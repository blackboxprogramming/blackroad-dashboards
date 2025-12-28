#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██████╗  ██╗      █████╗   ██████╗ ██╗  ██╗ ██████╗   ██████╗   █████╗  ██████╗
#  ██╔══██╗ ██║     ██╔══██╗ ██╔════╝ ██║ ██╔╝ ██╔══██╗ ██╔═══██╗ ██╔══██╗ ██╔══██╗
#  ██████╔╝ ██║     ███████║ ██║      █████╔╝  ██████╔╝ ██║   ██║ ███████║ ██║  ██║
#  ██╔══██╗ ██║     ██╔══██║ ██║      ██╔═██╗  ██╔══██╗ ██║   ██║ ██╔══██║ ██║  ██║
#  ██████╔╝ ███████╗██║  ██║ ╚██████╗ ██║  ██╗ ██║  ██║ ╚██████╔╝ ██║  ██║ ██████╔╝
#  ╚═════╝  ╚══════╝╚═╝  ╚═╝  ╚═════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝  ╚═════╝  ╚═╝  ╚═╝ ╚═════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD CORE LIBRARY v2.0
#  Shared functions, utilities, and components for all dashboards
#═══════════════════════════════════════════════════════════════════════════════

# Prevent multiple inclusions
[[ -n "$BLACKROAD_CORE_LOADED" ]] && return 0
export BLACKROAD_CORE_LOADED=1

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION & PATHS
#───────────────────────────────────────────────────────────────────────────────

export BLACKROAD_HOME="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}"
export BLACKROAD_CACHE="$BLACKROAD_HOME/cache"
export BLACKROAD_LOGS="$BLACKROAD_HOME/logs"
export BLACKROAD_DATA="$BLACKROAD_HOME/data"
export BLACKROAD_CONFIG="$BLACKROAD_HOME/config"
export BLACKROAD_TEMP="/tmp/blackroad-$$"

# Ensure directories exist
mkdir -p "$BLACKROAD_CACHE" "$BLACKROAD_LOGS" "$BLACKROAD_DATA" "$BLACKROAD_CONFIG" "$BLACKROAD_TEMP" 2>/dev/null

#───────────────────────────────────────────────────────────────────────────────
# CORE COLOR PALETTE - 24-bit RGB TrueColor
#───────────────────────────────────────────────────────────────────────────────

# Reset
export RST="\033[0m"
export BOLD="\033[1m"
export DIM="\033[2m"
export ITALIC="\033[3m"
export UNDERLINE="\033[4m"
export BLINK="\033[5m"
export REVERSE="\033[7m"

# BlackRoad Brand Colors
export BR_ORANGE="\033[38;2;247;147;26m"
export BR_PINK="\033[38;2;233;30;140m"
export BR_PURPLE="\033[38;2;153;69;255m"
export BR_CYAN="\033[38;2;0;212;255m"
export BR_GREEN="\033[38;2;20;241;149m"
export BR_BLUE="\033[38;2;66;133;244m"
export BR_RED="\033[38;2;255;82;82m"
export BR_YELLOW="\033[38;2;255;215;0m"
export BR_WHITE="\033[38;2;255;255;255m"
export BR_GRAY="\033[38;2;128;128;128m"

# Background variants
export BR_BG_ORANGE="\033[48;2;247;147;26m"
export BR_BG_PINK="\033[48;2;233;30;140m"
export BR_BG_PURPLE="\033[48;2;153;69;255m"
export BR_BG_CYAN="\033[48;2;0;212;255m"
export BR_BG_GREEN="\033[48;2;20;241;149m"
export BR_BG_DARK="\033[48;2;20;20;30m"

# Semantic Colors
export COLOR_SUCCESS="$BR_GREEN"
export COLOR_ERROR="$BR_RED"
export COLOR_WARNING="$BR_YELLOW"
export COLOR_INFO="$BR_CYAN"
export COLOR_MUTED="$BR_GRAY"

