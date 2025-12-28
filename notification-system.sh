#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ███╗   ██╗ ██████╗ ████████╗██╗███████╗██╗ ██████╗ █████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
#  ████╗  ██║██╔═══██╗╚══██╔══╝██║██╔════╝██║██╔════╝██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#  ██╔██╗ ██║██║   ██║   ██║   ██║█████╗  ██║██║     ███████║   ██║   ██║██║   ██║██╔██╗ ██║███████╗
#  ██║╚██╗██║██║   ██║   ██║   ██║██╔══╝  ██║██║     ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║╚════██║
#  ██║ ╚████║╚██████╔╝   ██║   ██║██║     ██║╚██████╗██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║███████║
#  ╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝╚═╝     ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD NOTIFICATION SYSTEM v2.0
#  Multi-channel alerting: Terminal, Desktop, Sound, Webhooks
#═══════════════════════════════════════════════════════════════════════════════

# Source core library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

NOTIFICATION_HOME="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}/notifications"
NOTIFICATION_LOG="$NOTIFICATION_HOME/history.log"
NOTIFICATION_CONFIG="$NOTIFICATION_HOME/config.json"

# Notification channels (can be combined)
NOTIFY_TERMINAL="${NOTIFY_TERMINAL:-1}"
NOTIFY_DESKTOP="${NOTIFY_DESKTOP:-1}"
NOTIFY_SOUND="${NOTIFY_SOUND:-1}"
NOTIFY_WEBHOOK="${NOTIFY_WEBHOOK:-0}"
NOTIFY_LOG="${NOTIFY_LOG:-1}"

# Webhook URLs (optional)
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

# Rate limiting
NOTIFICATION_COOLDOWN=5  # Minimum seconds between notifications of same type
declare -A LAST_NOTIFICATION_TIME

# Ensure directories exist
mkdir -p "$NOTIFICATION_HOME" 2>/dev/null

#───────────────────────────────────────────────────────────────────────────────
# NOTIFICATION TYPES
#───────────────────────────────────────────────────────────────────────────────

declare -A NOTIFICATION_TYPES=(
    [info]="ℹ️ |INFO|$BR_CYAN|Pop"
    [success]="✅|SUCCESS|$BR_GREEN|Glass"
    [warning]="⚠️ |WARNING|$BR_YELLOW|Sosumi"
    [error]="❌|ERROR|$BR_RED|Basso"
    [critical]="🚨|CRITICAL|$BR_RED$BLINK|Funk"
    [alert]="🔔|ALERT|$BR_ORANGE|Ping"
    [update]="🔄|UPDATE|$BR_PURPLE|Purr"
    [security]="🔒|SECURITY|$BR_PINK|Hero"
    [deploy]="🚀|DEPLOY|$BR_GREEN|Submarine"
    [payment]="💰|PAYMENT|$BR_YELLOW|Blow"
)

#───────────────────────────────────────────────────────────────────────────────
# CORE NOTIFICATION FUNCTIONS
#───────────────────────────────────────────────────────────────────────────────

# Main notification function
notify() {
    local type="${1:-info}"
    local title="$2"
    local message="$3"
    local channels="${4:-all}"  # all, terminal, desktop, sound, webhook

    # Get notification config
    local config="${NOTIFICATION_TYPES[$type]:-${NOTIFICATION_TYPES[info]}}"
    IFS='|' read -r icon label color sound <<< "$config"

    # Rate limiting
    local now=$(date +%s)
    local key="${type}_${title}"
    local last_time="${LAST_NOTIFICATION_TIME[$key]:-0}"

    if [[ $((now - last_time)) -lt $NOTIFICATION_COOLDOWN ]]; then
        return 0  # Skip, too soon
    fi
    LAST_NOTIFICATION_TIME[$key]=$now

    # Dispatch to channels
    case "$channels" in
        all)
            [[ "$NOTIFY_TERMINAL" == "1" ]] && notify_terminal "$icon" "$label" "$title" "$message" "$color"
            [[ "$NOTIFY_DESKTOP" == "1" ]] && notify_desktop "$icon" "$title" "$message" "$type"
            [[ "$NOTIFY_SOUND" == "1" ]] && notify_sound "$sound"
            [[ "$NOTIFY_WEBHOOK" == "1" ]] && notify_webhooks "$type" "$title" "$message"
            ;;
        terminal) notify_terminal "$icon" "$label" "$title" "$message" "$color" ;;
        desktop)  notify_desktop "$icon" "$title" "$message" "$type" ;;
        sound)    notify_sound "$sound" ;;
        webhook)  notify_webhooks "$type" "$title" "$message" ;;
    esac

    # Log notification
    [[ "$NOTIFY_LOG" == "1" ]] && log_notification "$type" "$title" "$message"
}

