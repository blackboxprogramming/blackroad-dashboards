#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#   ██████╗ █████╗ ██╗     ███████╗███╗   ██╗██████╗  █████╗ ██████╗
#  ██╔════╝██╔══██╗██║     ██╔════╝████╗  ██║██╔══██╗██╔══██╗██╔══██╗
#  ██║     ███████║██║     █████╗  ██╔██╗ ██║██║  ██║███████║██████╔╝
#  ██║     ██╔══██║██║     ██╔══╝  ██║╚██╗██║██║  ██║██╔══██║██╔══██╗
#  ╚██████╗██║  ██║███████╗███████╗██║ ╚████║██████╔╝██║  ██║██║  ██║
#   ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD CALENDAR & TASK MANAGER v1.0
#  Terminal Calendar with Events & Todo Lists
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/blackroad-calendar"
EVENTS_FILE="$DATA_DIR/events.json"
TASKS_FILE="$DATA_DIR/tasks.json"

CURRENT_YEAR=$(date +%Y)
CURRENT_MONTH=$(date +%m)
CURRENT_DAY=$(date +%d)

SELECTED_YEAR=$CURRENT_YEAR
SELECTED_MONTH=$CURRENT_MONTH
SELECTED_DAY=$CURRENT_DAY

MONTH_NAMES=("" "January" "February" "March" "April" "May" "June"
             "July" "August" "September" "October" "November" "December")

DAY_NAMES=("Su" "Mo" "Tu" "We" "Th" "Fr" "Sa")

#───────────────────────────────────────────────────────────────────────────────
# DATA MANAGEMENT
#───────────────────────────────────────────────────────────────────────────────

init_data() {
    mkdir -p "$DATA_DIR"
    [[ ! -f "$EVENTS_FILE" ]] && echo '{"events":[]}' > "$EVENTS_FILE"
    [[ ! -f "$TASKS_FILE" ]] && echo '{"tasks":[]}' > "$TASKS_FILE"
}

get_events() {
    local date="$1"
    if command -v jq &>/dev/null && [[ -f "$EVENTS_FILE" ]]; then
        jq -r ".events[] | select(.date == \"$date\") | .title" "$EVENTS_FILE" 2>/dev/null
    fi
}

get_all_events() {
    if command -v jq &>/dev/null && [[ -f "$EVENTS_FILE" ]]; then
        jq -r '.events[] | "\(.date)|\(.title)|\(.time // "")|\(.color // "39")"' "$EVENTS_FILE" 2>/dev/null
    fi
}

add_event() {
    local date="$1"
    local title="$2"
    local time="${3:-}"
    local color="${4:-39}"

    if command -v jq &>/dev/null; then
        local new_event=$(jq -n \
            --arg date "$date" \
            --arg title "$title" \
            --arg time "$time" \
            --arg color "$color" \
            '{date: $date, title: $title, time: $time, color: $color}')

        jq ".events += [$new_event]" "$EVENTS_FILE" > "$EVENTS_FILE.tmp" && \
            mv "$EVENTS_FILE.tmp" "$EVENTS_FILE"
    fi
}

delete_event() {
    local date="$1"
    local title="$2"

    if command -v jq &>/dev/null; then
        jq "del(.events[] | select(.date == \"$date\" and .title == \"$title\"))" "$EVENTS_FILE" > "$EVENTS_FILE.tmp" && \
            mv "$EVENTS_FILE.tmp" "$EVENTS_FILE"
    fi
}

get_tasks() {
    local filter="${1:-all}"

    if command -v jq &>/dev/null && [[ -f "$TASKS_FILE" ]]; then
        case "$filter" in
            pending)
                jq -r '.tasks[] | select(.done == false) | "\(.id)|\(.title)|\(.priority)|\(.due // "")"' "$TASKS_FILE" 2>/dev/null
                ;;
            done)
                jq -r '.tasks[] | select(.done == true) | "\(.id)|\(.title)|\(.priority)|\(.due // "")"' "$TASKS_FILE" 2>/dev/null
                ;;
            *)
                jq -r '.tasks[] | "\(.id)|\(.title)|\(.priority)|\(.due // "")|\(.done)"' "$TASKS_FILE" 2>/dev/null
                ;;
        esac
    fi
}

