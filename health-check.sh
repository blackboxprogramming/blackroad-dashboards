#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██╗  ██╗███████╗ █████╗ ██╗  ████████╗██╗  ██╗
#  ██║  ██║██╔════╝██╔══██╗██║  ╚══██╔══╝██║  ██║
#  ███████║█████╗  ███████║██║     ██║   ███████║
#  ██╔══██║██╔══╝  ██╔══██║██║     ██║   ██╔══██║
#  ██║  ██║███████╗██║  ██║███████╗██║   ██║  ██║
#  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝   ╚═╝  ╚═╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD HEALTH CHECK SYSTEM v2.0
#  Unified health monitoring with retry logic and alerting
#═══════════════════════════════════════════════════════════════════════════════

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"
[[ -f "$SCRIPT_DIR/notification-system.sh" ]] && source "$SCRIPT_DIR/notification-system.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

HEALTH_HOME="${BLACKROAD_DATA:-$HOME/.blackroad-dashboards}/health"
HEALTH_LOG="$HEALTH_HOME/health.log"
HEALTH_STATE="$HEALTH_HOME/state.json"
mkdir -p "$HEALTH_HOME" 2>/dev/null

# Retry configuration
MAX_RETRIES=3
RETRY_DELAY=2
TIMEOUT=10

# Check intervals (seconds)
CHECK_INTERVAL_FAST=30
CHECK_INTERVAL_NORMAL=60
CHECK_INTERVAL_SLOW=300

# State tracking
declare -A HEALTH_STATUS
declare -A LAST_CHECK_TIME
declare -A FAILURE_COUNT
declare -A LAST_ALERT_TIME

#───────────────────────────────────────────────────────────────────────────────
# RETRY LOGIC
#───────────────────────────────────────────────────────────────────────────────

# Execute with retry and exponential backoff
retry_exec() {
    local max_attempts="${1:-$MAX_RETRIES}"
    local base_delay="${2:-$RETRY_DELAY}"
    shift 2
    local cmd=("$@")

    local attempt=1
    local delay="$base_delay"

    while [[ $attempt -le $max_attempts ]]; do
        log_debug "Attempt $attempt/$max_attempts: ${cmd[*]}"

        local start_time=$(date +%s%N)
        local output
        local exit_code

        if output=$("${cmd[@]}" 2>&1); then
            local end_time=$(date +%s%N)
            local duration=$(( (end_time - start_time) / 1000000 ))

            echo "$output"
            return 0
        else
            exit_code=$?
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            log_warn "Attempt $attempt failed (exit=$exit_code), retrying in ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))  # Exponential backoff
        fi

        ((attempt++))
    done

    log_error "All $max_attempts attempts failed"
    return 1
}

#───────────────────────────────────────────────────────────────────────────────
# HEALTH CHECK TYPES
#───────────────────────────────────────────────────────────────────────────────

# Ping check with retry
check_ping() {
    local host="$1"
    local timeout="${2:-$TIMEOUT}"

    retry_exec $MAX_RETRIES $RETRY_DELAY \
        ping -c 1 -W "$timeout" "$host"
}

# HTTP check with retry
check_http() {
    local url="$1"
    local expected_code="${2:-200}"
    local timeout="${3:-$TIMEOUT}"

    local response
    response=$(retry_exec $MAX_RETRIES $RETRY_DELAY \
        curl -s -o /dev/null -w "%{http_code}|%{time_total}|%{size_download}" \
        --connect-timeout "$timeout" --max-time "$((timeout * 2))" "$url")

    if [[ $? -eq 0 ]]; then
        local code=$(echo "$response" | cut -d'|' -f1)
        local time=$(echo "$response" | cut -d'|' -f2)
        local size=$(echo "$response" | cut -d'|' -f3)

        if [[ "$code" == "$expected_code" ]]; then
            echo "OK|$code|$time|$size"
            return 0
        else
            echo "FAIL|$code|$time|$size"
            return 1
        fi
    fi

    echo "ERROR|0|0|0"
    return 1
}

# TCP port check
check_port() {
    local host="$1"
    local port="$2"
    local timeout="${3:-$TIMEOUT}"

    retry_exec $MAX_RETRIES $RETRY_DELAY \
        bash -c "timeout $timeout bash -c 'cat < /dev/null > /dev/tcp/$host/$port' 2>/dev/null"
}

# DNS check
check_dns() {
    local domain="$1"
    local expected_ip="${2:-}"

    local result
    result=$(retry_exec $MAX_RETRIES $RETRY_DELAY \
        dig +short "$domain" 2>/dev/null | head -1)

    if [[ -n "$result" ]]; then
        if [[ -z "$expected_ip" ]] || [[ "$result" == "$expected_ip" ]]; then
            echo "OK|$result"
            return 0
        fi
    fi

    echo "FAIL|$result"
    return 1
}