# Terminal notification (inline or popup style)
notify_terminal() {
    local icon="$1"
    local label="$2"
    local title="$3"
    local message="$4"
    local color="$5"

    local timestamp=$(date "+%H:%M:%S")

    # Save cursor, print notification, restore cursor
    printf "\n"
    printf "${color}╭─────────────────────────────────────────────────────────────────╮${RST}\n"
    printf "${color}│${RST} ${icon} ${BOLD}${color}${label}${RST} ${TEXT_MUTED}[${timestamp}]${RST}\n"
    printf "${color}│${RST} ${BOLD}${title}${RST}\n"
    [[ -n "$message" ]] && printf "${color}│${RST} ${TEXT_SECONDARY}${message}${RST}\n"
    printf "${color}╰─────────────────────────────────────────────────────────────────╯${RST}\n"
}

# Desktop notification (OS-specific)
notify_desktop() {
    local icon="$1"
    local title="$2"
    local message="$3"
    local type="$4"

    local os=$(get_os)

    case "$os" in
        macos)
            osascript -e "display notification \"$message\" with title \"$icon $title\" sound name \"default\"" 2>/dev/null &
            ;;
        linux)
            if command -v notify-send &>/dev/null; then
                local urgency="normal"
                [[ "$type" == "critical" ]] && urgency="critical"
                [[ "$type" == "error" ]] && urgency="critical"

                notify-send -u "$urgency" "$icon $title" "$message" 2>/dev/null &
            fi
            ;;
    esac
}

# Sound notification
notify_sound() {
    local sound="$1"

    local os=$(get_os)

    case "$os" in
        macos)
            afplay "/System/Library/Sounds/${sound}.aiff" 2>/dev/null &
            ;;
        linux)
            if command -v paplay &>/dev/null; then
                paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
            elif command -v aplay &>/dev/null; then
                aplay /usr/share/sounds/sound-icons/prompt.wav 2>/dev/null &
            fi
            ;;
    esac
}

# Log notification to file
log_notification() {
    local type="$1"
    local title="$2"
    local message="$3"

    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    printf "[%s] [%s] %s: %s\n" "$timestamp" "$type" "$title" "$message" >> "$NOTIFICATION_LOG"
}

#───────────────────────────────────────────────────────────────────────────────
# WEBHOOK INTEGRATIONS
#───────────────────────────────────────────────────────────────────────────────

# Dispatch to all configured webhooks
notify_webhooks() {
    local type="$1"
    local title="$2"
    local message="$3"

    [[ -n "$SLACK_WEBHOOK_URL" ]] && notify_slack "$type" "$title" "$message" &
    [[ -n "$DISCORD_WEBHOOK_URL" ]] && notify_discord "$type" "$title" "$message" &
    [[ -n "$TELEGRAM_BOT_TOKEN" ]] && notify_telegram "$type" "$title" "$message" &

    wait
}

# Slack webhook
notify_slack() {
    local type="$1"
    local title="$2"
    local message="$3"

    local color="#00d4ff"
    case "$type" in
        success) color="#14f195" ;;
        warning) color="#ffd700" ;;
        error|critical) color="#ff5252" ;;
    esac

    local payload=$(cat << EOF
{
    "attachments": [{
        "color": "$color",
        "title": "[$type] $title",
        "text": "$message",
        "footer": "BlackRoad Dashboards",
        "ts": $(date +%s)
    }]
}
EOF
)

    curl -s -X POST -H 'Content-type: application/json' \
        --data "$payload" "$SLACK_WEBHOOK_URL" >/dev/null 2>&1
}

# Discord webhook
notify_discord() {
    local type="$1"
    local title="$2"
    local message="$3"

    local color=65535  # cyan
    case "$type" in
        success) color=1369587 ;;
        warning) color=16766720 ;;
        error|critical) color=16724530 ;;
    esac

    local payload=$(cat << EOF
{
    "embeds": [{
        "title": "[$type] $title",
        "description": "$message",
        "color": $color,
        "footer": {
            "text": "BlackRoad Dashboards"
        },
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    }]
}
EOF
)

    curl -s -X POST -H 'Content-type: application/json' \
        --data "$payload" "$DISCORD_WEBHOOK_URL" >/dev/null 2>&1
}

