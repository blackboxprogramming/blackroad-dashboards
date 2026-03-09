#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#   ██████╗██████╗ ██╗   ██╗██████╗ ████████╗ ██████╗     ████████╗██████╗  █████╗ ██████╗ ███████╗
#  ██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗╚══██╔══╝██╔═══██╗    ╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██╔════╝
#  ██║     ██████╔╝ ╚████╔╝ ██████╔╝   ██║   ██║   ██║       ██║   ██████╔╝███████║██║  ██║█████╗
#  ██║     ██╔══██╗  ╚██╔╝  ██╔═══╝    ██║   ██║   ██║       ██║   ██╔══██╗██╔══██║██║  ██║██╔══╝
#  ╚██████╗██║  ██║   ██║   ██║        ██║   ╚██████╔╝       ██║   ██║  ██║██║  ██║██████╔╝███████╗
#   ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝        ╚═╝    ╚═════╝        ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD CRYPTO TRADING DASHBOARD v3.0
#  Real-time Cryptocurrency Prices, Charts & Portfolio Tracking
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

CRYPTO_CACHE_DIR="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}/cache/crypto"
PORTFOLIO_FILE="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}/portfolio.json"
ALERTS_FILE="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}/crypto_alerts.json"

mkdir -p "$CRYPTO_CACHE_DIR" 2>/dev/null

# CoinGecko API (free, no key required)
COINGECKO_API="https://api.coingecko.com/api/v3"

# Default watchlist
DEFAULT_COINS=("bitcoin" "ethereum" "solana" "cardano" "polkadot" "avalanche-2" "chainlink" "polygon")

# Currency
CURRENCY="${CRYPTO_CURRENCY:-usd}"

#───────────────────────────────────────────────────────────────────────────────
# API FUNCTIONS
#───────────────────────────────────────────────────────────────────────────────

fetch_price() {
    local coin="$1"
    local cache_file="$CRYPTO_CACHE_DIR/${coin}_price.json"
    local cache_age=60  # 1 minute cache

    # Check cache
    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        if [[ $file_age -lt $cache_age ]]; then
            cat "$cache_file"
            return
        fi
    fi

    # Fetch from API
    local result=$(curl -s --connect-timeout 5 "$COINGECKO_API/simple/price?ids=$coin&vs_currencies=$CURRENCY&include_24hr_change=true&include_24hr_vol=true&include_market_cap=true" 2>/dev/null)

    [[ -n "$result" ]] && echo "$result" > "$cache_file"
    echo "$result"
}

fetch_coin_details() {
    local coin="$1"
    local cache_file="$CRYPTO_CACHE_DIR/${coin}_details.json"
    local cache_age=300  # 5 minute cache

    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        if [[ $file_age -lt $cache_age ]]; then
            cat "$cache_file"
            return
        fi
    fi

    local result=$(curl -s --connect-timeout 5 "$COINGECKO_API/coins/$coin?localization=false&tickers=false&community_data=false&developer_data=false" 2>/dev/null)

    [[ -n "$result" ]] && echo "$result" > "$cache_file"
    echo "$result"
}

fetch_market_chart() {
    local coin="$1"
    local days="${2:-1}"
    local cache_file="$CRYPTO_CACHE_DIR/${coin}_chart_${days}d.json"
    local cache_age=300

    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        if [[ $file_age -lt $cache_age ]]; then
            cat "$cache_file"
            return
        fi
    fi

    local result=$(curl -s --connect-timeout 5 "$COINGECKO_API/coins/$coin/market_chart?vs_currency=$CURRENCY&days=$days" 2>/dev/null)

    [[ -n "$result" ]] && echo "$result" > "$cache_file"
    echo "$result"
}

fetch_top_coins() {
    local count="${1:-20}"
    local cache_file="$CRYPTO_CACHE_DIR/top_coins.json"
    local cache_age=120

    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        if [[ $file_age -lt $cache_age ]]; then
            cat "$cache_file"
            return
        fi
    fi

    local result=$(curl -s --connect-timeout 5 "$COINGECKO_API/coins/markets?vs_currency=$CURRENCY&order=market_cap_desc&per_page=$count&page=1&sparkline=true" 2>/dev/null)

    [[ -n "$result" ]] && echo "$result" > "$cache_file"
    echo "$result"
}