add_task() {
    local title="$1"
    local priority="${2:-2}"
    local due="${3:-}"

    if command -v jq &>/dev/null; then
        local id=$(date +%s%N | sha256sum | head -c 8)

        local new_task=$(jq -n \
            --arg id "$id" \
            --arg title "$title" \
            --argjson priority "$priority" \
            --arg due "$due" \
            '{id: $id, title: $title, priority: $priority, due: $due, done: false, created: now | todate}')

        jq ".tasks += [$new_task]" "$TASKS_FILE" > "$TASKS_FILE.tmp" && \
            mv "$TASKS_FILE.tmp" "$TASKS_FILE"
    fi
}

toggle_task() {
    local id="$1"

    if command -v jq &>/dev/null; then
        jq "(.tasks[] | select(.id == \"$id\") | .done) |= not" "$TASKS_FILE" > "$TASKS_FILE.tmp" && \
            mv "$TASKS_FILE.tmp" "$TASKS_FILE"
    fi
}

delete_task() {
    local id="$1"

    if command -v jq &>/dev/null; then
        jq "del(.tasks[] | select(.id == \"$id\"))" "$TASKS_FILE" > "$TASKS_FILE.tmp" && \
            mv "$TASKS_FILE.tmp" "$TASKS_FILE"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# CALENDAR FUNCTIONS
#───────────────────────────────────────────────────────────────────────────────

get_days_in_month() {
    local year="$1"
    local month="$2"

    case "$month" in
        1|3|5|7|8|10|12) echo 31 ;;
        4|6|9|11) echo 30 ;;
        2)
            if [[ $((year % 4)) -eq 0 && ($((year % 100)) -ne 0 || $((year % 400)) -eq 0) ]]; then
                echo 29
            else
                echo 28
            fi
            ;;
    esac
}

get_first_weekday() {
    local year="$1"
    local month="$2"

    date -d "$year-$month-01" +%w 2>/dev/null || \
        date -j -f "%Y-%m-%d" "$year-$month-01" +%w 2>/dev/null || echo 0
}

has_events() {
    local date="$1"
    local events=$(get_events "$date")
    [[ -n "$events" ]]
}

#───────────────────────────────────────────────────────────────────────────────
# RENDERING
#───────────────────────────────────────────────────────────────────────────────

render_header() {
    printf "\033[1;38;5;214m"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                        📅 CALENDAR & TASK MANAGER                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    printf "\033[0m"
}