# Telegram notification
notify_telegram() {
    local type="$1"
    local title="$2"
    local message="$3"

    [[ -z "$TELEGRAM_CHAT_ID" ]] && return 1

    local icon="ℹ️"
    case "$type" in
        success) icon="✅" ;;
        warning) icon="⚠️" ;;
        error) icon="❌" ;;
        critical) icon="🚨" ;;
    esac

    local text="$icon *[$type]* $title
$message

_BlackRoad Dashboards_"

    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$text" \
        -d parse_mode="Markdown" >/dev/null 2>&1
}

#───────────────────────────────────────────────────────────────────────────────
# CONVENIENCE FUNCTIONS
#───────────────────────────────────────────────────────────────────────────────

notify_info()     { notify "info" "$1" "$2" "${3:-all}"; }
notify_success()  { notify "success" "$1" "$2" "${3:-all}"; }
notify_warning()  { notify "warning" "$1" "$2" "${3:-all}"; }
notify_error()    { notify "error" "$1" "$2" "${3:-all}"; }
notify_critical() { notify "critical" "$1" "$2" "${3:-all}"; }
notify_alert()    { notify "alert" "$1" "$2" "${3:-all}"; }
notify_update()   { notify "update" "$1" "$2" "${3:-all}"; }
notify_security() { notify "security" "$1" "$2" "${3:-all}"; }
notify_deploy()   { notify "deploy" "$1" "$2" "${3:-all}"; }
notify_payment()  { notify "payment" "$1" "$2" "${3:-all}"; }

#───────────────────────────────────────────────────────────────────────────────
# NOTIFICATION CENTER (Interactive UI)
#───────────────────────────────────────────────────────────────────────────────

notification_center() {
    local mode="${1:-view}"

    case "$mode" in
        view) notification_center_view ;;
        test) notification_center_test ;;
        clear) notification_center_clear ;;
        config) notification_center_config ;;
    esac
}

notification_center_view() {
    clear_screen
    cursor_hide

    printf "${BR_CYAN}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                    🔔 BLACKROAD NOTIFICATION CENTER                      ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    # Channel status
    printf "${TEXT_SECONDARY}Active Channels:${RST} "
    [[ "$NOTIFY_TERMINAL" == "1" ]] && printf "${BR_GREEN}Terminal${RST} "
    [[ "$NOTIFY_DESKTOP" == "1" ]] && printf "${BR_GREEN}Desktop${RST} "
    [[ "$NOTIFY_SOUND" == "1" ]] && printf "${BR_GREEN}Sound${RST} "
    [[ "$NOTIFY_WEBHOOK" == "1" ]] && printf "${BR_GREEN}Webhooks${RST} "
    printf "\n\n"

    # Recent notifications
    printf "${BOLD}Recent Notifications:${RST}\n"
    printf "${TEXT_MUTED}─────────────────────────────────────────────────────────────────${RST}\n"

    if [[ -f "$NOTIFICATION_LOG" ]]; then
        tail -20 "$NOTIFICATION_LOG" | while IFS= read -r line; do
            local type=$(echo "$line" | grep -oE '\[(INFO|SUCCESS|WARNING|ERROR|CRITICAL|ALERT)\]' | tr -d '[]')
            local color="$BR_CYAN"

            case "$type" in
                SUCCESS) color="$BR_GREEN" ;;
                WARNING) color="$BR_YELLOW" ;;
                ERROR|CRITICAL) color="$BR_RED" ;;
                ALERT) color="$BR_ORANGE" ;;
            esac

            printf "${color}%s${RST}\n" "$line"
        done
    else
        printf "${TEXT_MUTED}No notifications yet.${RST}\n"
    fi

    printf "\n${TEXT_SECONDARY}[t]est [c]lear [s]ettings [q]uit${RST}\n"

    # Handle input
    while true; do
        read -rsn1 key
        case "$key" in
            t|T) notification_center_test; notification_center_view ;;
            c|C) notification_center_clear; notification_center_view ;;
            s|S) notification_center_config ;;
            q|Q) cursor_show; return ;;
        esac
    done
}

notification_center_test() {
    printf "\n${BR_PURPLE}Sending test notifications...${RST}\n"

    notify_info "Test Info" "This is an informational notification"
    sleep 0.5
    notify_success "Test Success" "Operation completed successfully"
    sleep 0.5
    notify_warning "Test Warning" "This is a warning notification"
    sleep 0.5
    notify_error "Test Error" "Something went wrong"

    printf "${BR_GREEN}Test notifications sent!${RST}\n"
    sleep 2
}