# Text Hierarchy
export TEXT_PRIMARY="$BR_WHITE"
export TEXT_SECONDARY="\033[38;2;180;180;180m"
export TEXT_MUTED="\033[38;2;100;100;100m"

#───────────────────────────────────────────────────────────────────────────────
# UNICODE SYMBOLS & BOX DRAWING
#───────────────────────────────────────────────────────────────────────────────

# Status Indicators
export SYM_ONLINE="◉"
export SYM_OFFLINE="○"
export SYM_CHECK="✓"
export SYM_CROSS="✗"
export SYM_WARNING="⚠"
export SYM_INFO="ℹ"
export SYM_ARROW="→"
export SYM_BULLET="•"
export SYM_STAR="★"
export SYM_LIGHTNING="⚡"
export SYM_FIRE="🔥"
export SYM_ROCKET="🚀"
export SYM_LOCK="🔒"
export SYM_UNLOCK="🔓"
export SYM_GEAR="⚙"
export SYM_CHART="📊"
export SYM_FOLDER="📁"
export SYM_FILE="📄"
export SYM_CLOCK="🕐"
export SYM_CALENDAR="📅"
export SYM_REFRESH="🔄"

# Sparkline Characters
export SPARK_CHARS="▁▂▃▄▅▆▇█"

# Box Drawing - Heavy
export BOX_TL="╔"
export BOX_TR="╗"
export BOX_BL="╚"
export BOX_BR="╝"
export BOX_H="═"
export BOX_V="║"
export BOX_LT="╠"
export BOX_RT="╣"
export BOX_TB="╦"
export BOX_BT="╩"
export BOX_X="╬"

# Box Drawing - Light
export BOX_TL_L="┌"
export BOX_TR_L="┐"
export BOX_BL_L="└"
export BOX_BR_L="┘"
export BOX_H_L="─"
export BOX_V_L="│"
export BOX_LT_L="├"
export BOX_RT_L="┤"
export BOX_TB_L="┬"
export BOX_BT_L="┴"
export BOX_X_L="┼"

# Progress Bar Characters
export PROG_FULL="█"
export PROG_HIGH="▓"
export PROG_MED="▒"
export PROG_LOW="░"
export PROG_EMPTY="░"

#───────────────────────────────────────────────────────────────────────────────
# TERMINAL UTILITIES
#───────────────────────────────────────────────────────────────────────────────

# Get terminal dimensions
get_term_size() {
    TERM_COLS=$(tput cols 2>/dev/null || echo 80)
    TERM_ROWS=$(tput lines 2>/dev/null || echo 24)
    export TERM_COLS TERM_ROWS
}

# Move cursor to position
cursor_to() {
    printf "\033[%d;%dH" "$1" "$2"
}

# Clear screen with optional mode
clear_screen() {
    local mode="${1:-full}"
    case "$mode" in
        full)   printf "\033[2J\033[H" ;;
        line)   printf "\033[2K\r" ;;
        below)  printf "\033[J" ;;
        above)  printf "\033[1J" ;;
    esac
}

# Hide/show cursor
cursor_hide() { printf "\033[?25l"; }
cursor_show() { printf "\033[?25h"; }

# Save/restore cursor position
cursor_save() { printf "\033[s"; }
cursor_restore() { printf "\033[u"; }

# Set terminal title
set_title() {
    printf "\033]0;%s\007" "$1"
}

#───────────────────────────────────────────────────────────────────────────────
# UI RENDERING COMPONENTS
#───────────────────────────────────────────────────────────────────────────────

# Draw horizontal line
draw_line() {
    local width="${1:-$TERM_COLS}"
    local char="${2:-─}"
    local color="${3:-$TEXT_MUTED}"
    printf "${color}"
    printf "%0.s${char}" $(seq 1 "$width")
    printf "${RST}\n"
}

