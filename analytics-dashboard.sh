#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#   █████╗  ███╗   ██╗ █████╗  ██╗  ██╗   ██╗ ████████╗ ██╗  ██████╗ ███████╗
#  ██╔══██╗ ████╗  ██║██╔══██╗ ██║  ╚██╗ ██╔╝ ╚══██╔══╝ ██║ ██╔════╝ ██╔════╝
#  ███████║ ██╔██╗ ██║███████║ ██║   ╚████╔╝     ██║    ██║ ██║      ███████╗
#  ██╔══██║ ██║╚██╗██║██╔══██║ ██║    ╚██╔╝      ██║    ██║ ██║      ╚════██║
#  ██║  ██║ ██║ ╚████║██║  ██║ ███████╗██║       ██║    ██║ ╚██████╗ ███████║
#  ╚═╝  ╚═╝ ╚═╝  ╚═══╝╚═╝  ╚═╝ ╚══════╝╚═╝       ╚═╝    ╚═╝  ╚═════╝ ╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD ANALYTICS DASHBOARD v2.0
#  Advanced metrics visualization, trends, and insights
#═══════════════════════════════════════════════════════════════════════════════

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"
[[ -f "$SCRIPT_DIR/lib-cache.sh" ]] && source "$SCRIPT_DIR/lib-cache.sh"
[[ -f "$SCRIPT_DIR/lib-parallel.sh" ]] && source "$SCRIPT_DIR/lib-parallel.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

ANALYTICS_HOME="${BLACKROAD_DATA:-$HOME/.blackroad-dashboards}/analytics"
METRICS_DB="$ANALYTICS_HOME/metrics.db"
mkdir -p "$ANALYTICS_HOME" 2>/dev/null

# Refresh interval (seconds)
REFRESH_INTERVAL=5

# Historical data points to keep
MAX_HISTORY_POINTS=100

# Metrics history arrays
declare -a CPU_HISTORY=()
declare -a MEM_HISTORY=()
declare -a NET_HISTORY=()
declare -a DISK_HISTORY=()

#───────────────────────────────────────────────────────────────────────────────
# CHART RENDERING
#───────────────────────────────────────────────────────────────────────────────

# Sparkline with color gradient
render_sparkline() {
    local -a values=("$@")
    local chars="▁▂▃▄▅▆▇█"
    local max=1 min=0

    # Find min/max
    for v in "${values[@]}"; do
        ((v > max)) && max=$v
    done

    local range=$((max - min))
    [[ $range -eq 0 ]] && range=1

    for v in "${values[@]}"; do
        local idx=$(( (v - min) * 7 / range ))
        # Color based on value (green->yellow->red)
        local color
        if ((v < 50)); then
            color="$BR_GREEN"
        elif ((v < 80)); then
            color="$BR_YELLOW"
        else
            color="$BR_RED"
        fi
        printf "${color}${chars:$idx:1}${RST}"
    done
}

