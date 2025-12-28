#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#   █████╗ ██╗    ██╗███╗   ██╗███████╗██╗ ██████╗ ██╗  ██╗████████╗███████╗
#  ██╔══██╗██║    ██║████╗  ██║██╔════╝██║██╔════╝ ██║  ██║╚══██╔══╝██╔════╝
#  ███████║██║    ██║██╔██╗ ██║███████╗██║██║  ███╗███████║   ██║   ███████╗
#  ██╔══██║██║    ██║██║╚██╗██║╚════██║██║██║   ██║██╔══██║   ██║   ╚════██║
#  ██║  ██║██║    ██║██║ ╚████║███████║██║╚██████╔╝██║  ██║   ██║   ███████║
#  ╚═╝  ╚═╝╚═╝    ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD AI INSIGHTS ENGINE v3.0
#  Predictive Analytics, Anomaly Detection, Smart Recommendations
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

AI_HOME="${BLACKROAD_DATA:-$HOME/.blackroad-dashboards}/ai"
AI_MODELS="$AI_HOME/models"
AI_TRAINING="$AI_HOME/training"
AI_PREDICTIONS="$AI_HOME/predictions"
mkdir -p "$AI_MODELS" "$AI_TRAINING" "$AI_PREDICTIONS" 2>/dev/null

# Anomaly detection thresholds
ANOMALY_ZSCORE_THRESHOLD=2.5
ANOMALY_PERCENTILE_THRESHOLD=95

# Prediction windows
PREDICTION_WINDOW_SHORT=5    # 5 minute prediction
PREDICTION_WINDOW_MEDIUM=30  # 30 minute prediction
PREDICTION_WINDOW_LONG=60    # 1 hour prediction

# Historical data storage
declare -a METRIC_HISTORY_CPU=()
declare -a METRIC_HISTORY_MEM=()
declare -a METRIC_HISTORY_NET=()
declare -a METRIC_HISTORY_DISK=()
declare -a METRIC_TIMESTAMPS=()

# Anomaly tracking
declare -A ANOMALY_SCORES
declare -A BASELINE_MEANS
declare -A BASELINE_STDDEVS

#───────────────────────────────────────────────────────────────────────────────
# STATISTICAL FUNCTIONS
#───────────────────────────────────────────────────────────────────────────────