# Draw box with title
draw_box() {
    local title="$1"
    local width="${2:-40}"
    local color="${3:-$BR_CYAN}"

    # Top border
    printf "${color}${BOX_TL}"
    printf "%0.s${BOX_H}" $(seq 1 $((width - 2)))
    printf "${BOX_TR}${RST}\n"

    # Title line
    if [[ -n "$title" ]]; then
        local title_len=${#title}
        local padding=$(( (width - 4 - title_len) / 2 ))
        printf "${color}${BOX_V}${RST}"
        printf "%${padding}s" ""
        printf "${BOLD}${color} %s ${RST}" "$title"
        printf "%$(( width - 4 - title_len - padding ))s" ""
        printf "${color}${BOX_V}${RST}\n"

        # Separator
        printf "${color}${BOX_LT}"
        printf "%0.s${BOX_H}" $(seq 1 $((width - 2)))
        printf "${BOX_RT}${RST}\n"
    fi
}

# Close box
close_box() {
    local width="${1:-40}"
    local color="${2:-$BR_CYAN}"
    printf "${color}${BOX_BL}"
    printf "%0.s${BOX_H}" $(seq 1 $((width - 2)))
    printf "${BOX_BR}${RST}\n"
}

# Draw card (modern style)
draw_card() {
    local title="$1"
    local content="$2"
    local width="${3:-50}"
    local accent="${4:-$BR_CYAN}"

    # Top with accent bar
    printf "${accent}▀${RST}"
    printf "%0.s▀" $(seq 1 $((width - 2)))
    printf "${accent}▀${RST}\n"

    # Content area
    printf "${TEXT_MUTED}│${RST} ${BOLD}${accent}%s${RST}" "$title"
    printf "%$(( width - ${#title} - 4 ))s" ""
    printf "${TEXT_MUTED}│${RST}\n"

    if [[ -n "$content" ]]; then
        printf "${TEXT_MUTED}│${RST} ${TEXT_SECONDARY}%s${RST}" "$content"
        printf "%$(( width - ${#content} - 4 ))s" ""
        printf "${TEXT_MUTED}│${RST}\n"
    fi

    # Bottom
    printf "${TEXT_MUTED}└"
    printf "%0.s─" $(seq 1 $((width - 2)))
    printf "┘${RST}\n"
}

# Progress bar
progress_bar() {
    local current="$1"
    local total="$2"
    local width="${3:-30}"
    local color="${4:-$BR_GREEN}"

    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "${color}"
    printf "%0.s${PROG_FULL}" $(seq 1 "$filled" 2>/dev/null) || true
    printf "${TEXT_MUTED}"
    printf "%0.s${PROG_EMPTY}" $(seq 1 "$empty" 2>/dev/null) || true
    printf "${RST} ${TEXT_SECONDARY}%3d%%${RST}" "$percentage"
}

# Sparkline from array of values
sparkline() {
    local -a values=("$@")
    local max=1
    local min=0

    # Find min/max
    for v in "${values[@]}"; do
        ((v > max)) && max=$v
        ((v < min)) && min=$v
    done

    local range=$((max - min))
    [[ $range -eq 0 ]] && range=1

    local spark=""
    for v in "${values[@]}"; do
        local idx=$(( (v - min) * 7 / range ))
        spark+="${SPARK_CHARS:$idx:1}"
    done

    printf "%s" "$spark"
}

# Status badge
badge() {
    local text="$1"
    local type="${2:-info}"

    case "$type" in
        success) printf "${BR_BG_GREEN}${BOLD} %s ${RST}" "$text" ;;
        error)   printf "${BR_BG_PINK}${BOLD} %s ${RST}" "$text" ;;
        warning) printf "\033[48;2;255;193;7m${BOLD}\033[38;2;0;0;0m %s ${RST}" "$text" ;;
        info)    printf "${BR_BG_CYAN}${BOLD}\033[38;2;0;0;0m %s ${RST}" "$text" ;;
        *)       printf "${BR_BG_PURPLE}${BOLD} %s ${RST}" "$text" ;;
    esac
}

