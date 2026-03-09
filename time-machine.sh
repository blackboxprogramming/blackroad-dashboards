#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ████████╗██╗███╗   ███╗███████╗    ███╗   ███╗ █████╗  ██████╗██╗  ██╗██╗███╗   ██╗███████╗
#  ╚══██╔══╝██║████╗ ████║██╔════╝    ████╗ ████║██╔══██╗██╔════╝██║  ██║██║████╗  ██║██╔════╝
#     ██║   ██║██╔████╔██║█████╗      ██╔████╔██║███████║██║     ███████║██║██╔██╗ ██║█████╗
#     ██║   ██║██║╚██╔╝██║██╔══╝      ██║╚██╔╝██║██╔══██║██║     ██╔══██║██║██║╚██╗██║██╔══╝
#     ██║   ██║██║ ╚═╝ ██║███████╗    ██║ ╚═╝ ██║██║  ██║╚██████╗██║  ██║██║██║ ╚████║███████╗
#     ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD TIME MACHINE v3.0
#  Historical Data Recording, Replay & Trend Analysis
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

DATA_DIR="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}/timemachine"
SNAPSHOTS_DIR="$DATA_DIR/snapshots"
RECORDINGS_DIR="$DATA_DIR/recordings"
EVENTS_FILE="$DATA_DIR/events.log"

mkdir -p "$SNAPSHOTS_DIR" "$RECORDINGS_DIR" 2>/dev/null
touch "$EVENTS_FILE" 2>/dev/null

# Recording state
RECORDING_ACTIVE=false
RECORDING_NAME=""
RECORDING_START=0

#───────────────────────────────────────────────────────────────────────────────
# SNAPSHOT MANAGEMENT
#───────────────────────────────────────────────────────────────────────────────