# Bar chart (horizontal)
render_bar_chart() {
    local -a labels=()
    local -a values=()
    local max_value=0
    local bar_width=40

    # Parse input (label:value format)
    while [[ $# -gt 0 ]]; do
        local item="$1"
        local label=$(echo "$item" | cut -d: -f1)
        local value=$(echo "$item" | cut -d: -f2)

        labels+=("$label")
        values+=("$value")
        ((value > max_value)) && max_value=$value
        shift
    done

    [[ $max_value -eq 0 ]] && max_value=1

    for i in "${!labels[@]}"; do
        local bar_len=$((values[i] * bar_width / max_value))
        local color="$BR_CYAN"

        ((values[i] > 75)) && color="$BR_RED"
        ((values[i] > 50 && values[i] <= 75)) && color="$BR_YELLOW"

        printf "  ${TEXT_SECONDARY}%-12s${RST} " "${labels[$i]}"
        printf "${color}"
        printf "%0.s█" $(seq 1 "$bar_len" 2>/dev/null) || true
        printf "${TEXT_MUTED}"
        printf "%0.s░" $(seq 1 $((bar_width - bar_len)) 2>/dev/null) || true
        printf "${RST} ${TEXT_SECONDARY}%3d%%${RST}\n" "${values[$i]}"
    done
}

# Pie chart (ASCII approximation)
render_pie_chart() {
    local -a labels=()
    local -a values=()
    local total=0

    # Parse input
    while [[ $# -gt 0 ]]; do
        labels+=("$(echo "$1" | cut -d: -f1)")
        values+=("$(echo "$1" | cut -d: -f2)")
        total=$((total + $(echo "$1" | cut -d: -f2)))
        shift
    done

    [[ $total -eq 0 ]] && total=1

    local colors=("$BR_CYAN" "$BR_PINK" "$BR_ORANGE" "$BR_PURPLE" "$BR_GREEN" "$BR_YELLOW")
    local pie_chars="○◔◑◕●"

    printf "  "
    for i in "${!labels[@]}"; do
        local pct=$((values[i] * 100 / total))
        local fill_idx=$((pct * 4 / 100))
        [[ $fill_idx -gt 4 ]] && fill_idx=4

        printf "${colors[$((i % 6))]}${pie_chars:$fill_idx:1}${RST} "
    done
    printf "\n\n"

    # Legend
    for i in "${!labels[@]}"; do
        local pct=$((values[i] * 100 / total))
        printf "  ${colors[$((i % 6))]}●${RST} %-15s %3d%% (%d)\n" "${labels[$i]}" "$pct" "${values[$i]}"
    done
}

# Timeline chart
render_timeline() {
    local -a timestamps=()
    local -a values=()
    local width=60
    local height=8

    # Parse input
    while [[ $# -gt 0 ]]; do
        values+=("$1")
        shift
    done

    local max=1
    for v in "${values[@]}"; do
        ((v > max)) && max=$v
    done

    # Create grid
    local -a grid=()
    for ((row=0; row<height; row++)); do
        grid[$row]=""
        for ((col=0; col<${#values[@]}; col++)); do
            local threshold=$(( (height - row) * max / height ))
            if ((values[col] >= threshold)); then
                grid[$row]+="█"
            else
                grid[$row]+=" "
            fi
        done
    done

    # Render
    for ((row=0; row<height; row++)); do
        local label=$(( (height - row) * max / height ))
        printf "  ${TEXT_MUTED}%4d │${RST}${BR_CYAN}%s${RST}\n" "$label" "${grid[$row]}"
    done

    # X-axis
    printf "  ${TEXT_MUTED}     └"
    printf "%0.s─" $(seq 1 ${#values[@]})
    printf "${RST}\n"
}

#───────────────────────────────────────────────────────────────────────────────
# METRICS COLLECTION
#───────────────────────────────────────────────────────────────────────────────

# Collect and store metrics
collect_metrics() {
    local cpu=$(get_cpu_usage 2>/dev/null || echo "0")
    local mem=$(get_memory_usage 2>/dev/null || echo "0")
    local disk=$(get_disk_usage "/" 2>/dev/null || echo "0")

    # Add to history
    CPU_HISTORY+=("$cpu")
    MEM_HISTORY+=("$mem")
    DISK_HISTORY+=("$disk")

    # Trim history
    [[ ${#CPU_HISTORY[@]} -gt $MAX_HISTORY_POINTS ]] && CPU_HISTORY=("${CPU_HISTORY[@]:1}")
    [[ ${#MEM_HISTORY[@]} -gt $MAX_HISTORY_POINTS ]] && MEM_HISTORY=("${MEM_HISTORY[@]:1}")
    [[ ${#DISK_HISTORY[@]} -gt $MAX_HISTORY_POINTS ]] && DISK_HISTORY=("${DISK_HISTORY[@]:1}")
}

# Calculate statistics
calc_stats() {
    local -a values=("$@")
    local sum=0 count=${#values[@]} min=${values[0]:-0} max=${values[0]:-0}

    for v in "${values[@]}"; do
        sum=$((sum + v))
        ((v < min)) && min=$v
        ((v > max)) && max=$v
    done

    local avg=$((count > 0 ? sum / count : 0))

    echo "$min $max $avg"
}

# Trend detection
detect_trend() {
    local -a values=("$@")
    local len=${#values[@]}

    [[ $len -lt 3 ]] && echo "stable" && return

    local first_half_avg=0 second_half_avg=0
    local mid=$((len / 2))

    for ((i=0; i<mid; i++)); do
        first_half_avg=$((first_half_avg + values[i]))
    done
    first_half_avg=$((first_half_avg / mid))

    for ((i=mid; i<len; i++)); do
        second_half_avg=$((second_half_avg + values[i]))
    done
    second_half_avg=$((second_half_avg / (len - mid)))

    local diff=$((second_half_avg - first_half_avg))

    if ((diff > 5)); then
        echo "rising"
    elif ((diff < -5)); then
        echo "falling"
    else
        echo "stable"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# DASHBOARD PANELS
#───────────────────────────────────────────────────────────────────────────────

# System overview panel
panel_system_overview() {
    local cpu=$(get_cpu_usage 2>/dev/null || echo "0")
    local mem=$(get_memory_usage 2>/dev/null || echo "0")
    local disk=$(get_disk_usage "/" 2>/dev/null || echo "0")
    local uptime_sec=$(get_uptime_seconds 2>/dev/null || echo "0")
    local uptime_str=$(time_ago "$uptime_sec" 2>/dev/null || echo "unknown")

    printf "${BR_CYAN}${BOLD}┌─ SYSTEM OVERVIEW ─────────────────────────────────────────┐${RST}\n"
    printf "${BR_CYAN}│${RST}\n"

    render_bar_chart "CPU:$cpu" "Memory:$mem" "Disk:$disk"

    printf "${BR_CYAN}│${RST}\n"
    printf "${BR_CYAN}│${RST} ${TEXT_SECONDARY}Hostname:${RST} %-20s ${TEXT_SECONDARY}Uptime:${RST} %s\n" "$(hostname)" "$uptime_str"
    printf "${BR_CYAN}│${RST} ${TEXT_SECONDARY}OS:${RST} %-25s ${TEXT_SECONDARY}Kernel:${RST} %s\n" "$(uname -s)" "$(uname -r)"
    printf "${BR_CYAN}└────────────────────────────────────────────────────────────┘${RST}\n"
}

# Real-time metrics panel
panel_realtime_metrics() {
    printf "${BR_PURPLE}${BOLD}┌─ REAL-TIME METRICS ────────────────────────────────────────┐${RST}\n"
    printf "${BR_PURPLE}│${RST}\n"

    printf "${BR_PURPLE}│${RST} ${TEXT_SECONDARY}CPU History:${RST}    "
    render_sparkline "${CPU_HISTORY[@]}"
    printf "\n"

    printf "${BR_PURPLE}│${RST} ${TEXT_SECONDARY}Memory History:${RST} "
    render_sparkline "${MEM_HISTORY[@]}"
    printf "\n"

    printf "${BR_PURPLE}│${RST} ${TEXT_SECONDARY}Disk History:${RST}   "
    render_sparkline "${DISK_HISTORY[@]}"
    printf "\n"

    # Stats
    if [[ ${#CPU_HISTORY[@]} -gt 0 ]]; then
        read min max avg <<< "$(calc_stats "${CPU_HISTORY[@]}")"
        local trend=$(detect_trend "${CPU_HISTORY[@]}")
        local trend_icon="→"
        [[ "$trend" == "rising" ]] && trend_icon="↗"
        [[ "$trend" == "falling" ]] && trend_icon="↘"

        printf "${BR_PURPLE}│${RST}\n"
        printf "${BR_PURPLE}│${RST} ${TEXT_MUTED}CPU: min=%d%% max=%d%% avg=%d%% trend=%s${RST}\n" "$min" "$max" "$avg" "$trend_icon"
    fi

    printf "${BR_PURPLE}└────────────────────────────────────────────────────────────┘${RST}\n"
}

# Network status panel
panel_network_status() {
    local devices=(
        "Lucidia Prime:192.168.4.38"
        "BlackRoad Pi:192.168.4.64"
        "Lucidia Alt:192.168.4.99"
        "iPhone Koder:192.168.4.68"
        "Codex VPS:159.65.43.12"
    )

    printf "${BR_GREEN}${BOLD}┌─ NETWORK STATUS ───────────────────────────────────────────┐${RST}\n"

    for device in "${devices[@]}"; do
        local name=$(echo "$device" | cut -d: -f1)
        local host=$(echo "$device" | cut -d: -f2)

        if ping -c 1 -W 1 "$host" &>/dev/null; then
            printf "${BR_GREEN}│${RST} ${BR_GREEN}◉${RST} %-18s ${TEXT_MUTED}%s${RST}\n" "$name" "$host"
        else
            printf "${BR_GREEN}│${RST} ${BR_RED}○${RST} %-18s ${TEXT_MUTED}%s${RST}\n" "$name" "$host"
        fi
    done

    printf "${BR_GREEN}└────────────────────────────────────────────────────────────┘${RST}\n"
}

# API health panel
panel_api_health() {
    printf "${BR_ORANGE}${BOLD}┌─ API HEALTH ───────────────────────────────────────────────┐${RST}\n"

    local apis=(
        "GitHub:https://api.github.com"
        "Cloudflare:https://api.cloudflare.com"
        "CoinGecko:https://api.coingecko.com"
        "Railway:https://backboard.railway.app"
    )

    for api in "${apis[@]}"; do
        local name=$(echo "$api" | cut -d: -f1)
        local url=$(echo "$api" | cut -d: -f2-)

        local status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$url" 2>/dev/null)

        if [[ "$status_code" == "200" ]] || [[ "$status_code" == "301" ]] || [[ "$status_code" == "302" ]]; then
            printf "${BR_ORANGE}│${RST} ${BR_GREEN}✓${RST} %-12s ${TEXT_MUTED}%s${RST}\n" "$name" "$status_code"
        else
            printf "${BR_ORANGE}│${RST} ${BR_RED}✗${RST} %-12s ${TEXT_MUTED}%s${RST}\n" "$name" "${status_code:-timeout}"
        fi
    done

    printf "${BR_ORANGE}└────────────────────────────────────────────────────────────┘${RST}\n"
}

# Crypto dashboard panel
panel_crypto() {
    printf "${BR_YELLOW}${BOLD}┌─ CRYPTO PORTFOLIO ─────────────────────────────────────────┐${RST}\n"

    # Fetch prices
    local btc_data=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true" 2>/dev/null)
    local eth_data=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd&include_24hr_change=true" 2>/dev/null)
    local sol_data=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=solana&vs_currencies=usd&include_24hr_change=true" 2>/dev/null)

    if command -v jq &>/dev/null; then
        local btc_price=$(echo "$btc_data" | jq -r '.bitcoin.usd // 0')
        local btc_change=$(echo "$btc_data" | jq -r '.bitcoin.usd_24h_change // 0' | cut -c1-5)
        local eth_price=$(echo "$eth_data" | jq -r '.ethereum.usd // 0')
        local eth_change=$(echo "$eth_data" | jq -r '.ethereum.usd_24h_change // 0' | cut -c1-5)
        local sol_price=$(echo "$sol_data" | jq -r '.solana.usd // 0')
        local sol_change=$(echo "$sol_data" | jq -r '.solana.usd_24h_change // 0' | cut -c1-5)

        local btc_color="$BR_GREEN"
        local eth_color="$BR_GREEN"
        local sol_color="$BR_GREEN"

        [[ "${btc_change:0:1}" == "-" ]] && btc_color="$BR_RED"
        [[ "${eth_change:0:1}" == "-" ]] && eth_color="$BR_RED"
        [[ "${sol_change:0:1}" == "-" ]] && sol_color="$BR_RED"

        printf "${BR_YELLOW}│${RST} ${BR_ORANGE}₿${RST} Bitcoin    ${TEXT_PRIMARY}\$%-10s${RST} ${btc_color}%s%%${RST}\n" "$btc_price" "$btc_change"
        printf "${BR_YELLOW}│${RST} ${BR_PURPLE}Ξ${RST} Ethereum   ${TEXT_PRIMARY}\$%-10s${RST} ${eth_color}%s%%${RST}\n" "$eth_price" "$eth_change"
        printf "${BR_YELLOW}│${RST} ${BR_CYAN}◎${RST} Solana     ${TEXT_PRIMARY}\$%-10s${RST} ${sol_color}%s%%${RST}\n" "$sol_price" "$sol_change"
    else
        printf "${BR_YELLOW}│${RST} ${TEXT_MUTED}Install jq for price display${RST}\n"
    fi

    printf "${BR_YELLOW}└────────────────────────────────────────────────────────────┘${RST}\n"
}

# Insights panel
panel_insights() {
    printf "${BR_PINK}${BOLD}┌─ AI INSIGHTS ──────────────────────────────────────────────┐${RST}\n"

    # Generate insights based on metrics
    local cpu=$(get_cpu_usage 2>/dev/null || echo "0")
    local mem=$(get_memory_usage 2>/dev/null || echo "0")

    if ((cpu > 80)); then
        printf "${BR_PINK}│${RST} ${BR_RED}⚠${RST} High CPU usage detected (%d%%) - consider scaling\n" "$cpu"
    elif ((cpu < 10)); then
        printf "${BR_PINK}│${RST} ${BR_GREEN}✓${RST} CPU resources underutilized - room for more workloads\n"
    else
        printf "${BR_PINK}│${RST} ${BR_CYAN}ℹ${RST} CPU usage normal (%d%%)\n" "$cpu"
    fi

    if ((mem > 85)); then
        printf "${BR_PINK}│${RST} ${BR_RED}⚠${RST} Memory pressure high (%d%%) - optimize or upgrade\n" "$mem"
    else
        printf "${BR_PINK}│${RST} ${BR_CYAN}ℹ${RST} Memory usage healthy (%d%%)\n" "$mem"
    fi

    # Check trends
    if [[ ${#CPU_HISTORY[@]} -ge 5 ]]; then
        local cpu_trend=$(detect_trend "${CPU_HISTORY[@]}")
        case "$cpu_trend" in
            rising)
                printf "${BR_PINK}│${RST} ${BR_YELLOW}↗${RST} CPU usage trending upward\n"
                ;;
            falling)
                printf "${BR_PINK}│${RST} ${BR_GREEN}↘${RST} CPU usage trending downward\n"
                ;;
        esac
    fi

    printf "${BR_PINK}│${RST}\n"
    printf "${BR_PINK}│${RST} ${TEXT_MUTED}Last updated: $(date '+%H:%M:%S')${RST}\n"
    printf "${BR_PINK}└────────────────────────────────────────────────────────────┘${RST}\n"
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

render_dashboard() {
    clear_screen
    get_term_size

    # Header
    printf "${BOLD}"
    printf "${BR_CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${RST}\n"
    printf "${BR_CYAN}║${RST}"
    printf "${BR_ORANGE}        █████╗ ███╗   ██╗ █████╗ ██╗  ██╗   ██╗████████╗██╗ ██████╗███████╗${RST}"
    printf "${BR_CYAN}║${RST}\n"
    printf "${BR_CYAN}║${RST}"
    printf "${BR_PINK}       ██╔══██╗████╗  ██║██╔══██╗██║  ╚██╗ ██╔╝╚══██╔══╝██║██╔════╝██╔════╝${RST}"
    printf "${BR_CYAN}║${RST}\n"
    printf "${BR_CYAN}║${RST}"
    printf "${BR_PURPLE}       ███████║██╔██╗ ██║███████║██║   ╚████╔╝    ██║   ██║██║     ███████╗${RST}"
    printf "${BR_CYAN}║${RST}\n"
    printf "${BR_CYAN}║${RST}"
    printf "${BR_CYAN}       ██╔══██║██║╚██╗██║██╔══██║██║    ╚██╔╝     ██║   ██║██║     ╚════██║${RST}"
    printf "${BR_CYAN}║${RST}\n"
    printf "${BR_CYAN}║${RST}"
    printf "${BR_GREEN}       ██║  ██║██║ ╚████║██║  ██║███████╗██║      ██║   ██║╚██████╗███████║${RST}"
    printf "${BR_CYAN}║${RST}\n"
    printf "${BR_CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${RST}\n"
    printf "\n"

    # Collect current metrics
    collect_metrics

    # Render panels
    panel_system_overview
    printf "\n"
    panel_realtime_metrics
    printf "\n"

    # Two column layout for smaller panels
    panel_network_status &
    local net_pid=$!
    panel_api_health &
    local api_pid=$!
    wait $net_pid $api_pid

    printf "\n"
    panel_crypto
    printf "\n"
    panel_insights

    # Footer
    printf "\n${TEXT_MUTED}─────────────────────────────────────────────────────────────────────────────${RST}\n"
    printf "${TEXT_SECONDARY}[r] Refresh  [e] Export  [t] Theme  [q] Quit${RST}\n"
}

main_loop() {
    cursor_hide
    stty -echo 2>/dev/null

    local last_refresh=0

    while true; do
        local now=$(date +%s)

        # Auto-refresh
        if ((now - last_refresh >= REFRESH_INTERVAL)); then
            render_dashboard
            last_refresh=$now
        fi

        # Check for input
        if read -rsn1 -t 1 key 2>/dev/null; then
            case "$key" in
                r|R) render_dashboard; last_refresh=$(date +%s) ;;
                e|E)
                    source "$SCRIPT_DIR/data-export.sh" 2>/dev/null
                    export_ui
                    ;;
                t|T)
                    source "$SCRIPT_DIR/themes-premium.sh" 2>/dev/null
                    theme_selector
                    ;;
                q|Q) break ;;
            esac
        fi
    done

    cursor_show
    stty echo 2>/dev/null
    printf "\n${TEXT_MUTED}Analytics dashboard closed.${RST}\n"
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-run}" in
        run)      main_loop ;;
        once)     render_dashboard ;;
        metrics)  collect_system_metrics ;;
        *)
            printf "Usage: %s [run|once|metrics]\n" "$0"
            printf "       %s run    # Interactive dashboard\n" "$0"
            printf "       %s once   # Single render\n" "$0"
            ;;
    esac
fi