# Status indicator with icon
status_indicator() {
    local status="$1"
    local label="$2"

    case "$status" in
        online|up|ok|success)
            printf "${COLOR_SUCCESS}${SYM_ONLINE} %s${RST}" "$label"
            ;;
        offline|down|error|fail)
            printf "${COLOR_ERROR}${SYM_OFFLINE} %s${RST}" "$label"
            ;;
        warning|warn|degraded)
            printf "${COLOR_WARNING}${SYM_WARNING} %s${RST}" "$label"
            ;;
        *)
            printf "${COLOR_INFO}${SYM_INFO} %s${RST}" "$label"
            ;;
    esac
}

#───────────────────────────────────────────────────────────────────────────────
# LOGGING SYSTEM
#───────────────────────────────────────────────────────────────────────────────

# Log levels
LOG_LEVEL="${LOG_LEVEL:-INFO}"
declare -A LOG_LEVELS=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3 [FATAL]=4)

# Get current timestamp
timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

# Log function
log() {
    local level="${1:-INFO}"
    shift
    local message="$*"

    local level_num="${LOG_LEVELS[$level]:-1}"
    local current_level_num="${LOG_LEVELS[$LOG_LEVEL]:-1}"

    [[ $level_num -lt $current_level_num ]] && return

    local color=""
    case "$level" in
        DEBUG) color="$TEXT_MUTED" ;;
        INFO)  color="$BR_CYAN" ;;
        WARN)  color="$BR_YELLOW" ;;
        ERROR) color="$BR_RED" ;;
        FATAL) color="$BR_RED$BOLD" ;;
    esac

    # Log to file
    local log_file="$BLACKROAD_LOGS/blackroad-$(date +%Y%m%d).log"
    printf "[%s] [%s] %s\n" "$(timestamp)" "$level" "$message" >> "$log_file"

    # Output to terminal if not silent
    [[ "${SILENT:-0}" != "1" ]] && printf "${color}[%s]${RST} %s\n" "$level" "$message"
}

log_debug() { log DEBUG "$@"; }
log_info()  { log INFO "$@"; }
log_warn()  { log WARN "$@"; }
log_error() { log ERROR "$@"; }
log_fatal() { log FATAL "$@"; exit 1; }

#───────────────────────────────────────────────────────────────────────────────
# ERROR HANDLING & RETRY LOGIC
#───────────────────────────────────────────────────────────────────────────────

# Retry with exponential backoff
retry_with_backoff() {
    local max_attempts="${1:-3}"
    local base_delay="${2:-1}"
    shift 2
    local cmd=("$@")

    local attempt=1
    local delay="$base_delay"

    while [[ $attempt -le $max_attempts ]]; do
        log_debug "Attempt $attempt/$max_attempts: ${cmd[*]}"

        if "${cmd[@]}"; then
            return 0
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            log_warn "Attempt $attempt failed, retrying in ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))
        fi

        ((attempt++))
    done

    log_error "All $max_attempts attempts failed for: ${cmd[*]}"
    return 1
}