# SSL certificate check
check_ssl() {
    local domain="$1"
    local warn_days="${2:-30}"

    local expiry
    expiry=$(echo | openssl s_client -connect "${domain}:443" -servername "$domain" 2>/dev/null | \
        openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [[ -n "$expiry" ]]; then
        local expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || date -j -f "%b %d %H:%M:%S %Y %Z" "$expiry" +%s 2>/dev/null)
        local now=$(date +%s)
        local days_left=$(( (expiry_epoch - now) / 86400 ))

        if [[ $days_left -lt 0 ]]; then
            echo "EXPIRED|$days_left|$expiry"
            return 1
        elif [[ $days_left -lt $warn_days ]]; then
            echo "WARNING|$days_left|$expiry"
            return 0
        else
            echo "OK|$days_left|$expiry"
            return 0
        fi
    fi

    echo "ERROR|0|unknown"
    return 1
}

# Disk space check
check_disk() {
    local path="${1:-/}"
    local threshold="${2:-90}"

    local usage=$(df -h "$path" 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')

    if [[ -n "$usage" ]]; then
        if [[ $usage -ge $threshold ]]; then
            echo "CRITICAL|$usage"
            return 1
        elif [[ $usage -ge $((threshold - 10)) ]]; then
            echo "WARNING|$usage"
            return 0
        else
            echo "OK|$usage"
            return 0
        fi
    fi

    echo "ERROR|0"
    return 1
}

# Memory check
check_memory() {
    local threshold="${1:-90}"
    local usage=$(get_memory_usage 2>/dev/null || echo "0")

    if [[ $usage -ge $threshold ]]; then
        echo "CRITICAL|$usage"
        return 1
    elif [[ $usage -ge $((threshold - 10)) ]]; then
        echo "WARNING|$usage"
        return 0
    else
        echo "OK|$usage"
        return 0
    fi
}

# CPU check
check_cpu() {
    local threshold="${1:-90}"
    local usage=$(get_cpu_usage 2>/dev/null || echo "0")

    if [[ $usage -ge $threshold ]]; then
        echo "CRITICAL|$usage"
        return 1
    elif [[ $usage -ge $((threshold - 10)) ]]; then
        echo "WARNING|$usage"
        return 0
    else
        echo "OK|$usage"
        return 0
    fi
}

# Process check
check_process() {
    local process_name="$1"

    if pgrep -x "$process_name" > /dev/null 2>&1; then
        local pid=$(pgrep -x "$process_name" | head -1)
        echo "OK|$pid"
        return 0
    fi

    echo "FAIL|0"
    return 1
}

#───────────────────────────────────────────────────────────────────────────────
# HEALTH CHECK DEFINITIONS
#───────────────────────────────────────────────────────────────────────────────

# Define all health checks
declare -A HEALTH_CHECKS=(
    # Format: "name|type|target|threshold|interval"

    # Network devices
    ["lucidia_prime"]="ping|192.168.4.38||$CHECK_INTERVAL_FAST"
    ["blackroad_pi"]="ping|192.168.4.64||$CHECK_INTERVAL_FAST"
    ["lucidia_alt"]="ping|192.168.4.99||$CHECK_INTERVAL_FAST"
    ["codex_vps"]="ping|159.65.43.12||$CHECK_INTERVAL_FAST"

    # APIs
    ["github_api"]="http|https://api.github.com|200|$CHECK_INTERVAL_NORMAL"
    ["cloudflare_api"]="http|https://api.cloudflare.com/client/v4|200|$CHECK_INTERVAL_NORMAL"
    ["coingecko_api"]="http|https://api.coingecko.com/api/v3/ping|200|$CHECK_INTERVAL_NORMAL"

    # SSL Certificates
    ["github_ssl"]="ssl|github.com|30|$CHECK_INTERVAL_SLOW"
    ["cloudflare_ssl"]="ssl|cloudflare.com|30|$CHECK_INTERVAL_SLOW"

    # System resources
    ["local_cpu"]="cpu||80|$CHECK_INTERVAL_FAST"
    ["local_memory"]="memory||85|$CHECK_INTERVAL_FAST"
    ["local_disk"]="disk|/|90|$CHECK_INTERVAL_NORMAL"
)

#───────────────────────────────────────────────────────────────────────────────
# CHECK EXECUTION
#───────────────────────────────────────────────────────────────────────────────

# Run a single health check
run_check() {
    local name="$1"
    local config="${HEALTH_CHECKS[$name]}"

    [[ -z "$config" ]] && return 1

    IFS='|' read -r type target threshold interval <<< "$config"

    local result
    local status="unknown"
    local details=""

    case "$type" in
        ping)
            if result=$(check_ping "$target"); then
                status="healthy"
            else
                status="unhealthy"
            fi
            ;;
        http)
            result=$(check_http "$target" "${threshold:-200}")
            IFS='|' read -r stat code time size <<< "$result"
            if [[ "$stat" == "OK" ]]; then
                status="healthy"
                details="HTTP $code, ${time}s"
            else
                status="unhealthy"
                details="HTTP $code"
            fi
            ;;
        ssl)
            result=$(check_ssl "$target" "${threshold:-30}")
            IFS='|' read -r stat days expiry <<< "$result"
            case "$stat" in
                OK)       status="healthy"; details="$days days left" ;;
                WARNING)  status="degraded"; details="$days days left" ;;
                EXPIRED)  status="unhealthy"; details="Expired!" ;;
                *)        status="unknown"; details="Check failed" ;;
            esac
            ;;
        cpu)
            result=$(check_cpu "${threshold:-80}")
            IFS='|' read -r stat usage <<< "$result"
            case "$stat" in
                OK)       status="healthy"; details="${usage}%" ;;
                WARNING)  status="degraded"; details="${usage}%" ;;
                CRITICAL) status="unhealthy"; details="${usage}%" ;;
            esac
            ;;
        memory)
            result=$(check_memory "${threshold:-85}")
            IFS='|' read -r stat usage <<< "$result"
            case "$stat" in
                OK)       status="healthy"; details="${usage}%" ;;
                WARNING)  status="degraded"; details="${usage}%" ;;
                CRITICAL) status="unhealthy"; details="${usage}%" ;;
            esac
            ;;
        disk)
            result=$(check_disk "$target" "${threshold:-90}")
            IFS='|' read -r stat usage <<< "$result"
            case "$stat" in
                OK)       status="healthy"; details="${usage}%" ;;
                WARNING)  status="degraded"; details="${usage}%" ;;
                CRITICAL) status="unhealthy"; details="${usage}%" ;;
            esac
            ;;
    esac

    # Update state
    local prev_status="${HEALTH_STATUS[$name]:-unknown}"
    HEALTH_STATUS[$name]="$status"
    LAST_CHECK_TIME[$name]=$(date +%s)

    # Handle state transitions
    if [[ "$status" != "$prev_status" ]]; then
        handle_state_change "$name" "$prev_status" "$status" "$details"
    fi

    # Track failures
    if [[ "$status" == "unhealthy" ]]; then
        FAILURE_COUNT[$name]=$((${FAILURE_COUNT[$name]:-0} + 1))
    else
        FAILURE_COUNT[$name]=0
    fi

    echo "$name|$status|$details"
    log_debug "Health check: $name = $status ($details)"
}

