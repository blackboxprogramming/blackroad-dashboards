#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██╗      ██████╗  ██████╗ ███████╗
#  ██║     ██╔═══██╗██╔════╝ ██╔════╝
#  ██║     ██║   ██║██║  ███╗███████╗
#  ██║     ██║   ██║██║   ██║╚════██║
#  ███████╗╚██████╔╝╚██████╔╝███████║
#  ╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD LOG STREAMING DASHBOARD v2.0
#  Real-time log aggregation, filtering, and visualization
#═══════════════════════════════════════════════════════════════════════════════

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

LOG_BUFFER_SIZE=1000
LOG_DISPLAY_LINES=20
LOG_UPDATE_INTERVAL=1

# Log sources
declare -A LOG_SOURCES=(
    ["blackroad"]="$HOME/.blackroad-dashboards/logs/blackroad-*.log"
    ["system"]="/var/log/syslog:/var/log/system.log"
    ["nginx"]="/var/log/nginx/access.log:/var/log/nginx/error.log"
    ["docker"]="docker logs"
    ["journal"]="journalctl -f"
)

# Log level colors
declare -A LOG_LEVEL_COLORS=(
    ["DEBUG"]="$TEXT_MUTED"
    ["INFO"]="$BR_CYAN"
    ["WARN"]="$BR_YELLOW"
    ["WARNING"]="$BR_YELLOW"
    ["ERROR"]="$BR_RED"
    ["FATAL"]="$BR_RED$BOLD"
    ["CRITICAL"]="$BR_RED$BOLD$BLINK"
)

# Log buffer
declare -a LOG_BUFFER=()
LOG_PAUSED=0
LOG_FILTER=""
LOG_LEVEL_FILTER=""
LOG_SOURCE_FILTER=""

#───────────────────────────────────────────────────────────────────────────────
# LOG PARSING
#───────────────────────────────────────────────────────────────────────────────