# Calculate mean of array
calc_mean() {
    local -a values=("$@")
    local sum=0
    local count=${#values[@]}

    [[ $count -eq 0 ]] && echo "0" && return

    for v in "${values[@]}"; do
        sum=$(echo "$sum + $v" | bc -l 2>/dev/null || echo "$((sum + v))")
    done

    echo "scale=2; $sum / $count" | bc -l 2>/dev/null || echo "$((sum / count))"
}

# Calculate standard deviation
calc_stddev() {
    local -a values=("$@")
    local mean=$(calc_mean "${values[@]}")
    local sum_sq=0
    local count=${#values[@]}

    [[ $count -lt 2 ]] && echo "0" && return

    for v in "${values[@]}"; do
        local diff=$(echo "$v - $mean" | bc -l 2>/dev/null || echo "$((v - mean))")
        sum_sq=$(echo "$sum_sq + ($diff * $diff)" | bc -l 2>/dev/null || echo "$sum_sq")
    done

    echo "scale=2; sqrt($sum_sq / ($count - 1))" | bc -l 2>/dev/null || echo "1"
}

# Calculate Z-score
calc_zscore() {
    local value="$1"
    local mean="$2"
    local stddev="$3"

    [[ "$stddev" == "0" ]] && echo "0" && return

    echo "scale=2; ($value - $mean) / $stddev" | bc -l 2>/dev/null || echo "0"
}

# Calculate percentile
calc_percentile() {
    local -a values=("$@")
    local percentile="${values[-1]}"
    unset 'values[-1]'

    local sorted=($(printf '%s\n' "${values[@]}" | sort -n))
    local count=${#sorted[@]}
    local index=$(echo "scale=0; $count * $percentile / 100" | bc 2>/dev/null || echo "$((count * percentile / 100))")

    [[ $index -ge $count ]] && index=$((count - 1))
    echo "${sorted[$index]}"
}

# Linear regression for trend prediction
linear_regression() {
    local -a values=("$@")
    local n=${#values[@]}

    [[ $n -lt 2 ]] && echo "0 0" && return

    local sum_x=0 sum_y=0 sum_xy=0 sum_xx=0

    for ((i=0; i<n; i++)); do
        sum_x=$((sum_x + i))
        sum_y=$(echo "$sum_y + ${values[$i]}" | bc -l 2>/dev/null || echo "$((sum_y + values[i]))")
        sum_xy=$(echo "$sum_xy + ($i * ${values[$i]})" | bc -l 2>/dev/null)
        sum_xx=$((sum_xx + i * i))
    done

    local slope=$(echo "scale=4; ($n * $sum_xy - $sum_x * $sum_y) / ($n * $sum_xx - $sum_x * $sum_x)" | bc -l 2>/dev/null || echo "0")
    local intercept=$(echo "scale=4; ($sum_y - $slope * $sum_x) / $n" | bc -l 2>/dev/null || echo "0")

    echo "$slope $intercept"
}

# Exponential moving average
calc_ema() {
    local -a values=("$@")
    local alpha="${values[-1]}"
    unset 'values[-1]'

    local ema="${values[0]}"

    for ((i=1; i<${#values[@]}; i++)); do
        ema=$(echo "scale=4; $alpha * ${values[$i]} + (1 - $alpha) * $ema" | bc -l 2>/dev/null)
    done

    echo "$ema"
}

#───────────────────────────────────────────────────────────────────────────────
# ANOMALY DETECTION
#───────────────────────────────────────────────────────────────────────────────

# Detect anomalies using Z-score method
detect_zscore_anomaly() {
    local metric_name="$1"
    local current_value="$2"
    local -a history=("${@:3}")

    local mean=$(calc_mean "${history[@]}")
    local stddev=$(calc_stddev "${history[@]}")
    local zscore=$(calc_zscore "$current_value" "$mean" "$stddev")

    BASELINE_MEANS[$metric_name]="$mean"
    BASELINE_STDDEVS[$metric_name]="$stddev"

    local abs_zscore=$(echo "$zscore" | tr -d '-')

    if (( $(echo "$abs_zscore > $ANOMALY_ZSCORE_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        echo "ANOMALY|$zscore|$mean|$stddev"
        return 1
    fi

    echo "NORMAL|$zscore|$mean|$stddev"
    return 0
}

# Detect anomalies using IQR method
detect_iqr_anomaly() {
    local current_value="$1"
    shift
    local -a history=("$@")

    local q1=$(calc_percentile "${history[@]}" 25)
    local q3=$(calc_percentile "${history[@]}" 75)
    local iqr=$(echo "$q3 - $q1" | bc -l 2>/dev/null || echo "$((q3 - q1))")

    local lower=$(echo "$q1 - 1.5 * $iqr" | bc -l 2>/dev/null)
    local upper=$(echo "$q3 + 1.5 * $iqr" | bc -l 2>/dev/null)

    if (( $(echo "$current_value < $lower || $current_value > $upper" | bc -l 2>/dev/null || echo 0) )); then
        echo "ANOMALY|$lower|$upper"
        return 1
    fi

    echo "NORMAL|$lower|$upper"
    return 0
}

# Combined anomaly detection with confidence score
detect_anomaly() {
    local metric_name="$1"
    local current_value="$2"
    shift 2
    local -a history=("$@")

    [[ ${#history[@]} -lt 10 ]] && echo "INSUFFICIENT_DATA|0" && return 0

    local zscore_result=$(detect_zscore_anomaly "$metric_name" "$current_value" "${history[@]}")
    local iqr_result=$(detect_iqr_anomaly "$current_value" "${history[@]}")

    local zscore_status=$(echo "$zscore_result" | cut -d'|' -f1)
    local iqr_status=$(echo "$iqr_result" | cut -d'|' -f1)

    local confidence=0
    local status="NORMAL"

    if [[ "$zscore_status" == "ANOMALY" ]]; then
        confidence=$((confidence + 50))
        status="ANOMALY"
    fi

    if [[ "$iqr_status" == "ANOMALY" ]]; then
        confidence=$((confidence + 50))
        status="ANOMALY"
    fi

    ANOMALY_SCORES[$metric_name]="$confidence"

    echo "$status|$confidence|$zscore_result"
}

#───────────────────────────────────────────────────────────────────────────────
# PREDICTIVE ANALYTICS
#───────────────────────────────────────────────────────────────────────────────

# Predict future value using linear regression
predict_linear() {
    local -a history=("$@")
    local steps_ahead="${history[-1]}"
    unset 'history[-1]'

    read slope intercept <<< "$(linear_regression "${history[@]}")"

    local n=${#history[@]}
    local prediction=$(echo "scale=2; $slope * ($n + $steps_ahead) + $intercept" | bc -l 2>/dev/null)

    echo "$prediction"
}

# Predict using exponential smoothing
predict_exponential() {
    local -a history=("$@")
    local steps_ahead="${history[-1]}"
    local alpha="${history[-2]}"
    unset 'history[-1]' 'history[-2]'

    local ema=$(calc_ema "${history[@]}" "$alpha")

    # Simple exponential prediction
    echo "$ema"
}

# Predict with confidence interval
predict_with_confidence() {
    local metric_name="$1"
    shift
    local -a history=("$@")
    local steps_ahead="${history[-1]}"
    unset 'history[-1]'

    [[ ${#history[@]} -lt 5 ]] && echo "0|0|0" && return

    local prediction=$(predict_linear "${history[@]}" "$steps_ahead")
    local stddev=$(calc_stddev "${history[@]}")

    local lower=$(echo "scale=2; $prediction - 1.96 * $stddev" | bc -l 2>/dev/null || echo "$prediction")
    local upper=$(echo "scale=2; $prediction + 1.96 * $stddev" | bc -l 2>/dev/null || echo "$prediction")

    echo "$prediction|$lower|$upper"
}

# Trend analysis
analyze_trend() {
    local -a history=("$@")

    [[ ${#history[@]} -lt 3 ]] && echo "UNKNOWN|0" && return

    read slope intercept <<< "$(linear_regression "${history[@]}")"

    local trend="STABLE"
    local strength=0

    if (( $(echo "$slope > 0.5" | bc -l 2>/dev/null || echo 0) )); then
        trend="RISING"
        strength=$(echo "scale=0; $slope * 10" | bc 2>/dev/null || echo "5")
    elif (( $(echo "$slope < -0.5" | bc -l 2>/dev/null || echo 0) )); then
        trend="FALLING"
        strength=$(echo "scale=0; $slope * -10" | bc 2>/dev/null || echo "5")
    fi

    echo "$trend|$strength"
}

#───────────────────────────────────────────────────────────────────────────────
# PATTERN RECOGNITION
#───────────────────────────────────────────────────────────────────────────────

# Detect cyclic patterns (daily, hourly)
detect_cycles() {
    local -a history=("$@")
    local len=${#history[@]}

    [[ $len -lt 24 ]] && echo "INSUFFICIENT_DATA" && return

    # Check for hourly pattern (correlation with 1-hour lag)
    local hourly_corr=0
    if [[ $len -ge 60 ]]; then
        # Simple autocorrelation check
        local matches=0
        for ((i=60; i<len; i++)); do
            local diff=$((${history[$i]} - ${history[$((i-60))]}))
            [[ ${diff#-} -lt 10 ]] && ((matches++))
        done
        hourly_corr=$((matches * 100 / (len - 60)))
    fi

    # Check for daily pattern
    local daily_corr=0
    if [[ $len -ge 1440 ]]; then
        local matches=0
        for ((i=1440; i<len; i++)); do
            local diff=$((${history[$i]} - ${history[$((i-1440))]}))
            [[ ${diff#-} -lt 10 ]] && ((matches++))
        done
        daily_corr=$((matches * 100 / (len - 1440)))
    fi

    echo "HOURLY:$hourly_corr|DAILY:$daily_corr"
}

# Detect spikes
detect_spikes() {
    local -a history=("$@")
    local threshold="${history[-1]}"
    unset 'history[-1]'

    local -a spikes=()
    local mean=$(calc_mean "${history[@]}")

    for ((i=0; i<${#history[@]}; i++)); do
        local ratio=$(echo "scale=2; ${history[$i]} / $mean" | bc -l 2>/dev/null || echo "1")
        if (( $(echo "$ratio > $threshold" | bc -l 2>/dev/null || echo 0) )); then
            spikes+=("$i:${history[$i]}")
        fi
    done

    echo "${spikes[*]}"
}

#───────────────────────────────────────────────────────────────────────────────
# SMART RECOMMENDATIONS
#───────────────────────────────────────────────────────────────────────────────

# Generate recommendations based on metrics
generate_recommendations() {
    local -a recommendations=()

    # CPU recommendations
    local cpu_mean="${BASELINE_MEANS[cpu]:-50}"
    local cpu_trend=$(analyze_trend "${METRIC_HISTORY_CPU[@]}")

    if (( $(echo "$cpu_mean > 80" | bc -l 2>/dev/null || echo 0) )); then
        recommendations+=("CRITICAL|CPU consistently high ($cpu_mean%). Consider scaling or optimizing processes.")
    elif [[ "$cpu_trend" == RISING* ]]; then
        recommendations+=("WARNING|CPU usage trending upward. Monitor for potential capacity issues.")
    fi

    # Memory recommendations
    local mem_mean="${BASELINE_MEANS[memory]:-50}"

    if (( $(echo "$mem_mean > 85" | bc -l 2>/dev/null || echo 0) )); then
        recommendations+=("CRITICAL|Memory usage critical ($mem_mean%). Risk of OOM. Add more RAM or optimize.")
    elif (( $(echo "$mem_mean > 70" | bc -l 2>/dev/null || echo 0) )); then
        recommendations+=("WARNING|Memory usage elevated ($mem_mean%). Consider memory optimization.")
    fi

    # Disk recommendations
    local disk_usage=$(get_disk_usage "/" 2>/dev/null || echo "50")

    if [[ $disk_usage -gt 90 ]]; then
        recommendations+=("CRITICAL|Disk space critically low ($disk_usage%). Immediate cleanup required.")
    elif [[ $disk_usage -gt 80 ]]; then
        recommendations+=("WARNING|Disk space getting low ($disk_usage%). Plan for cleanup or expansion.")
    fi

    # Anomaly-based recommendations
    for metric in "${!ANOMALY_SCORES[@]}"; do
        local score="${ANOMALY_SCORES[$metric]}"
        if [[ $score -gt 75 ]]; then
            recommendations+=("ALERT|Anomaly detected in $metric (confidence: $score%). Investigate unusual behavior.")
        fi
    done

    printf '%s\n' "${recommendations[@]}"
}

# Prioritized action items
generate_action_items() {
    local -a actions=()

    local cpu=$(get_cpu_usage 2>/dev/null || echo "0")
    local mem=$(get_memory_usage 2>/dev/null || echo "0")
    local disk=$(get_disk_usage "/" 2>/dev/null || echo "0")

    # Priority 1: Critical issues
    [[ $mem -gt 95 ]] && actions+=("P1|IMMEDIATE|Kill non-essential processes to free memory")
    [[ $disk -gt 95 ]] && actions+=("P1|IMMEDIATE|Clear disk space - system at risk")

    # Priority 2: High issues
    [[ $cpu -gt 90 ]] && actions+=("P2|URGENT|Investigate high CPU processes")
    [[ $mem -gt 85 ]] && actions+=("P2|URGENT|Review memory-hungry applications")
    [[ $disk -gt 85 ]] && actions+=("P2|URGENT|Plan disk cleanup or expansion")

    # Priority 3: Medium issues
    [[ $cpu -gt 70 ]] && actions+=("P3|MONITOR|CPU elevated - watch for increases")
    [[ $mem -gt 70 ]] && actions+=("P3|MONITOR|Memory usage above optimal")

    # Priority 4: Optimization suggestions
    [[ $cpu -lt 20 && $mem -lt 30 ]] && actions+=("P4|OPTIMIZE|Resources underutilized - consider downsizing")

    printf '%s\n' "${actions[@]}"
}

#───────────────────────────────────────────────────────────────────────────────
# DATA COLLECTION
#───────────────────────────────────────────────────────────────────────────────

# Collect current metrics
collect_metrics() {
    local cpu=$(get_cpu_usage 2>/dev/null || echo "0")
    local mem=$(get_memory_usage 2>/dev/null || echo "0")
    local disk=$(get_disk_usage "/" 2>/dev/null || echo "0")
    local timestamp=$(date +%s)

    METRIC_HISTORY_CPU+=("$cpu")
    METRIC_HISTORY_MEM+=("$mem")
    METRIC_HISTORY_DISK+=("$disk")
    METRIC_TIMESTAMPS+=("$timestamp")

    # Trim to last 1000 entries
    local max=1000
    [[ ${#METRIC_HISTORY_CPU[@]} -gt $max ]] && METRIC_HISTORY_CPU=("${METRIC_HISTORY_CPU[@]:(-$max)}")
    [[ ${#METRIC_HISTORY_MEM[@]} -gt $max ]] && METRIC_HISTORY_MEM=("${METRIC_HISTORY_MEM[@]:(-$max)}")
    [[ ${#METRIC_HISTORY_DISK[@]} -gt $max ]] && METRIC_HISTORY_DISK=("${METRIC_HISTORY_DISK[@]:(-$max)}")
    [[ ${#METRIC_TIMESTAMPS[@]} -gt $max ]] && METRIC_TIMESTAMPS=("${METRIC_TIMESTAMPS[@]:(-$max)}")

    echo "$timestamp|$cpu|$mem|$disk"
}

# Load historical data
load_history() {
    local history_file="$AI_TRAINING/metrics_history.dat"

    [[ ! -f "$history_file" ]] && return

    while IFS='|' read -r ts cpu mem disk; do
        METRIC_HISTORY_CPU+=("$cpu")
        METRIC_HISTORY_MEM+=("$mem")
        METRIC_HISTORY_DISK+=("$disk")
        METRIC_TIMESTAMPS+=("$ts")
    done < "$history_file"
}

# Save history
save_history() {
    local history_file="$AI_TRAINING/metrics_history.dat"
    local max=10000

    {
        for ((i=0; i<${#METRIC_TIMESTAMPS[@]} && i<max; i++)); do
            echo "${METRIC_TIMESTAMPS[$i]}|${METRIC_HISTORY_CPU[$i]}|${METRIC_HISTORY_MEM[$i]}|${METRIC_HISTORY_DISK[$i]}"
        done
    } > "$history_file"
}

#───────────────────────────────────────────────────────────────────────────────
# AI INSIGHTS DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

render_ai_dashboard() {
    clear_screen
    cursor_hide

    # Animated header
    local colors=("$BR_CYAN" "$BR_PURPLE" "$BR_PINK" "$BR_ORANGE")
    local frame=$(($(date +%s) % 4))

    printf "${colors[$frame]}${BOLD}"
    cat << 'HEADER'
╔══════════════════════════════════════════════════════════════════════════════╗
║   ▄▄▄       ██▓    ██▓ ███▄    █   ██████  ██▓  ▄████  ██░ ██ ▄▄▄█████▓      ║
║  ▒████▄    ▓██▒   ▓██▒ ██ ▀█   █ ▒██    ▒ ▓██▒ ██▒ ▀█▒▓██░ ██▒▓  ██▒ ▓▒      ║
║  ▒██  ▀█▄  ▒██▒   ▒██▒▓██  ▀█ ██▒░ ▓██▄   ▒██▒▒██░▄▄▄░▒██▀▀██░▒ ▓██░ ▒░      ║
║  ░██▄▄▄▄██ ░██░   ░██░▓██▒  ▐▌██▒  ▒   ██▒░██░░▓█  ██▓░▓█ ░██ ░ ▓██▓ ░       ║
║   ▓█   ▓██▒░██░   ░██░▒██░   ▓██░▒██████▒▒░██░░▒▓███▀▒░▓█▒░██▓  ▒██▒ ░       ║
║   ▒▒   ▓▒█░░▓     ░▓  ░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░░▓   ░▒   ▒  ▒ ░░▒░▒  ▒ ░░         ║
╚══════════════════════════════════════════════════════════════════════════════╝
HEADER
    printf "${RST}\n"

    # Collect fresh data
    collect_metrics > /dev/null

    # Current metrics with predictions
    local cpu=$(get_cpu_usage 2>/dev/null || echo "0")
    local mem=$(get_memory_usage 2>/dev/null || echo "0")
    local disk=$(get_disk_usage "/" 2>/dev/null || echo "0")

    printf "${BR_CYAN}┌─ REAL-TIME METRICS ──────────────────────────────────────────────────────┐${RST}\n"
    printf "${BR_CYAN}│${RST}\n"

    # CPU with prediction
    local cpu_pred=$(predict_with_confidence "cpu" "${METRIC_HISTORY_CPU[@]}" 5)
    local cpu_trend=$(analyze_trend "${METRIC_HISTORY_CPU[@]}")
    IFS='|' read -r cpu_forecast cpu_low cpu_high <<< "$cpu_pred"
    IFS='|' read -r cpu_direction cpu_strength <<< "$cpu_trend"

    local cpu_color="$BR_GREEN"
    [[ $cpu -gt 70 ]] && cpu_color="$BR_YELLOW"
    [[ $cpu -gt 85 ]] && cpu_color="$BR_RED"

    printf "${BR_CYAN}│${RST}  ${BOLD}CPU${RST}     Current: ${cpu_color}%3d%%${RST}  │  Forecast: ${TEXT_SECONDARY}%s%%${RST}  │  Trend: "
    case "$cpu_direction" in
        RISING)  printf "${BR_RED}↗ Rising${RST}" ;;
        FALLING) printf "${BR_GREEN}↘ Falling${RST}" ;;
        *)       printf "${TEXT_MUTED}→ Stable${RST}" ;;
    esac
    printf "\n" "$cpu" "$cpu_forecast"

    # Memory with prediction
    local mem_pred=$(predict_with_confidence "memory" "${METRIC_HISTORY_MEM[@]}" 5)
    local mem_trend=$(analyze_trend "${METRIC_HISTORY_MEM[@]}")
    IFS='|' read -r mem_forecast mem_low mem_high <<< "$mem_pred"
    IFS='|' read -r mem_direction mem_strength <<< "$mem_trend"

    local mem_color="$BR_GREEN"
    [[ $mem -gt 70 ]] && mem_color="$BR_YELLOW"
    [[ $mem -gt 85 ]] && mem_color="$BR_RED"

    printf "${BR_CYAN}│${RST}  ${BOLD}Memory${RST}  Current: ${mem_color}%3d%%${RST}  │  Forecast: ${TEXT_SECONDARY}%s%%${RST}  │  Trend: "
    case "$mem_direction" in
        RISING)  printf "${BR_RED}↗ Rising${RST}" ;;
        FALLING) printf "${BR_GREEN}↘ Falling${RST}" ;;
        *)       printf "${TEXT_MUTED}→ Stable${RST}" ;;
    esac
    printf "\n" "$mem" "$mem_forecast"

    # Disk
    local disk_color="$BR_GREEN"
    [[ $disk -gt 80 ]] && disk_color="$BR_YELLOW"
    [[ $disk -gt 90 ]] && disk_color="$BR_RED"

    printf "${BR_CYAN}│${RST}  ${BOLD}Disk${RST}    Current: ${disk_color}%3d%%${RST}  │\n" "$disk"
    printf "${BR_CYAN}│${RST}\n"
    printf "${BR_CYAN}└───────────────────────────────────────────────────────────────────────────┘${RST}\n\n"

    # Anomaly Detection Panel
    printf "${BR_PURPLE}┌─ ANOMALY DETECTION ──────────────────────────────────────────────────────┐${RST}\n"

    if [[ ${#METRIC_HISTORY_CPU[@]} -ge 10 ]]; then
        local cpu_anomaly=$(detect_anomaly "cpu" "$cpu" "${METRIC_HISTORY_CPU[@]}")
        local mem_anomaly=$(detect_anomaly "memory" "$mem" "${METRIC_HISTORY_MEM[@]}")

        IFS='|' read -r cpu_status cpu_conf _ <<< "$cpu_anomaly"
        IFS='|' read -r mem_status mem_conf _ <<< "$mem_anomaly"

        if [[ "$cpu_status" == "ANOMALY" ]]; then
            printf "${BR_PURPLE}│${RST}  ${BR_RED}⚠ CPU ANOMALY${RST} detected (confidence: %s%%)  ${BR_RED}█${RST}\n" "$cpu_conf"
        else
            printf "${BR_PURPLE}│${RST}  ${BR_GREEN}✓ CPU Normal${RST} (within expected range)\n"
        fi

        if [[ "$mem_status" == "ANOMALY" ]]; then
            printf "${BR_PURPLE}│${RST}  ${BR_RED}⚠ MEMORY ANOMALY${RST} detected (confidence: %s%%)  ${BR_RED}█${RST}\n" "$mem_conf"
        else
            printf "${BR_PURPLE}│${RST}  ${BR_GREEN}✓ Memory Normal${RST} (within expected range)\n"
        fi
    else
        printf "${BR_PURPLE}│${RST}  ${TEXT_MUTED}Collecting baseline data... (%d/10 samples)${RST}\n" "${#METRIC_HISTORY_CPU[@]}"
    fi

    printf "${BR_PURPLE}└───────────────────────────────────────────────────────────────────────────┘${RST}\n\n"

    # AI Recommendations
    printf "${BR_ORANGE}┌─ AI RECOMMENDATIONS ─────────────────────────────────────────────────────┐${RST}\n"

    local -a recs
    mapfile -t recs < <(generate_recommendations)

    if [[ ${#recs[@]} -eq 0 ]]; then
        printf "${BR_ORANGE}│${RST}  ${BR_GREEN}✓${RST} All systems operating within normal parameters\n"
    else
        for rec in "${recs[@]}"; do
            IFS='|' read -r severity message <<< "$rec"
            case "$severity" in
                CRITICAL) printf "${BR_ORANGE}│${RST}  ${BR_RED}🚨 %s${RST}\n" "$message" ;;
                WARNING)  printf "${BR_ORANGE}│${RST}  ${BR_YELLOW}⚠️  %s${RST}\n" "$message" ;;
                ALERT)    printf "${BR_ORANGE}│${RST}  ${BR_PURPLE}🔔 %s${RST}\n" "$message" ;;
                *)        printf "${BR_ORANGE}│${RST}  ${BR_CYAN}ℹ️  %s${RST}\n" "$message" ;;
            esac
        done
    fi

    printf "${BR_ORANGE}└───────────────────────────────────────────────────────────────────────────┘${RST}\n\n"

    # Action Items
    printf "${BR_PINK}┌─ PRIORITY ACTIONS ───────────────────────────────────────────────────────┐${RST}\n"

    local -a actions
    mapfile -t actions < <(generate_action_items)

    if [[ ${#actions[@]} -eq 0 ]]; then
        printf "${BR_PINK}│${RST}  ${BR_GREEN}No immediate actions required${RST}\n"
    else
        for action in "${actions[@]:0:5}"; do  # Show top 5
            IFS='|' read -r priority urgency message <<< "$action"
            case "$priority" in
                P1) printf "${BR_PINK}│${RST}  ${BR_RED}[P1] ${BOLD}%s${RST}: %s\n" "$urgency" "$message" ;;
                P2) printf "${BR_PINK}│${RST}  ${BR_ORANGE}[P2] %s${RST}: %s\n" "$urgency" "$message" ;;
                P3) printf "${BR_PINK}│${RST}  ${BR_YELLOW}[P3] %s${RST}: %s\n" "$urgency" "$message" ;;
                *)  printf "${BR_PINK}│${RST}  ${BR_CYAN}[P4] %s${RST}: %s\n" "$urgency" "$message" ;;
            esac
        done
    fi

    printf "${BR_PINK}└───────────────────────────────────────────────────────────────────────────┘${RST}\n\n"

    printf "${TEXT_MUTED}Data points: %d │ Last updated: %s │ [r]efresh [s]ave [q]uit${RST}\n" \
        "${#METRIC_HISTORY_CPU[@]}" "$(date '+%H:%M:%S')"
}

# Main loop
ai_dashboard_loop() {
    load_history

    while true; do
        render_ai_dashboard

        if read -rsn1 -t 3 key 2>/dev/null; then
            case "$key" in
                r|R) continue ;;
                s|S) save_history; printf "\n${BR_GREEN}History saved.${RST}"; sleep 1 ;;
                q|Q) save_history; break ;;
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
        dashboard) ai_dashboard_loop ;;
        predict)   predict_with_confidence "$2" "${@:3}" ;;
        anomaly)   detect_anomaly "$2" "$3" "${@:4}" ;;
        trend)     analyze_trend "${@:2}" ;;
        *)
            printf "Usage: %s [dashboard|predict|anomaly|trend]\n" "$0"
            ;;
    esac
fi