# Safe command execution with timeout
safe_exec() {
    local timeout="${1:-10}"
    shift
    local cmd=("$@")

    if command -v timeout &>/dev/null; then
        timeout "$timeout" "${cmd[@]}"
    else
        "${cmd[@]}"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# NETWORK UTILITIES
#───────────────────────────────────────────────────────────────────────────────

# Check if host is reachable
check_host() {
    local host="$1"
    local timeout="${2:-2}"

    ping -c 1 -W "$timeout" "$host" &>/dev/null
}

# Check HTTP endpoint
check_http() {
    local url="$1"
    local timeout="${2:-5}"
    local expected_code="${3:-200}"

    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$timeout" "$url" 2>/dev/null)

    [[ "$code" == "$expected_code" ]]
}

# Get public IP
get_public_ip() {
    curl -s --connect-timeout 5 https://api.ipify.org 2>/dev/null || \
    curl -s --connect-timeout 5 https://ifconfig.me 2>/dev/null || \
    echo "unknown"
}

# DNS lookup
dns_lookup() {
    local domain="$1"
    local type="${2:-A}"

    if command -v dig &>/dev/null; then
        dig +short "$type" "$domain" 2>/dev/null | head -1
    elif command -v nslookup &>/dev/null; then
        nslookup -type="$type" "$domain" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# DATE/TIME UTILITIES
#───────────────────────────────────────────────────────────────────────────────

# Human-readable time difference
time_ago() {
    local seconds="$1"

    if [[ $seconds -lt 60 ]]; then
        echo "${seconds}s ago"
    elif [[ $seconds -lt 3600 ]]; then
        echo "$((seconds / 60))m ago"
    elif [[ $seconds -lt 86400 ]]; then
        echo "$((seconds / 3600))h ago"
    else
        echo "$((seconds / 86400))d ago"
    fi
}

# Parse ISO date to epoch
iso_to_epoch() {
    local iso_date="$1"
    date -d "$iso_date" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso_date" +%s 2>/dev/null
}

# Format bytes to human readable
format_bytes() {
    local bytes="$1"
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0

    while [[ $bytes -ge 1024 && $unit -lt 4 ]]; do
        bytes=$((bytes / 1024))
        ((unit++))
    done

    printf "%d%s" "$bytes" "${units[$unit]}"
}

# Format number with commas
format_number() {
    local num="$1"
    printf "%'d" "$num" 2>/dev/null || echo "$num"
}

#───────────────────────────────────────────────────────────────────────────────
# SYSTEM INFORMATION
#───────────────────────────────────────────────────────────────────────────────

# Get OS type
get_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}

# Get CPU usage
get_cpu_usage() {
    local os=$(get_os)
    case "$os" in
        macos)
            top -l 1 | grep "CPU usage" | awk '{print int($3)}' 2>/dev/null
            ;;
        linux)
            grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print int(usage)}' 2>/dev/null
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Get memory usage
get_memory_usage() {
    local os=$(get_os)
    case "$os" in
        macos)
            vm_stat | awk '/Pages active/ {active=$3} /Pages wired/ {wired=$4} /Pages free/ {free=$3} END {used=active+wired; total=used+free; print int(used*100/total)}' 2>/dev/null
            ;;
        linux)
            free | awk '/Mem:/ {print int($3*100/$2)}' 2>/dev/null
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Get disk usage
get_disk_usage() {
    local path="${1:-/}"
    df -h "$path" 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}'
}

# Get uptime in seconds
get_uptime_seconds() {
    local os=$(get_os)
    case "$os" in
        macos)
            sysctl -n kern.boottime 2>/dev/null | awk '{print int(systime() - $4)}' | tr -d ','
            ;;
        linux)
            cat /proc/uptime 2>/dev/null | awk '{print int($1)}'
            ;;
        *)
            echo "0"
            ;;
    esac
}

#───────────────────────────────────────────────────────────────────────────────
# ANIMATION HELPERS
#───────────────────────────────────────────────────────────────────────────────

# Spinner animation
spinner() {
    local pid="$1"
    local message="${2:-Loading}"
    local spin_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    cursor_hide
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${BR_CYAN}${spin_chars:$i:1}${RST} %s..." "$message"
        i=$(( (i + 1) % 10 ))
        sleep 0.1
    done
    printf "\r%${TERM_COLS}s\r"
    cursor_show
}