# Parse log line and extract components
parse_log_line() {
    local line="$1"

    local timestamp=""
    local level="INFO"
    local source=""
    local message=""

    # Try to extract timestamp [YYYY-MM-DD HH:MM:SS]
    if [[ "$line" =~ \[([0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2})\] ]]; then
        timestamp="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
        timestamp="${BASH_REMATCH[1]}"
    fi

    # Extract log level
    if [[ "$line" =~ \[(DEBUG|INFO|WARN|WARNING|ERROR|FATAL|CRITICAL)\] ]]; then
        level="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ (debug|info|warn|warning|error|fatal|critical) ]]; then
        level=$(echo "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')
    fi

    # Extract source if present
    if [[ "$line" =~ \[([a-zA-Z0-9_-]+)\]: ]]; then
        source="${BASH_REMATCH[1]}"
    fi

    # Rest is message
    message="$line"

    echo "$timestamp|$level|$source|$message"
}

# Colorize log line based on level
colorize_log() {
    local line="$1"
    local level="INFO"

    # Detect level
    for lvl in "${!LOG_LEVEL_COLORS[@]}"; do
        if [[ "$line" =~ \[$lvl\] ]] || [[ "$line" =~ $lvl ]]; then
            level="$lvl"
            break
        fi
    done

    local color="${LOG_LEVEL_COLORS[$level]:-$TEXT_SECONDARY}"

    # Highlight specific patterns
    local highlighted="$line"

    # Highlight timestamps
    highlighted=$(echo "$highlighted" | sed -E "s/(\[[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}\])/${TEXT_MUTED}\1${color}/g")

    # Highlight log levels
    highlighted=$(echo "$highlighted" | sed -E "s/\[(DEBUG|INFO|WARN|WARNING|ERROR|FATAL|CRITICAL)\]/${BOLD}[\1]${RST}${color}/g")

    # Highlight IPs
    highlighted=$(echo "$highlighted" | sed -E "s/([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/${BR_PURPLE}\1${color}/g")

    # Highlight URLs
    highlighted=$(echo "$highlighted" | sed -E "s/(https?:\/\/[^[:space:]]+)/${BR_CYAN}\1${color}/g")

    printf "${color}%s${RST}\n" "$highlighted"
}

#───────────────────────────────────────────────────────────────────────────────
# LOG BUFFER MANAGEMENT
#───────────────────────────────────────────────────────────────────────────────

# Add line to buffer
add_to_buffer() {
    local line="$1"
    local source="${2:-unknown}"

    # Skip empty lines
    [[ -z "$line" ]] && return

    # Add to buffer with source tag
    LOG_BUFFER+=("[$(date '+%H:%M:%S')] [$source] $line")

    # Trim buffer if too large
    if [[ ${#LOG_BUFFER[@]} -gt $LOG_BUFFER_SIZE ]]; then
        LOG_BUFFER=("${LOG_BUFFER[@]:$((${#LOG_BUFFER[@]} - LOG_BUFFER_SIZE))}")
    fi
}

# Filter buffer
filter_buffer() {
    local -a filtered=()

    for line in "${LOG_BUFFER[@]}"; do
        local include=true

        # Text filter
        if [[ -n "$LOG_FILTER" ]]; then
            if ! [[ "$line" =~ $LOG_FILTER ]]; then
                include=false
            fi
        fi

        # Level filter
        if [[ -n "$LOG_LEVEL_FILTER" ]]; then
            if ! [[ "$line" =~ \[$LOG_LEVEL_FILTER\] ]]; then
                include=false
            fi
        fi

        # Source filter
        if [[ -n "$LOG_SOURCE_FILTER" ]]; then
            if ! [[ "$line" =~ \[$LOG_SOURCE_FILTER\] ]]; then
                include=false
            fi
        fi

        [[ "$include" == "true" ]] && filtered+=("$line")
    done

    printf '%s\n' "${filtered[@]}"
}

# Clear buffer
clear_buffer() {
    LOG_BUFFER=()
}

#───────────────────────────────────────────────────────────────────────────────
# LOG SOURCES
#───────────────────────────────────────────────────────────────────────────────

# Start tailing a file
tail_file() {
    local file="$1"
    local source_name="${2:-$(basename "$file")}"

    if [[ -f "$file" ]]; then
        tail -F "$file" 2>/dev/null | while IFS= read -r line; do
            [[ "$LOG_PAUSED" == "0" ]] && add_to_buffer "$line" "$source_name"
        done &
        echo $!
    fi
}

# Start tailing a command
tail_command() {
    local cmd="$1"
    local source_name="${2:-cmd}"

    eval "$cmd" 2>/dev/null | while IFS= read -r line; do
        [[ "$LOG_PAUSED" == "0" ]] && add_to_buffer "$line" "$source_name"
    done &
    echo $!
}

# Start all configured sources
start_all_sources() {
    local -a pids=()

    for source_name in "${!LOG_SOURCES[@]}"; do
        local config="${LOG_SOURCES[$source_name]}"

        if [[ "$config" =~ ^docker|^journalctl ]]; then
            # Command-based source
            local pid=$(tail_command "$config" "$source_name")
            [[ -n "$pid" ]] && pids+=("$pid")
        else
            # File-based source(s)
            IFS=':' read -ra files <<< "$config"
            for file_pattern in "${files[@]}"; do
                for file in $file_pattern; do
                    [[ -f "$file" ]] && {
                        local pid=$(tail_file "$file" "$source_name")
                        [[ -n "$pid" ]] && pids+=("$pid")
                    }
                done
            done
        fi
    done

    echo "${pids[*]}"
}

# Stop all sources
stop_all_sources() {
    local pids="$1"

    for pid in $pids; do
        kill "$pid" 2>/dev/null
    done
}

#───────────────────────────────────────────────────────────────────────────────
# LOG DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

render_log_header() {
    printf "${BR_CYAN}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                       📜 BLACKROAD LOG STREAM                                ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "${RST}"

    # Status bar
    local pause_status="${BR_GREEN}LIVE${RST}"
    [[ "$LOG_PAUSED" == "1" ]] && pause_status="${BR_YELLOW}PAUSED${RST}"

    printf " Status: $pause_status"
    printf "  │  Lines: ${TEXT_SECONDARY}${#LOG_BUFFER[@]}${RST}"
    [[ -n "$LOG_FILTER" ]] && printf "  │  Filter: ${BR_PURPLE}$LOG_FILTER${RST}"
    [[ -n "$LOG_LEVEL_FILTER" ]] && printf "  │  Level: ${BR_ORANGE}$LOG_LEVEL_FILTER${RST}"
    printf "\n"
    printf "${TEXT_MUTED}─────────────────────────────────────────────────────────────────────────────${RST}\n"
}

render_log_lines() {
    local lines_to_show="$LOG_DISPLAY_LINES"
    local filtered_lines
    mapfile -t filtered_lines < <(filter_buffer | tail -n "$lines_to_show")

    for line in "${filtered_lines[@]}"; do
        colorize_log "$line"
    done

    # Pad remaining lines
    local shown=${#filtered_lines[@]}
    for ((i=shown; i<lines_to_show; i++)); do
        printf "\n"
    done
}

render_log_footer() {
    printf "${TEXT_MUTED}─────────────────────────────────────────────────────────────────────────────${RST}\n"
    printf " ${TEXT_SECONDARY}[p]ause  [c]lear  [f]ilter  [l]evel  [/]search  [q]uit${RST}\n"
}

render_log_dashboard() {
    cursor_to 1 1
    render_log_header
    render_log_lines
    render_log_footer
}

#───────────────────────────────────────────────────────────────────────────────
# INTERACTIVE MODE
#───────────────────────────────────────────────────────────────────────────────

prompt_filter() {
    cursor_to $((TERM_ROWS - 2)) 1
    printf "%${TERM_COLS}s\r" ""  # Clear line
    printf "${BR_CYAN}Filter: ${RST}"

    cursor_show
    stty echo
    read -r LOG_FILTER
    stty -echo
    cursor_hide
}

prompt_level_filter() {
    cursor_to $((TERM_ROWS - 2)) 1
    printf "%${TERM_COLS}s\r" ""
    printf "${BR_CYAN}Level (DEBUG/INFO/WARN/ERROR/FATAL): ${RST}"

    cursor_show
    stty echo
    read -r LOG_LEVEL_FILTER
    LOG_LEVEL_FILTER=$(echo "$LOG_LEVEL_FILTER" | tr '[:lower:]' '[:upper:]')
    stty -echo
    cursor_hide
}

log_dashboard_loop() {
    clear_screen
    cursor_hide
    stty -echo 2>/dev/null
    get_term_size

    # Adjust display lines based on terminal size
    LOG_DISPLAY_LINES=$((TERM_ROWS - 8))

    # Start log sources
    local pids=$(start_all_sources)

    # Add some initial demo logs
    add_to_buffer "[INFO] Log streaming dashboard started" "system"
    add_to_buffer "[INFO] Monitoring ${#LOG_SOURCES[@]} log sources" "system"

    local last_render=0

    while true; do
        local now=$(date +%s)

        # Render at interval
        if [[ $((now - last_render)) -ge $LOG_UPDATE_INTERVAL ]]; then
            render_log_dashboard
            last_render=$now
        fi

        # Handle input
        if read -rsn1 -t 0.5 key 2>/dev/null; then
            case "$key" in
                q|Q)
                    stop_all_sources "$pids"
                    break
                    ;;
                p|P)
                    LOG_PAUSED=$((1 - LOG_PAUSED))
                    ;;
                c|C)
                    clear_buffer
                    add_to_buffer "[INFO] Log buffer cleared" "system"
                    ;;
                f|/)
                    prompt_filter
                    ;;
                l|L)
                    prompt_level_filter
                    ;;
                x|X)
                    LOG_FILTER=""
                    LOG_LEVEL_FILTER=""
                    LOG_SOURCE_FILTER=""
                    ;;
                +)
                    LOG_DISPLAY_LINES=$((LOG_DISPLAY_LINES + 5))
                    ;;
                -)
                    [[ $LOG_DISPLAY_LINES -gt 5 ]] && LOG_DISPLAY_LINES=$((LOG_DISPLAY_LINES - 5))
                    ;;
            esac
        fi
    done

    cursor_show
    stty echo 2>/dev/null
    clear_screen
}

