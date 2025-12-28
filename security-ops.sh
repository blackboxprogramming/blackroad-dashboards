#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗   ██╗
#  ██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝
#  ███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║    ╚████╔╝
#  ╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║     ╚██╔╝
#  ███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║      ██║
#  ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD SECURITY OPERATIONS CENTER v3.0
#  Threat Monitoring, Vulnerability Scanning, Security Alerts
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

SECURITY_HOME="${BLACKROAD_DATA:-$HOME/.blackroad-dashboards}/security"
SECURITY_LOGS="$SECURITY_HOME/logs"
SECURITY_ALERTS="$SECURITY_HOME/alerts"
THREAT_DB="$SECURITY_HOME/threats.db"
mkdir -p "$SECURITY_HOME" "$SECURITY_LOGS" "$SECURITY_ALERTS" 2>/dev/null

# Security levels
declare -A SEVERITY_LEVELS=(
    [critical]=5
    [high]=4
    [medium]=3
    [low]=2
    [info]=1
)

# Threat tracking
declare -a ACTIVE_THREATS=()
declare -A THREAT_COUNTS
declare -a SECURITY_EVENTS=()

# Scan results
declare -A PORT_SCAN_RESULTS
declare -A SSL_SCAN_RESULTS
declare -A VULN_SCAN_RESULTS

#───────────────────────────────────────────────────────────────────────────────
# THREAT DETECTION
#───────────────────────────────────────────────────────────────────────────────

# Log security event
log_security_event() {
    local severity="$1"
    local category="$2"
    local message="$3"
    local source="${4:-system}"

    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local event_id="evt_$(date +%s%N | tail -c 10)"

    local event=$(cat << EOF
{
    "id": "$event_id",
    "timestamp": "$timestamp",
    "severity": "$severity",
    "category": "$category",
    "message": "$message",
    "source": "$source"
}
EOF
)

    SECURITY_EVENTS+=("$event")
    echo "$event" >> "$SECURITY_LOGS/events_$(date +%Y%m%d).log"

    # Count by severity
    THREAT_COUNTS[$severity]=$((${THREAT_COUNTS[$severity]:-0} + 1))

    # Alert on critical/high
    if [[ "${SEVERITY_LEVELS[$severity]:-0}" -ge 4 ]]; then
        echo "$event" >> "$SECURITY_ALERTS/active.json"

        if [[ -f "$SCRIPT_DIR/notification-system.sh" ]]; then
            source "$SCRIPT_DIR/notification-system.sh"
            notify_security "Security Alert: $category" "$message"
        fi
    fi
}

# Check for suspicious processes
check_suspicious_processes() {
    local -a suspicious_patterns=(
        "nc -l"
        "ncat"
        "/tmp/.*sh"
        "base64.*decode"
        "curl.*\|.*sh"
        "wget.*\|.*sh"
    )

    local alerts=0

    for pattern in "${suspicious_patterns[@]}"; do
        if ps aux 2>/dev/null | grep -qE "$pattern"; then
            log_security_event "high" "process" "Suspicious process detected: $pattern"
            ((alerts++))
        fi
    done

    echo "$alerts"
}

# Check for unauthorized SSH sessions
check_ssh_sessions() {
    local authorized_users=("root" "admin" "$USER")
    local alerts=0

    while IFS= read -r session; do
        [[ -z "$session" ]] && continue

        local user=$(echo "$session" | awk '{print $1}')
        local from=$(echo "$session" | awk '{print $NF}')

        local authorized=false
        for auth_user in "${authorized_users[@]}"; do
            [[ "$user" == "$auth_user" ]] && authorized=true && break
        done

        if [[ "$authorized" != "true" ]]; then
            log_security_event "high" "ssh" "Unauthorized SSH session: $user from $from"
            ((alerts++))
        fi
    done < <(who 2>/dev/null)

    echo "$alerts"
}

# Check for failed login attempts
check_failed_logins() {
    local threshold=5
    local alerts=0

    if [[ -f /var/log/auth.log ]]; then
        local failed_count=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo "0")

        if [[ $failed_count -gt $threshold ]]; then
            log_security_event "medium" "auth" "Multiple failed login attempts: $failed_count"
            ((alerts++))
        fi
    fi

    echo "$alerts"
}