fetch_global_data() {
    local cache_file="$CRYPTO_CACHE_DIR/global.json"
    local cache_age=120

    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        if [[ $file_age -lt $cache_age ]]; then
            cat "$cache_file"
            return
        fi
    fi

    local result=$(curl -s --connect-timeout 5 "$COINGECKO_API/global" 2>/dev/null)

    [[ -n "$result" ]] && echo "$result" > "$cache_file"
    echo "$result"
}

#───────────────────────────────────────────────────────────────────────────────
# DATA PARSING
#───────────────────────────────────────────────────────────────────────────────

parse_price() {
    local json="$1"
    local coin="$2"

    if command -v jq &>/dev/null; then
        local price=$(echo "$json" | jq -r ".$coin.$CURRENCY // 0" 2>/dev/null)
        local change=$(echo "$json" | jq -r ".$coin.${CURRENCY}_24h_change // 0" 2>/dev/null)
        local volume=$(echo "$json" | jq -r ".$coin.${CURRENCY}_24h_vol // 0" 2>/dev/null)
        local mcap=$(echo "$json" | jq -r ".$coin.${CURRENCY}_market_cap // 0" 2>/dev/null)
        echo "$price|$change|$volume|$mcap"
    else
        echo "0|0|0|0"
    fi
}

format_price() {
    local price="$1"

    if command -v bc &>/dev/null; then
        if (( $(echo "$price >= 1" | bc -l) )); then
            printf "%.2f" "$price"
        elif (( $(echo "$price >= 0.01" | bc -l) )); then
            printf "%.4f" "$price"
        else
            printf "%.8f" "$price"
        fi
    else
        printf "%.2f" "$price"
    fi
}