#───────────────────────────────────────────────────────────────────────────────
# LOG ANALYSIS
#───────────────────────────────────────────────────────────────────────────────

# Analyze log patterns
analyze_logs() {
    local -A level_counts=()
    local -A source_counts=()
    local total=0

    for line in "${LOG_BUFFER[@]}"; do
        ((total++))

        # Count levels
        for level in "${!LOG_LEVEL_COLORS[@]}"; do
            if [[ "$line" =~ \[$level\] ]]; then
                level_counts[$level]=$((${level_counts[$level]:-0} + 1))
                break
            fi
        done

        # Count sources
        if [[ "$line" =~ \[([a-zA-Z0-9_-]+)\] ]]; then
            local source="${BASH_REMATCH[1]}"
            source_counts[$source]=$((${source_counts[$source]:-0} + 1))
        fi
    done

    printf "${BOLD}Log Analysis (${total} entries):${RST}\n\n"

    printf "${BR_CYAN}By Level:${RST}\n"
    for level in DEBUG INFO WARN WARNING ERROR FATAL CRITICAL; do
        local count="${level_counts[$level]:-0}"
        [[ $count -gt 0 ]] && printf "  %-10s %d\n" "$level" "$count"
    done

    printf "\n${BR_PURPLE}By Source:${RST}\n"
    for source in "${!source_counts[@]}"; do
        printf "  %-15s %d\n" "$source" "${source_counts[$source]}"
    done
}