# Check for open ports
check_open_ports() {
    local known_ports=(22 80 443 8080)
    local alerts=0

    # Get listening ports
    local open_ports
    if command -v ss &>/dev/null; then
        open_ports=$(ss -tuln 2>/dev/null | awk 'NR>1 {print $5}' | grep -oE '[0-9]+$' | sort -u)
    elif command -v netstat &>/dev/null; then
        open_ports=$(netstat -tuln 2>/dev/null | awk 'NR>2 {print $4}' | grep -oE '[0-9]+$' | sort -u)
    fi

    for port in $open_ports; do
        local known=false
        for kp in "${known_ports[@]}"; do
            [[ "$port" == "$kp" ]] && known=true && break
        done

        if [[ "$known" != "true" && $port -lt 1024 ]]; then
            log_security_event "low" "network" "Unknown privileged port open: $port"
            ((alerts++))
        fi

        PORT_SCAN_RESULTS[$port]="open"
    done

    echo "$alerts"
}

# Check file permissions
check_file_permissions() {
    local alerts=0

    # Check for world-writable files in sensitive locations
    local sensitive_dirs=("/etc" "/usr/bin" "/usr/sbin")

    for dir in "${sensitive_dirs[@]}"; do
        [[ ! -d "$dir" ]] && continue

        local writable=$(find "$dir" -maxdepth 1 -perm -002 -type f 2>/dev/null | head -5)
        if [[ -n "$writable" ]]; then
            log_security_event "medium" "filesystem" "World-writable files in $dir"
            ((alerts++))
        fi
    done

    # Check SSH key permissions
    if [[ -d "$HOME/.ssh" ]]; then
        local bad_perms=$(find "$HOME/.ssh" -type f -perm /077 2>/dev/null)
        if [[ -n "$bad_perms" ]]; then
            log_security_event "high" "ssh" "Insecure SSH key permissions detected"
            ((alerts++))
        fi
    fi

    echo "$alerts"
}

#───────────────────────────────────────────────────────────────────────────────
# SSL/TLS SCANNING
#───────────────────────────────────────────────────────────────────────────────

# Check SSL certificate
check_ssl_certificate() {
    local domain="$1"
    local port="${2:-443}"
    local warn_days="${3:-30}"

    local result
    result=$(echo | timeout 10 openssl s_client -connect "${domain}:${port}" -servername "$domain" 2>/dev/null)

    if [[ -z "$result" ]]; then
        SSL_SCAN_RESULTS[$domain]="connection_failed"
        return 1
    fi

    # Get certificate details
    local cert_info=$(echo "$result" | openssl x509 -noout -dates -subject 2>/dev/null)
    local not_after=$(echo "$cert_info" | grep "notAfter" | cut -d= -f2)

    if [[ -n "$not_after" ]]; then
        local expiry_epoch=$(date -d "$not_after" +%s 2>/dev/null || date -j -f "%b %d %H:%M:%S %Y %Z" "$not_after" +%s 2>/dev/null)
        local now=$(date +%s)
        local days_left=$(( (expiry_epoch - now) / 86400 ))

        if [[ $days_left -lt 0 ]]; then
            SSL_SCAN_RESULTS[$domain]="expired"
            log_security_event "critical" "ssl" "SSL certificate expired for $domain"
            return 1
        elif [[ $days_left -lt $warn_days ]]; then
            SSL_SCAN_RESULTS[$domain]="expiring:$days_left"
            log_security_event "high" "ssl" "SSL certificate expiring in $days_left days for $domain"
            return 0
        else
            SSL_SCAN_RESULTS[$domain]="valid:$days_left"
            return 0
        fi
    fi

    SSL_SCAN_RESULTS[$domain]="unknown"
    return 1
}

# Check SSL protocol versions
check_ssl_protocols() {
    local domain="$1"

    local -a weak_protocols=("ssl2" "ssl3" "tls1" "tls1_1")
    local alerts=0

    for proto in "${weak_protocols[@]}"; do
        if echo | timeout 5 openssl s_client -connect "${domain}:443" -"$proto" 2>/dev/null | grep -q "Cipher"; then
            log_security_event "high" "ssl" "Weak protocol $proto enabled on $domain"
            ((alerts++))
        fi
    done

    echo "$alerts"
}

#───────────────────────────────────────────────────────────────────────────────
# VULNERABILITY ASSESSMENT
#───────────────────────────────────────────────────────────────────────────────

