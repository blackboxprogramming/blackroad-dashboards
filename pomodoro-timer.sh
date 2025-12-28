#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██████╗  ██████╗ ███╗   ███╗ ██████╗ ██████╗  ██████╗ ██████╗  ██████╗
#  ██╔══██╗██╔═══██╗████╗ ████║██╔═══██╗██╔══██╗██╔═══██╗██╔══██╗██╔═══██╗
#  ██████╔╝██║   ██║██╔████╔██║██║   ██║██║  ██║██║   ██║██████╔╝██║   ██║
#  ██╔═══╝ ██║   ██║██║╚██╔╝██║██║   ██║██║  ██║██║   ██║██╔══██╗██║   ██║
#  ██║     ╚██████╔╝██║ ╚═╝ ██║╚██████╔╝██████╔╝╚██████╔╝██║  ██║╚██████╔╝
#  ╚═╝      ╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD POMODORO TIMER v3.0
#  Productivity Timer with Statistics & Focus Tracking
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

DATA_DIR="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}/pomodoro"
STATS_FILE="$DATA_DIR/stats.json"
HISTORY_FILE="$DATA_DIR/history.log"

mkdir -p "$DATA_DIR" 2>/dev/null

# Timer settings (in minutes)
WORK_DURATION=25
SHORT_BREAK=5
LONG_BREAK=15
POMODOROS_UNTIL_LONG=4

# State
CURRENT_MODE="work"  # work, short_break, long_break
POMODORO_COUNT=0
TOTAL_FOCUS_TODAY=0
IS_PAUSED=false
CURRENT_TASK=""

#───────────────────────────────────────────────────────────────────────────────
# TIMER DISPLAY
#───────────────────────────────────────────────────────────────────────────────