format_large_number() {
    local num="$1"

    if command -v bc &>/dev/null && [[ -n "$num" ]] && [[ "$num" != "null" ]]; then
        if (( $(echo "$num >= 1000000000000" | bc -l 2>/dev/null || echo 0) )); then
            printf "%.2fT" "$(echo "$num / 1000000000000" | bc -l)"
        elif (( $(echo "$num >= 1000000000" | bc -l 2>/dev/null || echo 0) )); then
            printf "%.2fB" "$(echo "$num / 1000000000" | bc -l)"
        elif (( $(echo "$num >= 1000000" | bc -l 2>/dev/null || echo 0) )); then
            printf "%.2fM" "$(echo "$num / 1000000" | bc -l)"
        elif (( $(echo "$num >= 1000" | bc -l 2>/dev/null || echo 0) )); then
            printf "%.2fK" "$(echo "$num / 1000" | bc -l)"
        else
            printf "%.2f" "$num"
        fi
    else
        echo "N/A"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# SPARKLINE CHART
#───────────────────────────────────────────────────────────────────────────────

render_sparkline() {
    local -a data=("$@")
    local width="${SPARKLINE_WIDTH:-40}"
    local height="${SPARKLINE_HEIGHT:-8}"

    [[ ${#data[@]} -eq 0 ]] && return

    # Find min/max
    local min="${data[0]}"
    local max="${data[0]}"
    for val in "${data[@]}"; do
        (( $(echo "$val < $min" | bc -l 2>/dev/null || echo 0) )) && min="$val"
        (( $(echo "$val > $max" | bc -l 2>/dev/null || echo 0) )) && max="$val"
    done

    local range=$(echo "$max - $min" | bc -l 2>/dev/null || echo 1)
    [[ "$range" == "0" ]] && range=1

    # Sample data points
    local step=$((${#data[@]} / width))
    [[ $step -lt 1 ]] && step=1

    # Build chart
    local -a chart=()
    for ((row=height-1; row>=0; row--)); do
        local line=""
        for ((col=0; col<width; col++)); do
            local idx=$((col * step))
            [[ $idx -ge ${#data[@]} ]] && idx=$((${#data[@]} - 1))

            local val="${data[$idx]}"
            local normalized=$(echo "($val - $min) * $height / $range" | bc -l 2>/dev/null || echo 0)
            normalized=${normalized%.*}
            [[ -z "$normalized" ]] && normalized=0

            if [[ $normalized -ge $row ]]; then
                line+="█"
            else
                line+=" "
            fi
        done
        chart+=("$line")
    done

    # Determine color based on trend
    local first="${data[0]}"
    local last="${data[-1]}"
    local color="$BR_GREEN"
    (( $(echo "$last < $first" | bc -l 2>/dev/null || echo 0) )) && color="$BR_RED"

    # Print chart
    for line in "${chart[@]}"; do
        printf "  ${color}%s${RST}\n" "$line"
    done
}

render_mini_sparkline() {
    local data_str="$1"
    local width="${2:-15}"

    # Sparkline characters: ▁▂▃▄▅▆▇█
    local chars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

    if command -v jq &>/dev/null; then
        local -a values=($(echo "$data_str" | jq -r '.[]' 2>/dev/null | tail -n "$width"))

        [[ ${#values[@]} -eq 0 ]] && return

        local min="${values[0]}"
        local max="${values[0]}"
        for val in "${values[@]}"; do
            (( $(echo "$val < $min" | bc -l 2>/dev/null || echo 0) )) && min="$val"
            (( $(echo "$val > $max" | bc -l 2>/dev/null || echo 0) )) && max="$val"
        done

        local range=$(echo "$max - $min" | bc -l 2>/dev/null || echo 1)
        [[ "$range" == "0" ]] && range=1

        local first="${values[0]}"
        local last="${values[-1]}"
        local color="$BR_GREEN"
        (( $(echo "$last < $first" | bc -l 2>/dev/null || echo 0) )) && color="$BR_RED"

        printf "%s" "$color"
        for val in "${values[@]}"; do
            local idx=$(echo "($val - $min) * 7 / $range" | bc 2>/dev/null || echo 0)
            [[ $idx -gt 7 ]] && idx=7
            [[ $idx -lt 0 ]] && idx=0
            printf "%s" "${chars[$idx]}"
        done
        printf "${RST}"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# CANDLESTICK CHART (ASCII)
#───────────────────────────────────────────────────────────────────────────────

render_candlestick() {
    local coin="$1"
    local days="${2:-7}"
    local width=60
    local height=15

    local chart_data=$(fetch_market_chart "$coin" "$days")

    if ! command -v jq &>/dev/null; then
        printf "${TEXT_MUTED}jq required for chart rendering${RST}\n"
        return
    fi

    local -a prices=($(echo "$chart_data" | jq -r '.prices[][1]' 2>/dev/null))

    [[ ${#prices[@]} -eq 0 ]] && return

    local min="${prices[0]}"
    local max="${prices[0]}"
    for val in "${prices[@]}"; do
        (( $(echo "$val < $min" | bc -l 2>/dev/null || echo 0) )) && min="$val"
        (( $(echo "$val > $max" | bc -l 2>/dev/null || echo 0) )) && max="$val"
    done

    printf "\n${BOLD}%s Price Chart (%d days)${RST}\n\n" "${coin^}" "$days"
    printf "  ${TEXT_MUTED}Max: \$%s${RST}\n" "$(format_price "$max")"

    render_sparkline "${prices[@]}"

    printf "  ${TEXT_MUTED}Min: \$%s${RST}\n" "$(format_price "$min")"
}

#───────────────────────────────────────────────────────────────────────────────
# PORTFOLIO MANAGEMENT
#───────────────────────────────────────────────────────────────────────────────

init_portfolio() {
    if [[ ! -f "$PORTFOLIO_FILE" ]]; then
        echo '{"holdings":[]}' > "$PORTFOLIO_FILE"
    fi
}

add_holding() {
    local coin="$1"
    local amount="$2"
    local buy_price="$3"

    init_portfolio

    if command -v jq &>/dev/null; then
        local holding="{\"coin\":\"$coin\",\"amount\":$amount,\"buy_price\":$buy_price,\"date\":\"$(date -Iseconds)\"}"
        local updated=$(jq ".holdings += [$holding]" "$PORTFOLIO_FILE")
        echo "$updated" > "$PORTFOLIO_FILE"
        printf "${BR_GREEN}Added %.4f %s at \$%s${RST}\n" "$amount" "$coin" "$buy_price"
    fi
}

remove_holding() {
    local index="$1"

    if command -v jq &>/dev/null; then
        local updated=$(jq "del(.holdings[$index])" "$PORTFOLIO_FILE")
        echo "$updated" > "$PORTFOLIO_FILE"
        printf "${BR_YELLOW}Removed holding at index %d${RST}\n" "$index"
    fi
}

get_portfolio_value() {
    init_portfolio

    if ! command -v jq &>/dev/null; then
        echo "0"
        return
    fi

    local total=0
    local holdings=$(jq -r '.holdings[] | "\(.coin)|\(.amount)|\(.buy_price)"' "$PORTFOLIO_FILE" 2>/dev/null)

    while IFS='|' read -r coin amount buy_price; do
        [[ -z "$coin" ]] && continue

        local price_data=$(fetch_price "$coin")
        IFS='|' read -r price change vol mcap <<< "$(parse_price "$price_data" "$coin")"

        local value=$(echo "$amount * $price" | bc -l 2>/dev/null || echo 0)
        total=$(echo "$total + $value" | bc -l 2>/dev/null || echo "$total")
    done <<< "$holdings"

    printf "%.2f" "$total"
}

render_portfolio() {
    init_portfolio

    printf "${BOLD}Portfolio Holdings${RST}\n\n"

    if ! command -v jq &>/dev/null; then
        printf "${TEXT_MUTED}jq required for portfolio${RST}\n"
        return
    fi

    printf "%-4s %-12s %-12s %-12s %-12s %-12s %-10s\n" "#" "COIN" "AMOUNT" "BUY PRICE" "CURR PRICE" "VALUE" "P/L %"
    printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────────────────────────────────────────────────"

    local total_value=0
    local total_invested=0
    local idx=0

    while IFS='|' read -r coin amount buy_price; do
        [[ -z "$coin" ]] && continue

        local price_data=$(fetch_price "$coin")
        IFS='|' read -r price change vol mcap <<< "$(parse_price "$price_data" "$coin")"

        local value=$(echo "$amount * $price" | bc -l 2>/dev/null || echo 0)
        local invested=$(echo "$amount * $buy_price" | bc -l 2>/dev/null || echo 0)
        local pl_pct=$(echo "($price - $buy_price) / $buy_price * 100" | bc -l 2>/dev/null || echo 0)

        local pl_color="$BR_GREEN"
        (( $(echo "$pl_pct < 0" | bc -l 2>/dev/null || echo 0) )) && pl_color="$BR_RED"

        printf "${BR_CYAN}%-4d${RST} " "$idx"
        printf "${BOLD}%-12s${RST} " "${coin:0:12}"
        printf "%-12s " "$(printf "%.4f" "$amount")"
        printf "${TEXT_MUTED}\$%-11s${RST} " "$(format_price "$buy_price")"
        printf "\$%-11s " "$(format_price "$price")"
        printf "${BR_YELLOW}\$%-11s${RST} " "$(format_price "$value")"
        printf "${pl_color}%+.2f%%${RST}\n" "$pl_pct"

        total_value=$(echo "$total_value + $value" | bc -l)
        total_invested=$(echo "$total_invested + $invested" | bc -l)
        ((idx++))
    done < <(jq -r '.holdings[] | "\(.coin)|\(.amount)|\(.buy_price)"' "$PORTFOLIO_FILE" 2>/dev/null)

    if [[ $idx -gt 0 ]]; then
        local total_pl=$(echo "($total_value - $total_invested) / $total_invested * 100" | bc -l 2>/dev/null || echo 0)
        local pl_color="$BR_GREEN"
        (( $(echo "$total_pl < 0" | bc -l 2>/dev/null || echo 0) )) && pl_color="$BR_RED"

        printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────────────────────────────────────────────────"
        printf "${BOLD}TOTAL${RST}%44s ${BR_YELLOW}\$%.2f${RST}  ${pl_color}%+.2f%%${RST}\n" "" "$total_value" "$total_pl"
    else
        printf "${TEXT_MUTED}No holdings. Use 'add' to add coins to portfolio.${RST}\n"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# PRICE ALERTS
#───────────────────────────────────────────────────────────────────────────────

init_alerts() {
    if [[ ! -f "$ALERTS_FILE" ]]; then
        echo '{"alerts":[]}' > "$ALERTS_FILE"
    fi
}

add_alert() {
    local coin="$1"
    local condition="$2"  # above, below
    local price="$3"

    init_alerts

    if command -v jq &>/dev/null; then
        local alert="{\"coin\":\"$coin\",\"condition\":\"$condition\",\"price\":$price,\"active\":true}"
        local updated=$(jq ".alerts += [$alert]" "$ALERTS_FILE")
        echo "$updated" > "$ALERTS_FILE"
        printf "${BR_GREEN}Alert set: %s %s \$%s${RST}\n" "$coin" "$condition" "$price"
    fi
}

check_alerts() {
    init_alerts

    if ! command -v jq &>/dev/null; then
        return
    fi

    local triggered=()

    while IFS='|' read -r coin condition target_price active; do
        [[ "$active" != "true" ]] && continue

        local price_data=$(fetch_price "$coin")
        IFS='|' read -r current_price change vol mcap <<< "$(parse_price "$price_data" "$coin")"

        local triggered_flag=false

        if [[ "$condition" == "above" ]]; then
            (( $(echo "$current_price >= $target_price" | bc -l 2>/dev/null || echo 0) )) && triggered_flag=true
        elif [[ "$condition" == "below" ]]; then
            (( $(echo "$current_price <= $target_price" | bc -l 2>/dev/null || echo 0) )) && triggered_flag=true
        fi

        if [[ "$triggered_flag" == "true" ]]; then
            printf "${BR_YELLOW}⚠ ALERT: %s is %s \$%s (target: \$%s)${RST}\n" "$coin" "$condition" "$current_price" "$target_price"
        fi
    done < <(jq -r '.alerts[] | "\(.coin)|\(.condition)|\(.price)|\(.active)"' "$ALERTS_FILE" 2>/dev/null)
}

#───────────────────────────────────────────────────────────────────────────────
# MARKET OVERVIEW
#───────────────────────────────────────────────────────────────────────────────

render_market_overview() {
    local global=$(fetch_global_data)

    if ! command -v jq &>/dev/null; then
        printf "${TEXT_MUTED}jq required for market overview${RST}\n"
        return
    fi

    local total_mcap=$(echo "$global" | jq -r '.data.total_market_cap.usd // 0' 2>/dev/null)
    local total_vol=$(echo "$global" | jq -r '.data.total_volume.usd // 0' 2>/dev/null)
    local btc_dom=$(echo "$global" | jq -r '.data.market_cap_percentage.btc // 0' 2>/dev/null)
    local eth_dom=$(echo "$global" | jq -r '.data.market_cap_percentage.eth // 0' 2>/dev/null)
    local active_coins=$(echo "$global" | jq -r '.data.active_cryptocurrencies // 0' 2>/dev/null)
    local mcap_change=$(echo "$global" | jq -r '.data.market_cap_change_percentage_24h_usd // 0' 2>/dev/null)

    local change_color="$BR_GREEN"
    (( $(echo "$mcap_change < 0" | bc -l 2>/dev/null || echo 0) )) && change_color="$BR_RED"

    printf "  ${BOLD}Total Market Cap:${RST} ${BR_CYAN}\$%s${RST}  " "$(format_large_number "$total_mcap")"
    printf "${change_color}(%+.2f%%)${RST}\n" "$mcap_change"

    printf "  ${BOLD}24h Volume:${RST}       ${BR_YELLOW}\$%s${RST}  " "$(format_large_number "$total_vol")"
    printf "${BOLD}Active Coins:${RST} ${TEXT_SECONDARY}%s${RST}\n" "$active_coins"

    printf "  ${BOLD}BTC Dominance:${RST}    "
    render_dominance_bar "$btc_dom" "$BR_ORANGE"
    printf "  ${BOLD}ETH Dominance:${RST}    "
    render_dominance_bar "$eth_dom" "$BR_PURPLE"
}

render_dominance_bar() {
    local pct="$1"
    local color="$2"
    local width=20

    local filled=$(printf "%.0f" "$(echo "$pct * $width / 100" | bc -l 2>/dev/null || echo 0)")
    local empty=$((width - filled))

    printf "%s" "$color"
    printf "%0.s█" $(seq 1 $filled 2>/dev/null) || true
    printf "${TEXT_MUTED}"
    printf "%0.s░" $(seq 1 $empty 2>/dev/null) || true
    printf "${RST} %.1f%%\n" "$pct"
}

#───────────────────────────────────────────────────────────────────────────────
# TOP COINS LIST
#───────────────────────────────────────────────────────────────────────────────

render_top_coins() {
    local count="${1:-15}"
    local data=$(fetch_top_coins "$count")

    if ! command -v jq &>/dev/null; then
        printf "${TEXT_MUTED}jq required${RST}\n"
        return
    fi

    printf "\n${BOLD}Top %d Cryptocurrencies${RST}\n\n" "$count"

    printf "%-4s %-15s %-12s %-10s %-14s %-15s\n" "#" "COIN" "PRICE" "24h %" "MARKET CAP" "SPARKLINE"
    printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────────────────────────────────────────────────"

    echo "$data" | jq -c '.[]' 2>/dev/null | while read -r coin; do
        local rank=$(echo "$coin" | jq -r '.market_cap_rank')
        local name=$(echo "$coin" | jq -r '.symbol' | tr '[:lower:]' '[:upper:]')
        local price=$(echo "$coin" | jq -r '.current_price')
        local change=$(echo "$coin" | jq -r '.price_change_percentage_24h // 0')
        local mcap=$(echo "$coin" | jq -r '.market_cap')
        local sparkline=$(echo "$coin" | jq -c '.sparkline_in_7d.price // []')

        local change_color="$BR_GREEN"
        (( $(echo "$change < 0" | bc -l 2>/dev/null || echo 0) )) && change_color="$BR_RED"

        printf "${BR_CYAN}%-4s${RST} " "$rank"
        printf "${BOLD}%-15s${RST} " "$name"
        printf "\$%-11s " "$(format_price "$price")"
        printf "${change_color}%+8.2f%%${RST}  " "$change"
        printf "${TEXT_MUTED}\$%-12s${RST}  " "$(format_large_number "$mcap")"
        render_mini_sparkline "$sparkline" 12
        printf "\n"
    done | head -n "$count"
}

#───────────────────────────────────────────────────────────────────────────────
# WATCHLIST
#───────────────────────────────────────────────────────────────────────────────

render_watchlist() {
    local -a coins=("${@:-${DEFAULT_COINS[@]}}")

    printf "${BOLD}Watchlist${RST}\n\n"

    for coin in "${coins[@]}"; do
        local price_data=$(fetch_price "$coin")
        IFS='|' read -r price change vol mcap <<< "$(parse_price "$price_data" "$coin")"

        local change_color="$BR_GREEN"
        local arrow="↑"
        if (( $(echo "$change < 0" | bc -l 2>/dev/null || echo 0) )); then
            change_color="$BR_RED"
            arrow="↓"
        fi

        printf "  ${BOLD}%-12s${RST} " "${coin^^}"
        printf "${BR_CYAN}\$%-12s${RST} " "$(format_price "$price")"
        printf "${change_color}%s %+.2f%%${RST}  " "$arrow" "$change"
        printf "${TEXT_MUTED}Vol: \$%s${RST}\n" "$(format_large_number "$vol")"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

render_crypto_dashboard() {
    clear_screen
    cursor_hide

    printf "${BR_YELLOW}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                     💰 CRYPTO TRADING DASHBOARD                              ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    # Market overview
    render_market_overview
    printf "\n"

    # Two-column layout
    printf "${BR_CYAN}┌───────────────────────────────────────┬──────────────────────────────────────┐${RST}\n"
    printf "${BR_CYAN}│${RST} ${BOLD}BTC/USD${RST}                              ${BR_CYAN}│${RST} ${BOLD}ETH/USD${RST}                             ${BR_CYAN}│${RST}\n"

    # Fetch BTC and ETH
    local btc_data=$(fetch_price "bitcoin")
    local eth_data=$(fetch_price "ethereum")

    IFS='|' read -r btc_price btc_change btc_vol btc_mcap <<< "$(parse_price "$btc_data" "bitcoin")"
    IFS='|' read -r eth_price eth_change eth_vol eth_mcap <<< "$(parse_price "$eth_data" "ethereum")"

    local btc_color="$BR_GREEN"
    (( $(echo "$btc_change < 0" | bc -l 2>/dev/null || echo 0) )) && btc_color="$BR_RED"

    local eth_color="$BR_GREEN"
    (( $(echo "$eth_change < 0" | bc -l 2>/dev/null || echo 0) )) && eth_color="$BR_RED"

    printf "${BR_CYAN}│${RST}  ${BR_ORANGE}\$%-36s${RST}${BR_CYAN}│${RST}  ${BR_PURPLE}\$%-35s${RST}${BR_CYAN}│${RST}\n" \
        "$(format_price "$btc_price")" "$(format_price "$eth_price")"

    printf "${BR_CYAN}│${RST}  ${btc_color}%+.2f%%${RST}%30s${BR_CYAN}│${RST}  ${eth_color}%+.2f%%${RST}%29s${BR_CYAN}│${RST}\n" \
        "$btc_change" "" "$eth_change" ""

    printf "${BR_CYAN}├───────────────────────────────────────┴──────────────────────────────────────┤${RST}\n"

    # Top coins
    printf "${BR_CYAN}│${RST} ${BOLD}Top Cryptocurrencies${RST}%56s${BR_CYAN}│${RST}\n" ""

    local top_data=$(fetch_top_coins 8)
    if command -v jq &>/dev/null; then
        echo "$top_data" | jq -c '.[]' 2>/dev/null | head -8 | while read -r coin; do
            local rank=$(echo "$coin" | jq -r '.market_cap_rank')
            local symbol=$(echo "$coin" | jq -r '.symbol' | tr '[:lower:]' '[:upper:]')
            local price=$(echo "$coin" | jq -r '.current_price')
            local change=$(echo "$coin" | jq -r '.price_change_percentage_24h // 0')

            local change_color="$BR_GREEN"
            (( $(echo "$change < 0" | bc -l 2>/dev/null || echo 0) )) && change_color="$BR_RED"

            printf "${BR_CYAN}│${RST}  ${TEXT_MUTED}%2d${RST} ${BOLD}%-8s${RST} \$%-15s ${change_color}%+8.2f%%${RST}%33s${BR_CYAN}│${RST}\n" \
                "$rank" "$symbol" "$(format_price "$price")" "$change" ""
        done
    fi

    printf "${BR_CYAN}└──────────────────────────────────────────────────────────────────────────────┘${RST}\n"

    # Check alerts
    check_alerts

    printf "\n${TEXT_MUTED}─────────────────────────────────────────────────────────────────────────────${RST}\n"
    printf "  ${TEXT_SECONDARY}[t]op coins  [c]hart  [p]ortfolio  [a]lert  [w]atchlist  [r]efresh  [q]uit${RST}\n"
}

crypto_dashboard_loop() {
    while true; do
        render_crypto_dashboard

        if read -rsn1 -t 5 key 2>/dev/null; then
            case "$key" in
                t|T)
                    clear_screen
                    render_top_coins 20
                    printf "\n${TEXT_MUTED}Press any key...${RST}"
                    read -rsn1
                    ;;
                c|C)
                    printf "\n${BR_CYAN}Coin (e.g., bitcoin): ${RST}"
                    cursor_show
                    read -r coin
                    cursor_hide
                    [[ -n "$coin" ]] && render_candlestick "$coin" 7
                    printf "\n${TEXT_MUTED}Press any key...${RST}"
                    read -rsn1
                    ;;
                p|P)
                    clear_screen
                    render_portfolio
                    printf "\n${TEXT_SECONDARY}[a]dd  [r]emove  [b]ack${RST}\n"
                    read -rsn1 pkey
                    case "$pkey" in
                        a|A)
                            printf "${BR_CYAN}Coin: ${RST}"
                            cursor_show
                            read -r coin
                            printf "${BR_CYAN}Amount: ${RST}"
                            read -r amount
                            printf "${BR_CYAN}Buy price: ${RST}"
                            read -r price
                            cursor_hide
                            add_holding "$coin" "$amount" "$price"
                            sleep 1
                            ;;
                        r|R)
                            printf "${BR_CYAN}Index to remove: ${RST}"
                            cursor_show
                            read -r idx
                            cursor_hide
                            remove_holding "$idx"
                            sleep 1
                            ;;
                    esac
                    ;;
                a|A)
                    printf "\n${BR_CYAN}Coin: ${RST}"
                    cursor_show
                    read -r coin
                    printf "${BR_CYAN}Condition (above/below): ${RST}"
                    read -r condition
                    printf "${BR_CYAN}Price: ${RST}"
                    read -r price
                    cursor_hide
                    add_alert "$coin" "$condition" "$price"
                    sleep 1
                    ;;
                w|W)
                    clear_screen
                    render_watchlist
                    printf "\n${TEXT_MUTED}Press any key...${RST}"
                    read -rsn1
                    ;;
                r|R) continue ;;
                q|Q) break ;;
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
        dashboard)   crypto_dashboard_loop ;;
        price)       fetch_price "$2" | jq '.' 2>/dev/null ;;
        top)         render_top_coins "${2:-20}" ;;
        chart)       render_candlestick "$2" "${3:-7}" ;;
        watchlist)   render_watchlist "${@:2}" ;;
        portfolio)   render_portfolio ;;
        add)         add_holding "$2" "$3" "$4" ;;
        alert)       add_alert "$2" "$3" "$4" ;;
        market)      render_market_overview ;;
        *)
            printf "Usage: %s [dashboard|price|top|chart|watchlist|portfolio|add|alert|market]\n" "$0"
            ;;
    esac
fi