# Typing effect
type_text() {
    local text="$1"
    local delay="${2:-0.03}"

    for ((i=0; i<${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
}

# Fade in text
fade_in() {
    local text="$1"
    local steps=5

    for ((i=1; i<=steps; i++)); do
        local brightness=$((50 + i * 40))
        printf "\r\033[38;2;%d;%d;%dm%s${RST}" "$brightness" "$brightness" "$brightness" "$text"
        sleep 0.05
    done
    printf "\n"
}

# Pulse animation (single frame)
pulse_frame() {
    local text="$1"
    local frame="$2"
    local colors=(
        "255;100;100"
        "255;150;100"
        "255;200;100"
        "255;255;100"
        "255;200;100"
        "255;150;100"
    )
    local color="${colors[$((frame % ${#colors[@]}))]}"
    printf "\033[38;2;%sm%s${RST}" "$color" "$text"
}

#───────────────────────────────────────────────────────────────────────────────
# KEYBOARD INPUT
#───────────────────────────────────────────────────────────────────────────────

# Read single keypress (non-blocking)
read_key() {
    local timeout="${1:-0.1}"
    local key=""

    if read -rsn1 -t "$timeout" key 2>/dev/null; then
        # Handle escape sequences
        if [[ "$key" == $'\e' ]]; then
            read -rsn2 -t 0.01 key2 2>/dev/null
            key+="$key2"
        fi
        echo "$key"
        return 0
    fi
    return 1
}

# Map key to action
key_to_action() {
    local key="$1"
    case "$key" in
        q|Q)        echo "quit" ;;
        r|R)        echo "refresh" ;;
        h|H|\?)     echo "help" ;;
        s|S)        echo "ssh" ;;
        t|T)        echo "theme" ;;
        e|E)        echo "export" ;;
        $'\e[A')    echo "up" ;;
        $'\e[B')    echo "down" ;;
        $'\e[C')    echo "right" ;;
        $'\e[D')    echo "left" ;;
        $'\e')      echo "escape" ;;
        ' ')        echo "select" ;;
        $'\n')      echo "enter" ;;
        *)          echo "unknown" ;;
    esac
}

#───────────────────────────────────────────────────────────────────────────────
# MENU SYSTEM
#───────────────────────────────────────────────────────────────────────────────

# Draw menu
draw_menu() {
    local title="$1"
    shift
    local -a items=("$@")
    local selected="${MENU_SELECTED:-0}"
    local width=50

    draw_box "$title" "$width" "$BR_PURPLE"

    for i in "${!items[@]}"; do
        if [[ $i -eq $selected ]]; then
            printf "${BR_PURPLE}${BOX_V}${RST} ${BR_BG_PURPLE}${BOLD} → ${items[$i]}${RST}"
        else
            printf "${BR_PURPLE}${BOX_V}${RST}    ${TEXT_SECONDARY}${items[$i]}${RST}"
        fi
        local item_len=$((${#items[$i]} + 5))
        printf "%$(( width - item_len - 3 ))s"
        printf "${BR_PURPLE}${BOX_V}${RST}\n"
    done

    close_box "$width" "$BR_PURPLE"
}

#───────────────────────────────────────────────────────────────────────────────
# NOTIFICATION HELPERS (used by notification-system.sh)
#───────────────────────────────────────────────────────────────────────────────

# Play sound if available
play_notification_sound() {
    local sound_type="${1:-default}"

    if [[ "$(get_os)" == "macos" ]]; then
        case "$sound_type" in
            success) afplay /System/Library/Sounds/Glass.aiff 2>/dev/null & ;;
            error)   afplay /System/Library/Sounds/Basso.aiff 2>/dev/null & ;;
            warning) afplay /System/Library/Sounds/Sosumi.aiff 2>/dev/null & ;;
            *)       afplay /System/Library/Sounds/Pop.aiff 2>/dev/null & ;;
        esac
    elif command -v paplay &>/dev/null; then
        paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# CLEANUP HANDLER
#───────────────────────────────────────────────────────────────────────────────

cleanup() {
    cursor_show
    stty echo 2>/dev/null
    rm -rf "$BLACKROAD_TEMP" 2>/dev/null
    printf "${RST}\n"
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

#───────────────────────────────────────────────────────────────────────────────
# INITIALIZATION
#───────────────────────────────────────────────────────────────────────────────

# Initialize on source
get_term_size

# Export functions for subshells
export -f log log_debug log_info log_warn log_error
export -f check_host check_http get_public_ip
export -f progress_bar sparkline badge status_indicator
export -f cursor_to clear_screen cursor_hide cursor_show
export -f timestamp time_ago format_bytes format_number
export -f get_os get_cpu_usage get_memory_usage get_disk_usage

log_debug "BlackRoad Core Library v2.0 loaded"