render_big_time() {
    local minutes="$1"
    local seconds="$2"

    local time_str=$(printf "%02d:%02d" "$minutes" "$seconds")

    # Big digits
    declare -A DIGITS
    DIGITS[0]="█████
█   █
█   █
█   █
█████"
    DIGITS[1]="  █
  █
  █
  █
  █  "
    DIGITS[2]="█████
    █
█████
█
█████"
    DIGITS[3]="█████
    █
█████
    █
█████"
    DIGITS[4]="█   █
█   █
█████
    █
    █"
    DIGITS[5]="█████
█
█████
    █
█████"
    DIGITS[6]="█████
█
█████
█   █
█████"
    DIGITS[7]="█████
    █
   █
  █
 █   "
    DIGITS[8]="█████
█   █
█████
█   █
█████"
    DIGITS[9]="█████
█   █
█████
    █
█████"
    DIGITS[:]="
  █

  █
     "

    local color="\033[38;5;46m"
    [[ "$CURRENT_MODE" == "short_break" ]] && color="\033[38;5;39m"
    [[ "$CURRENT_MODE" == "long_break" ]] && color="\033[38;5;201m"
    [[ "$IS_PAUSED" == "true" ]] && color="\033[38;5;226m"

    # Render each row
    for row in 0 1 2 3 4; do
        printf "        "
        for ((i=0; i<${#time_str}; i++)); do
            local char="${time_str:$i:1}"
            local digit_art="${DIGITS[$char]}"
            local line=$(echo "$digit_art" | sed -n "$((row+1))p")
            printf "%s%s\033[0m " "$color" "$line"
        done
        printf "\n"
    done
}

render_progress_bar() {
    local current="$1"
    local total="$2"
    local width=50

    local filled=$((current * width / total))
    local empty=$((width - filled))

    local color="\033[38;5;46m"
    [[ "$CURRENT_MODE" == "short_break" ]] && color="\033[38;5;39m"
    [[ "$CURRENT_MODE" == "long_break" ]] && color="\033[38;5;201m"

    printf "        ["
    printf "%s" "$color"
    printf "%0.s█" $(seq 1 $filled 2>/dev/null) || true
    printf "\033[38;5;240m"
    printf "%0.s░" $(seq 1 $empty 2>/dev/null) || true
    printf "\033[0m]\n"
}

render_tomatoes() {
    local count="$1"
    local max="${2:-8}"

    printf "        "
    for ((i=1; i<=max; i++)); do
        if [[ $i -le $count ]]; then
            printf "\033[38;5;196m🍅\033[0m"
        else
            printf "\033[38;5;240m○ \033[0m"
        fi
    done
    printf "\n"
}

#───────────────────────────────────────────────────────────────────────────────
# NOTIFICATIONS
#───────────────────────────────────────────────────────────────────────────────

play_notification() {
    local type="$1"

    # Try different notification methods
    if command -v notify-send &>/dev/null; then
        case "$type" in
            work_done)
                notify-send "Pomodoro Complete!" "Time for a break 🎉" -i dialog-information
                ;;
            break_done)
                notify-send "Break Over!" "Ready to focus again? 💪" -i dialog-information
                ;;
        esac
    fi

    # Terminal bell
    printf "\a"

    # Sound (if available)
    if command -v paplay &>/dev/null; then
        paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
    elif command -v afplay &>/dev/null; then
        afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# STATISTICS
#───────────────────────────────────────────────────────────────────────────────

init_stats() {
    if [[ ! -f "$STATS_FILE" ]]; then
        echo '{"total_pomodoros":0,"total_focus_minutes":0,"daily_stats":{}}' > "$STATS_FILE"
    fi
}

update_stats() {
    local pomodoros="$1"
    local focus_minutes="$2"

    init_stats

    if command -v jq &>/dev/null; then
        local today=$(date +%Y-%m-%d)
        local updated=$(jq --arg date "$today" \
            --argjson poms "$pomodoros" \
            --argjson mins "$focus_minutes" \
            '.total_pomodoros += $poms |
             .total_focus_minutes += $mins |
             .daily_stats[$date].pomodoros = ((.daily_stats[$date].pomodoros // 0) + $poms) |
             .daily_stats[$date].minutes = ((.daily_stats[$date].minutes // 0) + $mins)' \
            "$STATS_FILE")
        echo "$updated" > "$STATS_FILE"
    fi
}

get_today_stats() {
    init_stats

    if command -v jq &>/dev/null; then
        local today=$(date +%Y-%m-%d)
        local poms=$(jq -r ".daily_stats[\"$today\"].pomodoros // 0" "$STATS_FILE")
        local mins=$(jq -r ".daily_stats[\"$today\"].minutes // 0" "$STATS_FILE")
        echo "$poms|$mins"
    else
        echo "0|0"
    fi
}

get_total_stats() {
    init_stats

    if command -v jq &>/dev/null; then
        local poms=$(jq -r '.total_pomodoros // 0' "$STATS_FILE")
        local mins=$(jq -r '.total_focus_minutes // 0' "$STATS_FILE")
        echo "$poms|$mins"
    else
        echo "0|0"
    fi
}

log_session() {
    local duration="$1"
    local mode="$2"
    local task="${3:-}"

    echo "$(date -Iseconds)|$mode|$duration|$task" >> "$HISTORY_FILE"
}

render_stats() {
    IFS='|' read -r today_poms today_mins <<< "$(get_today_stats)"
    IFS='|' read -r total_poms total_mins <<< "$(get_total_stats)"

    local today_hours=$((today_mins / 60))
    local today_remaining=$((today_mins % 60))
    local total_hours=$((total_mins / 60))

    printf "\n\033[1mStatistics\033[0m\n\n"
    printf "  \033[38;5;226mToday:\033[0m     %d pomodoros, %dh %dm focus time\n" "$today_poms" "$today_hours" "$today_remaining"
    printf "  \033[38;5;51mAll Time:\033[0m  %d pomodoros, %d hours total\n" "$total_poms" "$total_hours"
}

#───────────────────────────────────────────────────────────────────────────────
# TIMER LOGIC
#───────────────────────────────────────────────────────────────────────────────

run_timer() {
    local duration_minutes="$1"
    local duration_seconds=$((duration_minutes * 60))
    local start_time=$(date +%s)
    local paused_time=0

    clear
    tput civis

    trap 'tput cnorm; exit 0' INT TERM

    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time - paused_time))
        local remaining=$((duration_seconds - elapsed))

        if [[ $remaining -le 0 ]]; then
            # Timer complete
            play_notification "${CURRENT_MODE}_done"

            if [[ "$CURRENT_MODE" == "work" ]]; then
                ((POMODORO_COUNT++))
                ((TOTAL_FOCUS_TODAY += duration_minutes))
                update_stats 1 "$duration_minutes"
                log_session "$duration_minutes" "work" "$CURRENT_TASK"
            fi

            return 0
        fi

        local mins=$((remaining / 60))
        local secs=$((remaining % 60))

        # Render
        tput cup 0 0

        printf "\033[1;38;5;196m"
        printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
        printf "║                          🍅 POMODORO TIMER                                   ║\n"
        printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
        printf "\033[0m\n"

        # Mode indicator
        local mode_text=""
        case "$CURRENT_MODE" in
            work) mode_text="\033[38;5;196m🔥 FOCUS TIME\033[0m" ;;
            short_break) mode_text="\033[38;5;39m☕ SHORT BREAK\033[0m" ;;
            long_break) mode_text="\033[38;5;201m🌴 LONG BREAK\033[0m" ;;
        esac

        printf "        %s" "$mode_text"
        [[ "$IS_PAUSED" == "true" ]] && printf "  \033[38;5;226m⏸ PAUSED\033[0m"
        printf "\n\n"

        # Task name
        [[ -n "$CURRENT_TASK" ]] && printf "        \033[38;5;245mTask: %s\033[0m\n\n" "$CURRENT_TASK"

        # Big time display
        render_big_time "$mins" "$secs"
        printf "\n"

        # Progress bar
        local progress=$((elapsed * 100 / duration_seconds))
        render_progress_bar "$elapsed" "$duration_seconds"
        printf "\n"

        # Tomatoes
        render_tomatoes "$POMODORO_COUNT"
        printf "\n"

        # Stats
        render_stats

        # Controls
        printf "\n\033[38;5;240m───────────────────────────────────────────────────────────────────────────────\033[0m\n"
        printf "  \033[38;5;245m[Space] Pause  [S] Skip  [R] Reset  [Q] Quit\033[0m\n"

        # Handle input
        if [[ "$IS_PAUSED" == "true" ]]; then
            if read -rsn1 key 2>/dev/null; then
                case "$key" in
                    ' ')
                        IS_PAUSED=false
                        paused_time=$((paused_time + $(date +%s) - pause_start))
                        ;;
                    s|S) return 1 ;;  # Skip
                    r|R) return 2 ;;  # Reset
                    q|Q) tput cnorm; exit 0 ;;
                esac
            fi
        else
            if read -rsn1 -t 1 key 2>/dev/null; then
                case "$key" in
                    ' ')
                        IS_PAUSED=true
                        pause_start=$(date +%s)
                        ;;
                    s|S) return 1 ;;
                    r|R) return 2 ;;
                    q|Q) tput cnorm; exit 0 ;;
                esac
            fi
        fi
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN LOOP
#───────────────────────────────────────────────────────────────────────────────

