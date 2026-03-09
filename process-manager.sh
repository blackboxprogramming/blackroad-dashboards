#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██████╗ ██████╗  ██████╗  ██████╗███████╗███████╗███████╗
#  ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔════╝██╔════╝██╔════╝
#  ██████╔╝██████╔╝██║   ██║██║     █████╗  ███████╗███████╗
#  ██╔═══╝ ██╔══██╗██║   ██║██║     ██╔══╝  ╚════██║╚════██║
#  ██║     ██║  ██║╚██████╔╝╚██████╗███████╗███████║███████║
#  ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚══════╝╚══════╝╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD PROCESS MANAGER v3.0
#  Interactive htop-like Process Viewer & Manager
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

SORT_BY="cpu"  # cpu, mem, pid, name
SORT_ORDER="desc"
FILTER=""
SELECTED_IDX=0
SCROLL_OFFSET=0
SHOW_THREADS=false
SHOW_TREE=false
MAX_DISPLAY=20

#───────────────────────────────────────────────────────────────────────────────
# SYSTEM METRICS
#───────────────────────────────────────────────────────────────────────────────

get_cpu_usage() {
    local idle=$(grep 'cpu ' /proc/stat | awk '{print $5}')
    local total=$(grep 'cpu ' /proc/stat | awk '{print $2+$3+$4+$5+$6+$7+$8}')

    if [[ -f /tmp/cpu_prev ]]; then
        local prev_idle=$(cut -d' ' -f1 /tmp/cpu_prev)
        local prev_total=$(cut -d' ' -f2 /tmp/cpu_prev)

        local diff_idle=$((idle - prev_idle))
        local diff_total=$((total - prev_total))

        if [[ $diff_total -gt 0 ]]; then
            echo "scale=1; 100 * (1 - $diff_idle / $diff_total)" | bc -l 2>/dev/null || echo "0"
        else
            echo "0"
        fi
    else
        echo "0"
    fi

    echo "$idle $total" > /tmp/cpu_prev
}

get_memory_info() {
    local total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local used=$((total - available))
    local pct=$((used * 100 / total))

    echo "$used|$total|$pct"
}

get_swap_info() {
    local total=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    local free=$(grep SwapFree /proc/meminfo | awk '{print $2}')
    local used=$((total - free))
    local pct=0
    [[ $total -gt 0 ]] && pct=$((used * 100 / total))

    echo "$used|$total|$pct"
}

get_load_average() {
    cat /proc/loadavg | awk '{print $1, $2, $3}'
}

get_uptime() {
    uptime -p 2>/dev/null || uptime | grep -oP 'up \K[^,]+'
}

get_cpu_count() {
    nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo
}

#───────────────────────────────────────────────────────────────────────────────
# PROCESS LISTING
#───────────────────────────────────────────────────────────────────────────────

get_processes() {
    local sort_field=""
    local sort_flags="-rn"

    case "$SORT_BY" in
        cpu)  sort_field=3 ;;
        mem)  sort_field=4 ;;
        pid)  sort_field=1; sort_flags="-n" ;;
        name) sort_field=5; sort_flags="" ;;
    esac

    [[ "$SORT_ORDER" == "asc" ]] && sort_flags="${sort_flags//-r/}"

    local thread_flag=""
    [[ "$SHOW_THREADS" == "true" ]] && thread_flag="-L"

    ps aux $thread_flag --no-headers 2>/dev/null | \
    awk '{printf "%s|%s|%.1f|%.1f|%s|%s\n", $2, $1, $3, $4, $11, $0}' | \
    sort -t'|' -k${sort_field} $sort_flags | \
    if [[ -n "$FILTER" ]]; then
        grep -i "$FILTER"
    else
        cat
    fi
}

get_process_count() {
    ps aux --no-headers 2>/dev/null | wc -l
}

get_thread_count() {
    ps -eLf --no-headers 2>/dev/null | wc -l
}

get_running_count() {
    ps aux --no-headers 2>/dev/null | awk '$8 ~ /R/ {count++} END {print count+0}'
}

#───────────────────────────────────────────────────────────────────────────────
# PROCESS TREE
#───────────────────────────────────────────────────────────────────────────────