# Check for common vulnerabilities
run_vulnerability_scan() {
    local target="${1:-localhost}"
    local alerts=0

    printf "${BR_CYAN}Running vulnerability scan on %s...${RST}\n" "$target"

    # Check for default credentials (simulation)
    VULN_SCAN_RESULTS["default_creds"]="checking..."

    # Check for outdated software
    if command -v apt &>/dev/null; then
        local upgradable=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")
        if [[ $upgradable -gt 0 ]]; then
            VULN_SCAN_RESULTS["outdated_packages"]="$upgradable packages"
            log_security_event "medium" "vulnerability" "$upgradable packages need updating"
            ((alerts++))
        fi
    fi

    # Check for common misconfigurations
    # 1. SSH root login
    if grep -q "PermitRootLogin yes" /etc/ssh/sshd_config 2>/dev/null; then
        VULN_SCAN_RESULTS["ssh_root_login"]="enabled"
        log_security_event "high" "config" "SSH root login is enabled"
        ((alerts++))
    fi

    # 2. Password authentication
    if grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config 2>/dev/null; then
        VULN_SCAN_RESULTS["ssh_password_auth"]="enabled"
        log_security_event "medium" "config" "SSH password authentication is enabled"
        ((alerts++))
    fi

    # 3. Firewall status
    if command -v ufw &>/dev/null; then
        if ! ufw status 2>/dev/null | grep -q "active"; then
            VULN_SCAN_RESULTS["firewall"]="disabled"
            log_security_event "high" "firewall" "UFW firewall is not active"
            ((alerts++))
        fi
    fi

    echo "$alerts"
}

#───────────────────────────────────────────────────────────────────────────────
# SECURITY DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