pomodoro_cycle() {
    while true; do
        # Work session
        CURRENT_MODE="work"
        run_timer "$WORK_DURATION"
        local result=$?

        [[ $result -eq 2 ]] && continue  # Reset

        # Break
        if [[ $((POMODORO_COUNT % POMODOROS_UNTIL_LONG)) -eq 0 && $POMODORO_COUNT -gt 0 ]]; then
            CURRENT_MODE="long_break"
            run_timer "$LONG_BREAK"
        else
            CURRENT_MODE="short_break"
            run_timer "$SHORT_BREAK"
        fi
    done
}

start_pomodoro() {
    clear

    printf "\033[1;38;5;196m"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                          🍅 POMODORO TIMER                                   ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "\033[0m\n"

    printf "  \033[1mPomodoro Settings\033[0m\n\n"
    printf "  Work:        \033[38;5;196m%d minutes\033[0m\n" "$WORK_DURATION"
    printf "  Short Break: \033[38;5;39m%d minutes\033[0m\n" "$SHORT_BREAK"
    printf "  Long Break:  \033[38;5;201m%d minutes\033[0m (every %d pomodoros)\n\n" "$LONG_BREAK" "$POMODOROS_UNTIL_LONG"

    printf "  \033[38;5;51mWhat are you working on? (optional): \033[0m"
    read -r CURRENT_TASK

    printf "\n  \033[38;5;245mPress any key to start...\033[0m"
    read -rsn1

    pomodoro_cycle
}

#───────────────────────────────────────────────────────────────────────────────
# SETTINGS
#───────────────────────────────────────────────────────────────────────────────

settings_menu() {
    while true; do
        clear
        printf "\033[1mPomodoro Settings\033[0m\n\n"

        printf "  1. Work duration:       %d minutes\n" "$WORK_DURATION"
        printf "  2. Short break:         %d minutes\n" "$SHORT_BREAK"
        printf "  3. Long break:          %d minutes\n" "$LONG_BREAK"
        printf "  4. Pomodoros until long: %d\n" "$POMODOROS_UNTIL_LONG"
        printf "\n  S. Save & Start\n"
        printf "  Q. Back\n\n"
        printf "  Choice: "

        read -rsn1 choice

        case "$choice" in
            1)
                printf "\n  Work duration (minutes): "
                read -r val
                [[ "$val" =~ ^[0-9]+$ ]] && WORK_DURATION=$val
                ;;
            2)
                printf "\n  Short break (minutes): "
                read -r val
                [[ "$val" =~ ^[0-9]+$ ]] && SHORT_BREAK=$val
                ;;
            3)
                printf "\n  Long break (minutes): "
                read -r val
                [[ "$val" =~ ^[0-9]+$ ]] && LONG_BREAK=$val
                ;;
            4)
                printf "\n  Pomodoros until long break: "
                read -r val
                [[ "$val" =~ ^[0-9]+$ ]] && POMODOROS_UNTIL_LONG=$val
                ;;
            s|S) start_pomodoro; break ;;
            q|Q) break ;;
        esac
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-start}" in
        start)    start_pomodoro ;;
        settings) settings_menu ;;
        stats)    render_stats ;;
        *)
            printf "Usage: %s [start|settings|stats]\n" "$0"
            ;;
    esac
fi