# Handle state changes
handle_state_change() {
    local name="$1"
    local old_status="$2"
    local new_status="$3"
    local details="$4"

    local now=$(date +%s)
    local last_alert="${LAST_ALERT_TIME[$name]:-0}"

    # Rate limit alerts (min 5 minutes between alerts for same check)
    if [[ $((now - last_alert)) -lt 300 ]]; then
        return
    fi

    case "$new_status" in
        unhealthy)
            notify_error "Health Check Failed" "$name is DOWN: $details"
            LAST_ALERT_TIME[$name]=$now
            ;;
        degraded)
            notify_warning "Health Check Degraded" "$name is degraded: $details"
            LAST_ALERT_TIME[$name]=$now
            ;;
        healthy)
            if [[ "$old_status" == "unhealthy" ]]; then
                notify_success "Health Check Recovered" "$name is back UP: $details"
                LAST_ALERT_TIME[$name]=$now
            fi
            ;;
    esac

    # Log state change
    printf "[%s] %s: %s -> %s (%s)\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$name" "$old_status" "$new_status" "$details" \
        >> "$HEALTH_LOG"
}

# Run all health checks
run_all_checks() {
    local results=()

    for name in "${!HEALTH_CHECKS[@]}"; do
        results+=("$(run_check "$name")")
    done

    printf '%s\n' "${results[@]}"
}

#───────────────────────────────────────────────────────────────────────────────
# HEALTH DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