render_security_dashboard() {
    clear_screen
    cursor_hide

    local frame=$(($(date +%s) % 2))
    local pulse=""
    [[ $frame -eq 0 ]] && pulse="${BR_RED}${BLINK}"

    printf "${BR_RED}${BOLD}"
    cat << 'BANNER'
╔══════════════════════════════════════════════════════════════════════════════╗
║   ███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗   ██╗             ║
║   ██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝             ║
║   ███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║    ╚████╔╝              ║
║   ╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║     ╚██╔╝               ║
║   ███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║      ██║                ║
║   ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝                ║
║                    O P E R A T I O N S   C E N T E R                         ║
╚══════════════════════════════════════════════════════════════════════════════╝
BANNER
    printf "${RST}\n"

    # Threat Level Indicator
    local critical=${THREAT_COUNTS[critical]:-0}
    local high=${THREAT_COUNTS[high]:-0}
    local medium=${THREAT_COUNTS[medium]:-0}
    local low=${THREAT_COUNTS[low]:-0}

    local threat_level="LOW"
    local threat_color="$BR_GREEN"

    if [[ $critical -gt 0 ]]; then
        threat_level="CRITICAL"
        threat_color="$BR_RED$BLINK"
    elif [[ $high -gt 0 ]]; then
        threat_level="HIGH"
        threat_color="$BR_RED"
    elif [[ $medium -gt 0 ]]; then
        threat_level="MEDIUM"
        threat_color="$BR_YELLOW"
    fi

    printf "  ${BOLD}THREAT LEVEL:${RST} ${threat_color}████ %s ████${RST}\n\n" "$threat_level"

    # Alert Summary
    printf "${BR_ORANGE}┌─ ALERT SUMMARY ───────────────────────────────────────────────────────────┐${RST}\n"
    printf "${BR_ORANGE}│${RST}  ${BR_RED}Critical: %-5d${RST}  ${BR_ORANGE}High: %-5d${RST}  ${BR_YELLOW}Medium: %-5d${RST}  ${BR_GREEN}Low: %-5d${RST}       ${BR_ORANGE}│${RST}\n" \
        "$critical" "$high" "$medium" "$low"
    printf "${BR_ORANGE}└───────────────────────────────────────────────────────────────────────────┘${RST}\n\n"

    # Run quick scans
    printf "${BR_CYAN}┌─ REAL-TIME MONITORING ───────────────────────────────────────────────────┐${RST}\n"

    # Process check
    printf "${BR_CYAN}│${RST}  Suspicious Processes: "
    local proc_alerts=$(check_suspicious_processes)
    if [[ $proc_alerts -gt 0 ]]; then
        printf "${BR_RED}%d detected${RST}\n" "$proc_alerts"
    else
        printf "${BR_GREEN}None${RST}\n"
    fi

    # SSH sessions
    printf "${BR_CYAN}│${RST}  SSH Sessions: "
    local ssh_alerts=$(check_ssh_sessions)
    local active_sessions=$(who 2>/dev/null | wc -l)
    if [[ $ssh_alerts -gt 0 ]]; then
        printf "${BR_RED}%d unauthorized${RST} " "$ssh_alerts"
    fi
    printf "${TEXT_SECONDARY}(%d active)${RST}\n" "$active_sessions"

    # Open ports
    printf "${BR_CYAN}│${RST}  Open Ports: "
    local port_alerts=$(check_open_ports)
    printf "${TEXT_SECONDARY}%d ports${RST}" "${#PORT_SCAN_RESULTS[@]}"
    [[ $port_alerts -gt 0 ]] && printf " ${BR_YELLOW}(%d unusual)${RST}" "$port_alerts"
    printf "\n"

    # File permissions
    printf "${BR_CYAN}│${RST}  File Permissions: "
    local perm_alerts=$(check_file_permissions)
    if [[ $perm_alerts -gt 0 ]]; then
        printf "${BR_YELLOW}%d issues${RST}\n" "$perm_alerts"
    else
        printf "${BR_GREEN}OK${RST}\n"
    fi

    printf "${BR_CYAN}└───────────────────────────────────────────────────────────────────────────┘${RST}\n\n"

    # Recent Events
    printf "${BR_PURPLE}┌─ RECENT SECURITY EVENTS ─────────────────────────────────────────────────┐${RST}\n"

    local event_count=0
    for event in "${SECURITY_EVENTS[@]: -5}"; do
        [[ -z "$event" ]] && continue
        ((event_count++))

        local severity=$(echo "$event" | jq -r '.severity' 2>/dev/null)
        local category=$(echo "$event" | jq -r '.category' 2>/dev/null)
        local message=$(echo "$event" | jq -r '.message' 2>/dev/null | head -c 50)
        local timestamp=$(echo "$event" | jq -r '.timestamp' 2>/dev/null | cut -dT -f2 | cut -d. -f1)

        local sev_color="$TEXT_MUTED"
        case "$severity" in
            critical) sev_color="$BR_RED$BOLD" ;;
            high)     sev_color="$BR_RED" ;;
            medium)   sev_color="$BR_YELLOW" ;;
            low)      sev_color="$BR_GREEN" ;;
        esac

        printf "${BR_PURPLE}│${RST}  ${TEXT_MUTED}%s${RST} ${sev_color}%-8s${RST} ${BR_CYAN}%-10s${RST} %s\n" \
            "$timestamp" "[$severity]" "[$category]" "$message"
    done

    [[ $event_count -eq 0 ]] && printf "${BR_PURPLE}│${RST}  ${TEXT_MUTED}No recent events${RST}\n"

    printf "${BR_PURPLE}└───────────────────────────────────────────────────────────────────────────┘${RST}\n\n"

    # SSL Status
    printf "${BR_GREEN}┌─ SSL/TLS STATUS ──────────────────────────────────────────────────────────┐${RST}\n"

    for domain in "${!SSL_SCAN_RESULTS[@]}"; do
        local status="${SSL_SCAN_RESULTS[$domain]}"
        local status_color="$BR_GREEN"
        local status_icon="✓"

        case "$status" in
            expired)     status_color="$BR_RED"; status_icon="✗" ;;
            expiring:*)  status_color="$BR_YELLOW"; status_icon="⚠" ;;
            valid:*)     status_color="$BR_GREEN"; status_icon="✓" ;;
            *)           status_color="$TEXT_MUTED"; status_icon="?" ;;
        esac

        printf "${BR_GREEN}│${RST}  ${status_color}%s${RST} %-25s %s\n" "$status_icon" "$domain" "$status"
    done

    [[ ${#SSL_SCAN_RESULTS[@]} -eq 0 ]] && printf "${BR_GREEN}│${RST}  ${TEXT_MUTED}No SSL scans performed${RST}\n"

    printf "${BR_GREEN}└───────────────────────────────────────────────────────────────────────────┘${RST}\n\n"

    printf "${TEXT_MUTED}Last scan: $(date '+%H:%M:%S') │ [s]can [v]ulns [c]lear [q]uit${RST}\n"
}

# Main security dashboard loop
security_dashboard_loop() {
    # Initial scans
    check_open_ports > /dev/null
    check_ssl_certificate "github.com" > /dev/null
    check_ssl_certificate "cloudflare.com" > /dev/null

    while true; do
        render_security_dashboard

        if read -rsn1 -t 3 key 2>/dev/null; then
            case "$key" in
                s|S)
                    printf "\n${BR_CYAN}Running security scan...${RST}\n"
                    check_suspicious_processes > /dev/null
                    check_ssh_sessions > /dev/null
                    check_open_ports > /dev/null
                    check_file_permissions > /dev/null
                    sleep 2
                    ;;
                v|V)
                    printf "\n${BR_CYAN}Running vulnerability assessment...${RST}\n"
                    run_vulnerability_scan
                    sleep 3
                    ;;
                c|C)
                    SECURITY_EVENTS=()
                    THREAT_COUNTS=()
                    ;;
                q|Q)
                    break
                    ;;
            esac
        fi
    done

    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-dashboard}" in
        dashboard)  security_dashboard_loop ;;
        scan)       run_vulnerability_scan "$2" ;;
        ssl)        check_ssl_certificate "$2" "$3" ;;
        ports)      check_open_ports ;;
        procs)      check_suspicious_processes ;;
        *)
            printf "Usage: %s [dashboard|scan|ssl|ports|procs]\n" "$0"
            ;;
    esac
fi