# Search logs
search_logs() {
    local pattern="$1"
    local context="${2:-0}"

    local -a matches=()
    local idx=0

    for line in "${LOG_BUFFER[@]}"; do
        if [[ "$line" =~ $pattern ]]; then
            # Add context before
            for ((i=idx-context; i<idx; i++)); do
                [[ $i -ge 0 ]] && matches+=("  ${LOG_BUFFER[$i]}")
            done

            # Add match
            matches+=("→ $line")

            # Add context after
            for ((i=idx+1; i<=idx+context && i<${#LOG_BUFFER[@]}; i++)); do
                matches+=("  ${LOG_BUFFER[$i]}")
            done

            matches+=("---")
        fi
        ((idx++))
    done

    printf '%s\n' "${matches[@]}"
}

# Export logs
export_logs() {
    local format="${1:-txt}"
    local output_file="${2:-$HOME/.blackroad-dashboards/logs/export_$(date +%Y%m%d_%H%M%S).$format}"

    case "$format" in
        txt)
            printf '%s\n' "${LOG_BUFFER[@]}" > "$output_file"
            ;;
        json)
            printf '[\n'
            local first=true
            for line in "${LOG_BUFFER[@]}"; do
                [[ "$first" != "true" ]] && printf ',\n'
                first=false
                printf '  "%s"' "$(echo "$line" | sed 's/"/\\"/g')"
            done
            printf '\n]\n'
            ;;
    esac > "$output_file"

    printf "Exported to: %s\n" "$output_file"
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-stream}" in
        stream)    log_dashboard_loop ;;
        analyze)   analyze_logs ;;
        search)    search_logs "$2" "${3:-0}" ;;
        export)    export_logs "${2:-txt}" "$3" ;;
        tail)
            # Simple tail mode
            tail_file "$2" "${3:-file}" &
            wait
            ;;
        *)
            printf "Usage: %s [stream|analyze|search|export|tail]\n" "$0"
            printf "       %s stream           # Interactive log dashboard\n" "$0"
            printf "       %s search 'error'   # Search logs\n" "$0"
            printf "       %s export json      # Export logs\n" "$0"
            printf "       %s tail /var/log/syslog  # Tail specific file\n" "$0"
            ;;
    esac
fi