render_health_dashboard() {
    clear_screen
    cursor_hide

    printf "${BR_CYAN}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                    🏥 BLACKROAD HEALTH MONITOR                           ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    # Summary
    local healthy=0 degraded=0 unhealthy=0 unknown=0

    for name in "${!HEALTH_CHECKS[@]}"; do
        case "${HEALTH_STATUS[$name]:-unknown}" in
            healthy)   ((healthy++)) ;;
            degraded)  ((degraded++)) ;;
            unhealthy) ((unhealthy++)) ;;
            *)         ((unknown++)) ;;
        esac
    done

    local total=$((healthy + degraded + unhealthy + unknown))

    printf "  ${BR_GREEN}●${RST} Healthy: %-5d" "$healthy"
    printf "${BR_YELLOW}●${RST} Degraded: %-5d" "$degraded"
    printf "${BR_RED}●${RST} Unhealthy: %-5d" "$unhealthy"
    printf "${TEXT_MUTED}●${RST} Unknown: %-5d\n\n" "$unknown"

    # Health checks table
    printf "${TEXT_MUTED}┌────────────────────┬───────────┬────────────────────────────────┐${RST}\n"
    printf "${TEXT_MUTED}│${RST} ${BOLD}%-18s${RST} ${TEXT_MUTED}│${RST} ${BOLD}%-9s${RST} ${TEXT_MUTED}│${RST} ${BOLD}%-30s${RST} ${TEXT_MUTED}│${RST}\n" "Check" "Status" "Details"
    printf "${TEXT_MUTED}├────────────────────┼───────────┼────────────────────────────────┤${RST}\n"

    for name in $(echo "${!HEALTH_CHECKS[@]}" | tr ' ' '\n' | sort); do
        local status="${HEALTH_STATUS[$name]:-unknown}"
        local last_time="${LAST_CHECK_TIME[$name]:-0}"
        local failures="${FAILURE_COUNT[$name]:-0}"

        local status_color="$TEXT_MUTED"
        local status_icon="○"

        case "$status" in
            healthy)   status_color="$BR_GREEN"; status_icon="●" ;;
            degraded)  status_color="$BR_YELLOW"; status_icon="◐" ;;
            unhealthy) status_color="$BR_RED"; status_icon="●" ;;
        esac

        local ago=""
        if [[ $last_time -gt 0 ]]; then
            ago=$(time_ago "$(($(date +%s) - last_time))")
        fi

        local details="checked $ago"
        [[ $failures -gt 0 ]] && details+=" (${failures} failures)"

        printf "${TEXT_MUTED}│${RST} %-18s ${TEXT_MUTED}│${RST} ${status_color}${status_icon} %-7s${RST} ${TEXT_MUTED}│${RST} %-30s ${TEXT_MUTED}│${RST}\n" \
            "$name" "$status" "$details"
    done

    printf "${TEXT_MUTED}└────────────────────┴───────────┴────────────────────────────────┘${RST}\n"

    printf "\n${TEXT_SECONDARY}[r] Refresh  [a] Run all checks  [q] Quit${RST}\n"
}

# Interactive health dashboard
health_dashboard() {
    while true; do
        render_health_dashboard

        if read -rsn1 -t 5 key 2>/dev/null; then
            case "$key" in
                r|R) continue ;;
                a|A)
                    printf "\n${BR_CYAN}Running all health checks...${RST}\n"
                    run_all_checks
                    sleep 2
                    ;;
                q|Q) break ;;
            esac
        fi
    done

    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# CONTINUOUS MONITORING
#───────────────────────────────────────────────────────────────────────────────

# Background monitor daemon
monitor_daemon() {
    log_info "Starting health monitor daemon..."

    while true; do
        for name in "${!HEALTH_CHECKS[@]}"; do
            local config="${HEALTH_CHECKS[$name]}"
            IFS='|' read -r type target threshold interval <<< "$config"

            local last_time="${LAST_CHECK_TIME[$name]:-0}"
            local now=$(date +%s)

            if [[ $((now - last_time)) -ge ${interval:-60} ]]; then
                run_check "$name" >/dev/null 2>&1 &
            fi
        done

        sleep 5
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-dashboard}" in
        dashboard)     health_dashboard ;;
        check)         run_check "$2" ;;
        all)           run_all_checks ;;
        daemon)        monitor_daemon ;;
        ping)          check_ping "$2" ;;
        http)          check_http "$2" "$3" ;;
        ssl)           check_ssl "$2" "$3" ;;
        disk)          check_disk "$2" "$3" ;;
        memory)        check_memory "$2" ;;
        cpu)           check_cpu "$2" ;;
        *)
            printf "Usage: %s [dashboard|check|all|daemon|ping|http|ssl|disk|memory|cpu]\n" "$0"
            printf "       %s check github_api\n" "$0"
            printf "       %s http https://example.com 200\n" "$0"
            printf "       %s ssl example.com 30\n" "$0"
            ;;
    esac
fi