render_calendar() {
    local year="$SELECTED_YEAR"
    local month="$SELECTED_MONTH"
    local month_num=$((10#$month))

    local days_in_month=$(get_days_in_month "$year" "$month_num")
    local first_weekday=$(get_first_weekday "$year" "$(printf '%02d' $month_num)")

    printf "\n  \033[1;38;5;51m◀\033[0m  \033[1;38;5;226m%s %d\033[0m  \033[1;38;5;51m▶\033[0m\n\n" "${MONTH_NAMES[$month_num]}" "$year"

    # Day headers
    printf "  "
    for day_name in "${DAY_NAMES[@]}"; do
        printf "\033[38;5;39m%4s\033[0m" "$day_name"
    done
    printf "\n"

    # Days
    printf "  "
    for ((i=0; i<first_weekday; i++)); do
        printf "    "
    done

    local current_weekday=$first_weekday

    for ((day=1; day<=days_in_month; day++)); do
        local date_str=$(printf "%d-%02d-%02d" "$year" "$month_num" "$day")
        local is_today=false
        local is_selected=false
        local has_event=false

        [[ $year -eq $CURRENT_YEAR && $month_num -eq $((10#$CURRENT_MONTH)) && $day -eq $((10#$CURRENT_DAY)) ]] && is_today=true
        [[ $day -eq $((10#$SELECTED_DAY)) ]] && is_selected=true
        has_events "$date_str" && has_event=true

        if $is_selected; then
            printf "\033[48;5;39m\033[30m"
        elif $is_today; then
            printf "\033[48;5;236m\033[38;5;226m"
        fi

        if $has_event; then
            printf "\033[38;5;196m"
        fi

        printf "%4d" "$day"
        printf "\033[0m"

        ((current_weekday++))
        if [[ $current_weekday -ge 7 ]]; then
            printf "\n  "
            current_weekday=0
        fi
    done

    printf "\n"
}

render_day_events() {
    local date_str=$(printf "%d-%02d-%02d" "$SELECTED_YEAR" "$((10#$SELECTED_MONTH))" "$((10#$SELECTED_DAY))")

    printf "\n  \033[1;38;5;201m📌 Events for %s\033[0m\n" "$date_str"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"

    local events=$(get_events "$date_str")

    if [[ -z "$events" ]]; then
        printf "  \033[38;5;240mNo events for this day\033[0m\n"
    else
        while IFS= read -r event; do
            printf "  • \033[38;5;39m%s\033[0m\n" "$event"
        done <<< "$events"
    fi
}

render_tasks() {
    printf "\n  \033[1;38;5;46m✅ Tasks\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"

    local has_tasks=false

    while IFS='|' read -r id title priority due done; do
        [[ -z "$id" ]] && continue
        has_tasks=true

        local icon="☐"
        local style=""

        if [[ "$done" == "true" ]]; then
            icon="☑"
            style="\033[38;5;240m\033[9m"
        fi

        local priority_color="252"
        case "$priority" in
            1) priority_color="196" ;;  # High
            2) priority_color="226" ;;  # Medium
            3) priority_color="46" ;;   # Low
        esac

        printf "  \033[38;5;${priority_color}m%s\033[0m ${style}%s\033[0m" "$icon" "$title"

        if [[ -n "$due" ]]; then
            printf " \033[38;5;240m(%s)\033[0m" "$due"
        fi
        printf "\n"
    done < <(get_tasks "all")

    if ! $has_tasks; then
        printf "  \033[38;5;240mNo tasks yet\033[0m\n"
    fi
}

render_upcoming() {
    printf "\n  \033[1;38;5;208m📆 Upcoming Events\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"

    local today=$(date +%Y-%m-%d)
    local count=0

    while IFS='|' read -r date title time color; do
        [[ -z "$date" ]] && continue
        [[ "$date" < "$today" ]] && continue

        ((count++))
        [[ $count -gt 5 ]] && break

        printf "  \033[38;5;${color:-39}m●\033[0m %s " "$date"
        [[ -n "$time" ]] && printf "\033[38;5;240m%s\033[0m " "$time"
        printf "%s\n" "$title"
    done < <(get_all_events | sort)

    [[ $count -eq 0 ]] && printf "  \033[38;5;240mNo upcoming events\033[0m\n"
}

render_mini_calendars() {
    local year="$SELECTED_YEAR"
    local month="$((10#$SELECTED_MONTH))"

    # Previous month
    local prev_month=$((month - 1))
    local prev_year=$year
    [[ $prev_month -lt 1 ]] && prev_month=12 && ((prev_year--))

    # Next month
    local next_month=$((month + 1))
    local next_year=$year
    [[ $next_month -gt 12 ]] && next_month=1 && ((next_year++))

    printf "\n  \033[38;5;240m%-20s         %-20s\033[0m\n" "${MONTH_NAMES[$prev_month]} $prev_year" "${MONTH_NAMES[$next_month]} $next_year"
}

render_controls() {
    printf "\n  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"
    printf "  \033[38;5;39m←→\033[0m Day  "
    printf "\033[38;5;39m↑↓\033[0m Week  "
    printf "\033[38;5;46mn/p\033[0m Month  "
    printf "\033[38;5;226ma\033[0m Add Event  "
    printf "\033[38;5;201mt\033[0m Add Task  "
    printf "\033[38;5;240mq\033[0m Quit\n"
}

#───────────────────────────────────────────────────────────────────────────────
# INTERACTIVE MODE
#───────────────────────────────────────────────────────────────────────────────

prompt_add_event() {
    local date_str=$(printf "%d-%02d-%02d" "$SELECTED_YEAR" "$((10#$SELECTED_MONTH))" "$((10#$SELECTED_DAY))")

    tput cnorm
    printf "\n  \033[1;38;5;226m➕ Add Event for %s\033[0m\n" "$date_str"
    printf "  Title: "
    read -r title

    if [[ -n "$title" ]]; then
        printf "  Time (HH:MM, optional): "
        read -r time

        printf "  Color (39=blue, 46=green, 196=red, 226=yellow): "
        read -r color
        color="${color:-39}"

        add_event "$date_str" "$title" "$time" "$color"
        printf "  \033[38;5;46m✓ Event added!\033[0m\n"
    fi

    tput civis
    sleep 1
}

prompt_add_task() {
    tput cnorm
    printf "\n  \033[1;38;5;226m➕ Add Task\033[0m\n"
    printf "  Title: "
    read -r title

    if [[ -n "$title" ]]; then
        printf "  Priority (1=High, 2=Medium, 3=Low): "
        read -r priority
        priority="${priority:-2}"

        printf "  Due date (YYYY-MM-DD, optional): "
        read -r due

        add_task "$title" "$priority" "$due"
        printf "  \033[38;5;46m✓ Task added!\033[0m\n"
    fi

    tput civis
    sleep 1
}

interactive_mode() {
    init_data

    tput civis
    trap 'tput cnorm; clear; exit 0' INT TERM

    while true; do
        clear
        render_header
        render_calendar
        render_day_events
        render_tasks
        render_upcoming
        render_controls

        read -rsn1 key

        case "$key" in
            $'\x1b')
                read -rsn2 key2
                case "$key2" in
                    '[A')  # Up - previous week
                        SELECTED_DAY=$((10#$SELECTED_DAY - 7))
                        if [[ $SELECTED_DAY -lt 1 ]]; then
                            SELECTED_MONTH=$((10#$SELECTED_MONTH - 1))
                            if [[ $SELECTED_MONTH -lt 1 ]]; then
                                SELECTED_MONTH=12
                                ((SELECTED_YEAR--))
                            fi
                            local prev_days=$(get_days_in_month "$SELECTED_YEAR" "$SELECTED_MONTH")
                            SELECTED_DAY=$((prev_days + SELECTED_DAY))
                        fi
                        ;;
                    '[B')  # Down - next week
                        local days_in_month=$(get_days_in_month "$SELECTED_YEAR" "$((10#$SELECTED_MONTH))")
                        SELECTED_DAY=$((10#$SELECTED_DAY + 7))
                        if [[ $SELECTED_DAY -gt $days_in_month ]]; then
                            SELECTED_DAY=$((SELECTED_DAY - days_in_month))
                            SELECTED_MONTH=$((10#$SELECTED_MONTH + 1))
                            if [[ $SELECTED_MONTH -gt 12 ]]; then
                                SELECTED_MONTH=1
                                ((SELECTED_YEAR++))
                            fi
                        fi
                        ;;
                    '[C')  # Right - next day
                        local days_in_month=$(get_days_in_month "$SELECTED_YEAR" "$((10#$SELECTED_MONTH))")
                        SELECTED_DAY=$((10#$SELECTED_DAY + 1))
                        if [[ $SELECTED_DAY -gt $days_in_month ]]; then
                            SELECTED_DAY=1
                            SELECTED_MONTH=$((10#$SELECTED_MONTH + 1))
                            if [[ $SELECTED_MONTH -gt 12 ]]; then
                                SELECTED_MONTH=1
                                ((SELECTED_YEAR++))
                            fi
                        fi
                        ;;
                    '[D')  # Left - previous day
                        SELECTED_DAY=$((10#$SELECTED_DAY - 1))
                        if [[ $SELECTED_DAY -lt 1 ]]; then
                            SELECTED_MONTH=$((10#$SELECTED_MONTH - 1))
                            if [[ $SELECTED_MONTH -lt 1 ]]; then
                                SELECTED_MONTH=12
                                ((SELECTED_YEAR--))
                            fi
                            SELECTED_DAY=$(get_days_in_month "$SELECTED_YEAR" "$SELECTED_MONTH")
                        fi
                        ;;
                esac
                ;;
            n|N)  # Next month
                SELECTED_MONTH=$((10#$SELECTED_MONTH + 1))
                if [[ $SELECTED_MONTH -gt 12 ]]; then
                    SELECTED_MONTH=1
                    ((SELECTED_YEAR++))
                fi
                local max_day=$(get_days_in_month "$SELECTED_YEAR" "$SELECTED_MONTH")
                [[ $((10#$SELECTED_DAY)) -gt $max_day ]] && SELECTED_DAY=$max_day
                ;;
            p|P)  # Previous month
                SELECTED_MONTH=$((10#$SELECTED_MONTH - 1))
                if [[ $SELECTED_MONTH -lt 1 ]]; then
                    SELECTED_MONTH=12
                    ((SELECTED_YEAR--))
                fi
                local max_day=$(get_days_in_month "$SELECTED_YEAR" "$SELECTED_MONTH")
                [[ $((10#$SELECTED_DAY)) -gt $max_day ]] && SELECTED_DAY=$max_day
                ;;
            y|Y)  # Next year
                ((SELECTED_YEAR++))
                local max_day=$(get_days_in_month "$SELECTED_YEAR" "$SELECTED_MONTH")
                [[ $((10#$SELECTED_DAY)) -gt $max_day ]] && SELECTED_DAY=$max_day
                ;;
            u|U)  # Previous year
                ((SELECTED_YEAR--))
                local max_day=$(get_days_in_month "$SELECTED_YEAR" "$SELECTED_MONTH")
                [[ $((10#$SELECTED_DAY)) -gt $max_day ]] && SELECTED_DAY=$max_day
                ;;
            g|G)  # Go to today
                SELECTED_YEAR=$CURRENT_YEAR
                SELECTED_MONTH=$CURRENT_MONTH
                SELECTED_DAY=$CURRENT_DAY
                ;;
            a|A)  # Add event
                prompt_add_event
                ;;
            t|T)  # Add task
                prompt_add_task
                ;;
            d|D)  # Delete event
                tput cnorm
                local date_str=$(printf "%d-%02d-%02d" "$SELECTED_YEAR" "$((10#$SELECTED_MONTH))" "$((10#$SELECTED_DAY))")
                printf "\n  Event title to delete: "
                read -r title
                [[ -n "$title" ]] && delete_event "$date_str" "$title"
                tput civis
                ;;
            q|Q)
                tput cnorm
                clear
                exit 0
                ;;
        esac

        # Ensure valid month format
        SELECTED_MONTH=$(printf '%02d' "$((10#$SELECTED_MONTH))")
        SELECTED_DAY=$(printf '%02d' "$((10#$SELECTED_DAY))")
    done
}

#───────────────────────────────────────────────────────────────────────────────
# CLI COMMANDS
#───────────────────────────────────────────────────────────────────────────────

cmd_list_events() {
    local date="${1:-$(date +%Y-%m-%d)}"

    printf "\n  \033[1;38;5;201mEvents for %s\033[0m\n" "$date"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"

    local events=$(get_events "$date")
    if [[ -z "$events" ]]; then
        printf "  No events\n"
    else
        while IFS= read -r event; do
            printf "  • %s\n" "$event"
        done <<< "$events"
    fi
}

cmd_add_event() {
    local date="$1"
    local title="$2"
    local time="${3:-}"

    if [[ -z "$date" || -z "$title" ]]; then
        printf "Usage: calendar-manager.sh add <date> <title> [time]\n"
        exit 1
    fi

    add_event "$date" "$title" "$time"
    printf "✓ Event added: %s on %s\n" "$title" "$date"
}

cmd_list_tasks() {
    local filter="${1:-pending}"

    printf "\n  \033[1;38;5;46mTasks (%s)\033[0m\n" "$filter"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"

    while IFS='|' read -r id title priority due; do
        [[ -z "$id" ]] && continue

        local priority_icon="●"
        case "$priority" in
            1) priority_icon="\033[38;5;196m!!!\033[0m" ;;
            2) priority_icon="\033[38;5;226m!!\033[0m" ;;
            3) priority_icon="\033[38;5;46m!\033[0m" ;;
        esac

        printf "  [%s] %s %s" "$id" "$priority_icon" "$title"
        [[ -n "$due" ]] && printf " (due: %s)" "$due"
        printf "\n"
    done < <(get_tasks "$filter")
}

cmd_add_task() {
    local title="$1"
    local priority="${2:-2}"
    local due="${3:-}"

    if [[ -z "$title" ]]; then
        printf "Usage: calendar-manager.sh task-add <title> [priority] [due]\n"
        exit 1
    fi

    add_task "$title" "$priority" "$due"
    printf "✓ Task added: %s\n" "$title"
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

show_help() {
    cat << 'EOF'

  BLACKROAD CALENDAR & TASK MANAGER
  ══════════════════════════════════

  Usage: calendar-manager.sh [command] [options]

  Commands:
    (none)              Interactive calendar mode
    list [date]         List events for date (default: today)
    add <date> <title>  Add event
    tasks [filter]      List tasks (pending/done/all)
    task-add <title>    Add task

  Interactive Controls:
    ←→        Previous/Next day
    ↑↓        Previous/Next week
    n/p       Next/Previous month
    y/u       Next/Previous year
    g         Go to today
    a         Add event
    t         Add task
    d         Delete event
    q         Quit

  Examples:
    calendar-manager.sh                    # Interactive mode
    calendar-manager.sh list 2024-01-15    # Events for date
    calendar-manager.sh add 2024-01-20 "Meeting"
    calendar-manager.sh tasks pending
    calendar-manager.sh task-add "Review code" 1 2024-01-18

EOF
}

main() {
    init_data

    if [[ $# -eq 0 ]]; then
        interactive_mode
        exit 0
    fi

    case "$1" in
        list)
            cmd_list_events "$2"
            ;;
        add)
            cmd_add_event "$2" "$3" "$4"
            ;;
        tasks)
            cmd_list_tasks "$2"
            ;;
        task-add)
            cmd_add_task "$2" "$3" "$4"
            ;;
        -h|--help|help)
            show_help
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