get_process_tree() {
    if command -v pstree &>/dev/null; then
        pstree -p -U 2>/dev/null | head -50
    else
        ps auxf --no-headers 2>/dev/null | head -50
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# PROCESS ACTIONS
#───────────────────────────────────────────────────────────────────────────────

kill_process() {
    local pid="$1"
    local signal="${2:-15}"

    kill -"$signal" "$pid" 2>/dev/null
}

renice_process() {
    local pid="$1"
    local priority="$2"

    renice "$priority" -p "$pid" 2>/dev/null
}

get_process_details() {
    local pid="$1"

    local cmdline=$(cat /proc/"$pid"/cmdline 2>/dev/null | tr '\0' ' ')
    local status=$(cat /proc/"$pid"/status 2>/dev/null)
    local stat=$(cat /proc/"$pid"/stat 2>/dev/null)
    local fd_count=$(ls /proc/"$pid"/fd 2>/dev/null | wc -l)

    local name=$(echo "$status" | grep ^Name: | awk '{print $2}')
    local state=$(echo "$status" | grep ^State: | awk '{print $2}')
    local ppid=$(echo "$status" | grep ^PPid: | awk '{print $2}')
    local threads=$(echo "$status" | grep ^Threads: | awk '{print $2}')
    local vm_rss=$(echo "$status" | grep ^VmRSS: | awk '{print $2, $3}')
    local vm_size=$(echo "$status" | grep ^VmSize: | awk '{print $2, $3}')
    local uid=$(echo "$status" | grep ^Uid: | awk '{print $2}')

    local user=$(getent passwd "$uid" 2>/dev/null | cut -d: -f1)
    [[ -z "$user" ]] && user="$uid"

    printf "PID: %s\n" "$pid"
    printf "Name: %s\n" "$name"
    printf "State: %s\n" "$state"
    printf "User: %s\n" "$user"
    printf "PPID: %s\n" "$ppid"
    printf "Threads: %s\n" "$threads"
    printf "Memory (RSS): %s\n" "$vm_rss"
    printf "Virtual Size: %s\n" "$vm_size"
    printf "File Descriptors: %s\n" "$fd_count"
    printf "Command: %s\n" "${cmdline:0:60}"
}

#───────────────────────────────────────────────────────────────────────────────
# RENDERING
#───────────────────────────────────────────────────────────────────────────────

render_meter() {
    local value="$1"
    local max="${2:-100}"
    local width="${3:-30}"
    local label="${4:-}"
    local color="${5:-}"

    local filled=$((value * width / max))
    [[ $filled -gt $width ]] && filled=$width
    local empty=$((width - filled))

    [[ -z "$color" ]] && {
        if [[ $value -gt 80 ]]; then
            color="\033[38;5;196m"
        elif [[ $value -gt 50 ]]; then
            color="\033[38;5;226m"
        else
            color="\033[38;5;46m"
        fi
    }

    printf "%s" "$color"
    printf "%0.s|" $(seq 1 $filled 2>/dev/null) || true
    printf "\033[38;5;240m"
    printf "%0.s|" $(seq 1 $empty 2>/dev/null) || true
    printf "\033[0m"

    [[ -n "$label" ]] && printf " %s" "$label"
}

render_cpu_meters() {
    local cpu_count=$(get_cpu_count)
    local overall=$(get_cpu_usage)

    printf "  \033[1mCPU\033[0m ["
    render_meter "${overall%.*}" 100 20
    printf "] %.1f%%\n" "$overall"

    # Per-CPU if available
    if [[ -f /proc/stat ]] && [[ $cpu_count -le 8 ]]; then
        for ((i=0; i<cpu_count && i<4; i++)); do
            local cpu_line=$(grep "^cpu$i " /proc/stat)
            local user=$(echo "$cpu_line" | awk '{print $2}')
            local system=$(echo "$cpu_line" | awk '{print $4}')
            local idle=$(echo "$cpu_line" | awk '{print $5}')
            local total=$((user + system + idle))
            local usage=0
            [[ $total -gt 0 ]] && usage=$(( (user + system) * 100 / total ))

            printf "  \033[38;5;240mCPU%d\033[0m [" "$i"
            render_meter "$usage" 100 15
            printf "] %3d%%\n" "$usage"
        done
    fi
}

render_memory_meters() {
    IFS='|' read -r mem_used mem_total mem_pct <<< "$(get_memory_info)"
    IFS='|' read -r swap_used swap_total swap_pct <<< "$(get_swap_info)"

    local mem_gb=$(echo "scale=1; $mem_used / 1048576" | bc -l 2>/dev/null || echo "0")
    local mem_total_gb=$(echo "scale=1; $mem_total / 1048576" | bc -l 2>/dev/null || echo "0")

    printf "  \033[1mMem\033[0m ["
    render_meter "$mem_pct" 100 20
    printf "] %.1fG/%.1fG\n" "$mem_gb" "$mem_total_gb"

    if [[ $swap_total -gt 0 ]]; then
        local swap_gb=$(echo "scale=1; $swap_used / 1048576" | bc -l 2>/dev/null || echo "0")
        local swap_total_gb=$(echo "scale=1; $swap_total / 1048576" | bc -l 2>/dev/null || echo "0")

        printf "  \033[1mSwp\033[0m ["
        render_meter "$swap_pct" 100 20
        printf "] %.1fG/%.1fG\n" "$swap_gb" "$swap_total_gb"
    fi
}

render_header() {
    printf "\033[1;38;5;39m"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                       ⚡ BLACKROAD PROCESS MANAGER                            ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "\033[0m\n"
}

render_system_info() {
    render_cpu_meters
    printf "\n"
    render_memory_meters
    printf "\n"

    local load=$(get_load_average)
    local uptime=$(get_uptime)
    local procs=$(get_process_count)
    local threads=$(get_thread_count)
    local running=$(get_running_count)

    printf "  \033[1mLoad:\033[0m %s  \033[1mUptime:\033[0m %s\n" "$load" "$uptime"
    printf "  \033[1mTasks:\033[0m %d total, \033[38;5;46m%d running\033[0m, %d threads\n" "$procs" "$running" "$threads"
}

render_process_list() {
    local -a processes
    mapfile -t processes < <(get_processes)

    local total=${#processes[@]}

    # Adjust scroll
    [[ $SELECTED_IDX -lt 0 ]] && SELECTED_IDX=0
    [[ $SELECTED_IDX -ge $total ]] && SELECTED_IDX=$((total - 1))
    [[ $SELECTED_IDX -lt $SCROLL_OFFSET ]] && SCROLL_OFFSET=$SELECTED_IDX
    [[ $SELECTED_IDX -ge $((SCROLL_OFFSET + MAX_DISPLAY)) ]] && SCROLL_OFFSET=$((SELECTED_IDX - MAX_DISPLAY + 1))

    printf "\n"
    printf "\033[1;38;5;240m"
    printf "  %6s %8s %6s %6s  %-40s\n" "PID" "USER" "CPU%" "MEM%" "COMMAND"
    printf "  ────────────────────────────────────────────────────────────────────────\033[0m\n"

    for ((i=SCROLL_OFFSET; i<SCROLL_OFFSET+MAX_DISPLAY && i<total; i++)); do
        IFS='|' read -r pid user cpu mem cmd full <<< "${processes[$i]}"

        local line_color=""
        local prefix="  "

        if [[ $i -eq $SELECTED_IDX ]]; then
            line_color="\033[48;5;236m\033[1m"
            prefix="\033[38;5;51m▶\033[0m${line_color} "
        fi

        # Color CPU/MEM
        local cpu_color="\033[38;5;46m"
        [[ ${cpu%.*} -gt 50 ]] && cpu_color="\033[38;5;226m"
        [[ ${cpu%.*} -gt 80 ]] && cpu_color="\033[38;5;196m"

        local mem_color="\033[38;5;39m"
        [[ ${mem%.*} -gt 50 ]] && mem_color="\033[38;5;226m"
        [[ ${mem%.*} -gt 80 ]] && mem_color="\033[38;5;196m"

        printf "%s%s%6s \033[38;5;243m%8s\033[0m%s %s%5.1f%% %s%5.1f%%\033[0m%s  %-40s\033[0m\n" \
            "$line_color" "$prefix" "$pid" "${user:0:8}" "$line_color" "$cpu_color" "$cpu" "$mem_color" "$mem" "$line_color" "${cmd:0:40}"
    done

    # Scroll indicator
    if [[ $total -gt $MAX_DISPLAY ]]; then
        printf "\n  \033[38;5;240m[%d-%d of %d]\033[0m" "$((SCROLL_OFFSET + 1))" "$((SCROLL_OFFSET + MAX_DISPLAY))" "$total"
    fi
}

render_controls() {
    printf "\n\n\033[38;5;240m───────────────────────────────────────────────────────────────────────────────\033[0m\n"
    printf "  \033[38;5;39m↑/↓\033[0m Navigate  "
    printf "\033[38;5;196mF9\033[0m Kill  "
    printf "\033[38;5;226mk\033[0m SIGKILL  "
    printf "\033[38;5;46ms\033[0m Sort  "
    printf "\033[38;5;201m/\033[0m Filter  "
    printf "\033[38;5;240mq\033[0m Quit\n"

    printf "  Sort: \033[38;5;51m%s\033[0m (%s)  " "$SORT_BY" "$SORT_ORDER"
    [[ -n "$FILTER" ]] && printf "Filter: \033[38;5;201m%s\033[0m  " "$FILTER"
    [[ "$SHOW_TREE" == "true" ]] && printf "\033[38;5;46m[TREE]\033[0m  "
    [[ "$SHOW_THREADS" == "true" ]] && printf "\033[38;5;226m[THREADS]\033[0m"
    printf "\n"
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN LOOP
#───────────────────────────────────────────────────────────────────────────────

process_manager_loop() {
    clear
    tput civis

    trap 'tput cnorm; clear; exit 0' INT TERM

    while true; do
        tput cup 0 0

        if [[ "$SHOW_TREE" == "true" ]]; then
            render_header
            printf "\033[1mProcess Tree:\033[0m\n\n"
            get_process_tree
            printf "\n\n\033[38;5;240mPress 't' to exit tree view, 'q' to quit\033[0m\n"
        else
            render_header
            render_system_info
            render_process_list
            render_controls
        fi

        # Handle input
        if read -rsn1 -t 1 key 2>/dev/null; then
            case "$key" in
                $'\x1b')
                    read -rsn2 -t 0.01 key2
                    case "$key2" in
                        '[A') ((SELECTED_IDX--)) ;;  # Up
                        '[B') ((SELECTED_IDX++)) ;;  # Down
                        '[5') ((SCROLL_OFFSET -= MAX_DISPLAY)); ((SELECTED_IDX -= MAX_DISPLAY)) ;;  # PgUp
                        '[6') ((SCROLL_OFFSET += MAX_DISPLAY)); ((SELECTED_IDX += MAX_DISPLAY)) ;;  # PgDn
                        '[2')  # F9 (some terminals)
                            read -rsn1
                            # Get selected PID and kill
                            local -a procs
                            mapfile -t procs < <(get_processes)
                            IFS='|' read -r pid rest <<< "${procs[$SELECTED_IDX]}"
                            [[ -n "$pid" ]] && kill_process "$pid" 15
                            ;;
                    esac
                    ;;
                k|K)
                    local -a procs
                    mapfile -t procs < <(get_processes)
                    IFS='|' read -r pid rest <<< "${procs[$SELECTED_IDX]}"
                    [[ -n "$pid" ]] && kill_process "$pid" 9
                    ;;
                9)  # F9 alternative
                    local -a procs
                    mapfile -t procs < <(get_processes)
                    IFS='|' read -r pid rest <<< "${procs[$SELECTED_IDX]}"
                    [[ -n "$pid" ]] && kill_process "$pid" 15
                    ;;
                s|S)
                    case "$SORT_BY" in
                        cpu) SORT_BY="mem" ;;
                        mem) SORT_BY="pid" ;;
                        pid) SORT_BY="name" ;;
                        *) SORT_BY="cpu" ;;
                    esac
                    ;;
                o|O)
                    [[ "$SORT_ORDER" == "desc" ]] && SORT_ORDER="asc" || SORT_ORDER="desc"
                    ;;
                /)
                    tput cnorm
                    printf "\n  Filter: "
                    read -r FILTER
                    tput civis
                    SELECTED_IDX=0
                    SCROLL_OFFSET=0
                    ;;
                c|C)
                    FILTER=""
                    SELECTED_IDX=0
                    SCROLL_OFFSET=0
                    ;;
                t|T)
                    [[ "$SHOW_TREE" == "true" ]] && SHOW_TREE=false || SHOW_TREE=true
                    clear
                    ;;
                h|H)
                    [[ "$SHOW_THREADS" == "true" ]] && SHOW_THREADS=false || SHOW_THREADS=true
                    ;;
                i|I)
                    # Show process details
                    local -a procs
                    mapfile -t procs < <(get_processes)
                    IFS='|' read -r pid rest <<< "${procs[$SELECTED_IDX]}"
                    if [[ -n "$pid" ]]; then
                        clear
                        printf "\033[1mProcess Details:\033[0m\n\n"
                        get_process_details "$pid"
                        printf "\n\nPress any key to continue..."
                        read -rsn1
                        clear
                    fi
                    ;;
                q|Q)
                    tput cnorm
                    clear
                    exit 0
                    ;;
            esac
        fi
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-run}" in
        run)     process_manager_loop ;;
        list)    get_processes | head -20 ;;
        tree)    get_process_tree ;;
        kill)    kill_process "$2" "${3:-15}" ;;
        info)    get_process_details "$2" ;;
        *)
            printf "Usage: %s [run|list|tree|kill|info]\n" "$0"
            ;;
    esac
fi