take_snapshot() {
    local name="${1:-snapshot_$(date +%Y%m%d_%H%M%S)}"
    local snapshot_file="$SNAPSHOTS_DIR/${name}.json"

    local cpu=$(grep 'cpu ' /proc/stat 2>/dev/null | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f", usage}' || echo "0")
    local mem=$(free 2>/dev/null | awk '/Mem:/ {printf "%.1f", $3/$2 * 100}' || echo "0")
    local disk=$(df / 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%' || echo "0")
    local load=$(cat /proc/loadavg 2>/dev/null | awk '{print $1}' || echo "0")
    local connections=$(netstat -tunapl 2>/dev/null | grep -c ESTABLISHED || echo "0")
    local docker_count=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ' || echo "0")

    cat > "$snapshot_file" << EOF
{
    "name": "$name",
    "timestamp": "$(date -Iseconds)",
    "epoch": $(date +%s),
    "metrics": {
        "cpu": $cpu,
        "memory": $mem,
        "disk": $disk,
        "load": $load,
        "connections": $connections,
        "docker_containers": $docker_count
    },
    "hostname": "$(hostname)",
    "uptime": "$(uptime -p 2>/dev/null || uptime)"
}
EOF

    printf "${BR_GREEN}Snapshot saved: %s${RST}\n" "$name"
}

list_snapshots() {
    printf "${BOLD}Snapshots${RST}\n\n"
    printf "%-30s %-20s %-10s %-10s\n" "NAME" "TIMESTAMP" "CPU" "MEM"
    printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────────────────────────────────"

    for snapshot_file in "$SNAPSHOTS_DIR"/*.json; do
        [[ ! -f "$snapshot_file" ]] && continue
        if command -v jq &>/dev/null; then
            local name=$(jq -r '.name' "$snapshot_file" 2>/dev/null)
            local timestamp=$(jq -r '.timestamp' "$snapshot_file" 2>/dev/null)
            local cpu=$(jq -r '.metrics.cpu' "$snapshot_file" 2>/dev/null)
            local mem=$(jq -r '.metrics.memory' "$snapshot_file" 2>/dev/null)
            printf "%-30s %-20s %8.1f%% %8.1f%%\n" "${name:0:30}" "${timestamp:0:20}" "$cpu" "$mem"
        fi
    done
}

compare_snapshots() {
    local file1="$SNAPSHOTS_DIR/${1}.json"
    local file2="$SNAPSHOTS_DIR/${2}.json"

    [[ ! -f "$file1" || ! -f "$file2" ]] && { printf "${BR_RED}Snapshot not found${RST}\n"; return 1; }

    printf "${BOLD}Comparison: %s vs %s${RST}\n\n" "$1" "$2"
    printf "%-15s %-15s %-15s %-10s\n" "METRIC" "$1" "$2" "CHANGE"
    printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────────────────────"

    for metric in cpu memory disk load; do
        local val1=$(jq -r ".metrics.$metric // 0" "$file1")
        local val2=$(jq -r ".metrics.$metric // 0" "$file2")
        local diff=$(echo "$val2 - $val1" | bc -l 2>/dev/null || echo "0")
        printf "%-15s %-15s %-15s %+.2f\n" "$metric" "$val1" "$val2" "$diff"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# RECORDING SYSTEM
#───────────────────────────────────────────────────────────────────────────────

start_recording() {
    local name="${1:-recording_$(date +%Y%m%d_%H%M%S)}"
    local interval="${2:-5}"
    local recording_file="$RECORDINGS_DIR/${name}.rec"

    RECORDING_NAME="$name"
    RECORDING_START=$(date +%s)
    RECORDING_ACTIVE=true

    echo "# Recording: $name" > "$recording_file"
    echo "# Started: $(date -Iseconds)" >> "$recording_file"

    touch "$recording_file.lock"

    (
        while [[ -f "$recording_file.lock" ]]; do
            local ts=$(date +%s)
            local cpu=$(grep 'cpu ' /proc/stat 2>/dev/null | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f", usage}' || echo "0")
            local mem=$(free 2>/dev/null | awk '/Mem:/ {printf "%.1f", $3/$2 * 100}' || echo "0")
            local load=$(cat /proc/loadavg 2>/dev/null | awk '{print $1}' || echo "0")
            echo "$ts|$cpu|$mem|$load" >> "$recording_file"
            sleep "$interval"
        done
    ) &

    printf "${BR_GREEN}Recording started: %s${RST}\n" "$name"
}

stop_recording() {
    local recording_file="$RECORDINGS_DIR/${RECORDING_NAME}.rec"
    rm -f "$recording_file.lock"
    RECORDING_ACTIVE=false
    printf "${BR_GREEN}Recording stopped${RST}\n"
}

list_recordings() {
    printf "${BOLD}Recordings${RST}\n\n"
    for f in "$RECORDINGS_DIR"/*.rec; do
        [[ -f "$f" ]] && printf "  %s\n" "$(basename "$f" .rec)"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# REPLAY SYSTEM
#───────────────────────────────────────────────────────────────────────────────

replay_recording() {
    local name="$1"
    local speed="${2:-1}"
    local recording_file="$RECORDINGS_DIR/${name}.rec"

    [[ ! -f "$recording_file" ]] && { printf "${BR_RED}Recording not found${RST}\n"; return 1; }

    clear_screen
    cursor_hide

    printf "${BR_PURPLE}${BOLD}Replaying: %s (Speed: %.1fx)${RST}\n\n" "$name" "$speed"

    local idx=0
    while IFS='|' read -r ts cpu mem load; do
        [[ ! "$ts" =~ ^[0-9]+$ ]] && continue
        ((idx++))

        printf "\r  Time: %s  CPU: %6.1f%%  MEM: %6.1f%%  Load: %s    " \
            "$(date -d "@$ts" '+%H:%M:%S' 2>/dev/null || echo "$ts")" "$cpu" "$mem" "$load"

        local delay=$(echo "1 / $speed" | bc -l 2>/dev/null || echo 1)
        sleep "$delay"
    done < "$recording_file"

    printf "\n\n${BR_GREEN}Replay complete! (%d points)${RST}\n" "$idx"
    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# EVENT LOGGING
#───────────────────────────────────────────────────────────────────────────────

log_event() {
    echo "$(date -Iseconds)|$1|$2|$3" >> "$EVENTS_FILE"
}

show_events() {
    printf "${BOLD}Recent Events${RST}\n\n"
    tail -n "${1:-20}" "$EVENTS_FILE" 2>/dev/null | while IFS='|' read -r ts type source msg; do
        printf "%-25s %-10s %-15s %s\n" "${ts:0:25}" "$type" "$source" "$msg"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

time_machine_dashboard() {
    clear_screen
    cursor_hide

    while true; do
        cursor_to 1 1

        printf "${BR_PURPLE}${BOLD}"
        printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
        printf "║                         ⏱️  TIME MACHINE                                      ║\n"
        printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
        printf "${RST}\n"

        local snap_count=$(ls "$SNAPSHOTS_DIR"/*.json 2>/dev/null | wc -l)
        local rec_count=$(ls "$RECORDINGS_DIR"/*.rec 2>/dev/null | wc -l)

        printf "  ${BOLD}Snapshots:${RST} ${BR_CYAN}%s${RST}  " "$snap_count"
        printf "${BOLD}Recordings:${RST} ${BR_YELLOW}%s${RST}\n\n" "$rec_count"

        [[ "$RECORDING_ACTIVE" == "true" ]] && \
            printf "  ${BR_RED}● RECORDING:${RST} %s\n\n" "$RECORDING_NAME"

        printf "${BOLD}Options:${RST}\n"
        printf "  ${BR_CYAN}1.${RST} Take Snapshot    ${BR_CYAN}4.${RST} List Snapshots\n"
        printf "  ${BR_CYAN}2.${RST} Start Recording  ${BR_CYAN}5.${RST} List Recordings\n"
        printf "  ${BR_CYAN}3.${RST} Stop Recording   ${BR_CYAN}6.${RST} Replay Recording\n"
        printf "  ${BR_CYAN}7.${RST} Compare          ${BR_CYAN}8.${RST} Events\n"
        printf "  ${TEXT_MUTED}Q.${RST} Quit\n\n"

        read -rsn1 choice
        case "$choice" in
            1) printf "\n${BR_CYAN}Name: ${RST}"; read -r n; take_snapshot "$n"; sleep 1 ;;
            2) printf "\n${BR_CYAN}Name: ${RST}"; read -r n; start_recording "$n"; sleep 1 ;;
            3) stop_recording; sleep 1 ;;
            4) clear_screen; list_snapshots; read -rsn1 ;;
            5) clear_screen; list_recordings; read -rsn1 ;;
            6) printf "\n${BR_CYAN}Name: ${RST}"; read -r n; replay_recording "$n" ;;
            7) printf "\n${BR_CYAN}Snap 1: ${RST}"; read -r s1; printf "${BR_CYAN}Snap 2: ${RST}"; read -r s2; compare_snapshots "$s1" "$s2"; read -rsn1 ;;
            8) clear_screen; show_events 30; read -rsn1 ;;
            q|Q) break ;;
        esac
        clear_screen
    done
    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-dashboard}" in
        dashboard)   time_machine_dashboard ;;
        snapshot)    take_snapshot "$2" ;;
        snapshots)   list_snapshots ;;
        compare)     compare_snapshots "$2" "$3" ;;
        record)      start_recording "$2" "$3" ;;
        stop)        stop_recording ;;
        recordings)  list_recordings ;;
        replay)      replay_recording "$2" "$3" ;;
        events)      show_events "$2" ;;
        log)         log_event "$2" "$3" "$4" ;;
        *)           printf "Usage: %s [dashboard|snapshot|record|replay|...]\n" "$0" ;;
    esac
fi