notification_center_clear() {
    : > "$NOTIFICATION_LOG"
    printf "${BR_GREEN}Notification log cleared.${RST}\n"
    sleep 1
}

notification_center_config() {
    clear_screen

    printf "${BR_CYAN}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════╗\n"
    printf "║              ⚙️  NOTIFICATION SETTINGS                        ║\n"
    printf "╚══════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    printf "${BOLD}Channel Configuration:${RST}\n\n"

    printf "1. Terminal Notifications:  ${NOTIFY_TERMINAL:+${BR_GREEN}Enabled${RST}}${NOTIFY_TERMINAL:-${BR_RED}Disabled${RST}}\n"
    printf "2. Desktop Notifications:   ${NOTIFY_DESKTOP:+${BR_GREEN}Enabled${RST}}${NOTIFY_DESKTOP:-${BR_RED}Disabled${RST}}\n"
    printf "3. Sound Notifications:     ${NOTIFY_SOUND:+${BR_GREEN}Enabled${RST}}${NOTIFY_SOUND:-${BR_RED}Disabled${RST}}\n"
    printf "4. Webhook Notifications:   ${NOTIFY_WEBHOOK:+${BR_GREEN}Enabled${RST}}${NOTIFY_WEBHOOK:-${BR_RED}Disabled${RST}}\n"
    printf "5. Logging:                 ${NOTIFY_LOG:+${BR_GREEN}Enabled${RST}}${NOTIFY_LOG:-${BR_RED}Disabled${RST}}\n"

    printf "\n${BOLD}Webhook Configuration:${RST}\n\n"

    printf "Slack:    ${SLACK_WEBHOOK_URL:+${BR_GREEN}Configured${RST}}${SLACK_WEBHOOK_URL:-${TEXT_MUTED}Not configured${RST}}\n"
    printf "Discord:  ${DISCORD_WEBHOOK_URL:+${BR_GREEN}Configured${RST}}${DISCORD_WEBHOOK_URL:-${TEXT_MUTED}Not configured${RST}}\n"
    printf "Telegram: ${TELEGRAM_BOT_TOKEN:+${BR_GREEN}Configured${RST}}${TELEGRAM_BOT_TOKEN:-${TEXT_MUTED}Not configured${RST}}\n"

    printf "\n${TEXT_SECONDARY}Press any key to return...${RST}"
    read -rsn1
    notification_center_view
}

#───────────────────────────────────────────────────────────────────────────────
# SYSTEM MONITORING ALERTS
#───────────────────────────────────────────────────────────────────────────────

# Check system thresholds and notify
check_system_alerts() {
    local cpu_threshold="${1:-80}"
    local mem_threshold="${2:-85}"
    local disk_threshold="${3:-90}"

    local cpu=$(get_cpu_usage)
    local mem=$(get_memory_usage)
    local disk=$(get_disk_usage "/")

    [[ $cpu -gt $cpu_threshold ]] && \
        notify_warning "High CPU Usage" "CPU usage is at ${cpu}% (threshold: ${cpu_threshold}%)"

    [[ $mem -gt $mem_threshold ]] && \
        notify_warning "High Memory Usage" "Memory usage is at ${mem}% (threshold: ${mem_threshold}%)"

    [[ $disk -gt $disk_threshold ]] && \
        notify_critical "Disk Space Low" "Disk usage is at ${disk}% (threshold: ${disk_threshold}%)"
}

# Watch for service health
watch_service_health() {
    local service_name="$1"
    local check_command="$2"
    local interval="${3:-60}"

    while true; do
        if ! eval "$check_command" >/dev/null 2>&1; then
            notify_critical "Service Down" "$service_name is not responding"
        fi
        sleep "$interval"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-center}" in
        center)   notification_center "view" ;;
        test)     notification_center_test ;;
        clear)    notification_center_clear ;;
        config)   notification_center_config ;;
        notify)   notify "$2" "$3" "$4" "${5:-all}" ;;
        info)     notify_info "$2" "$3" ;;
        success)  notify_success "$2" "$3" ;;
        warning)  notify_warning "$2" "$3" ;;
        error)    notify_error "$2" "$3" ;;
        critical) notify_critical "$2" "$3" ;;
        watch)    check_system_alerts "$2" "$3" "$4" ;;
        *)
            printf "Usage: %s [center|test|clear|config|notify|watch]\n" "$0"
            printf "       %s notify <type> <title> <message>\n" "$0"
            printf "       %s info|success|warning|error|critical <title> <message>\n" "$0"
            ;;
    esac
fi
