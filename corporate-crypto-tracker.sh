#!/bin/bash

# BlackRoad OS - Corporate Crypto Portfolio Real-Time Tracker
# Real-time tracking of crypto holdings with alerts

source ~/blackroad-dashboards/themes.sh
load_theme

source ~/blackroad-dashboards/api-integrations.sh

CRYPTO_DIR="$HOME/.corporate-crypto-tracker"
PRICE_HISTORY="$CRYPTO_DIR/price-history.log"
PORTFOLIO_HISTORY="$CRYPTO_DIR/portfolio-history.log"
ALERTS_LOG="$CRYPTO_DIR/alerts.log"

mkdir -p "$CRYPTO_DIR"

# Portfolio holdings
ETH_AMOUNT=2.5
SOL_AMOUNT=100
BTC_AMOUNT=0.1

# Alert thresholds (percentage change)
ALERT_THRESHOLD_WARNING=5   # 5% change
ALERT_THRESHOLD_CRITICAL=10  # 10% change

# Get current portfolio value
get_portfolio_value() {
    local eth_price=$(get_crypto_price "ethereum" 2>/dev/null)
    local sol_price=$(get_crypto_price "solana" 2>/dev/null)
    local btc_price=$(get_crypto_price "bitcoin" 2>/dev/null)

    if [ -z "$eth_price" ] || [ "$eth_price" = "null" ]; then
        echo "error|0|0|0|0"
        return 1
    fi

    local eth_value=$(echo "$ETH_AMOUNT * $eth_price" | bc)
    local sol_value=$(echo "$SOL_AMOUNT * $sol_price" | bc)
    local btc_value=$(echo "$BTC_AMOUNT * $btc_price" | bc)
    local total_value=$(echo "$eth_value + $sol_value + $btc_value" | bc)

    echo "$total_value|$eth_price|$sol_price|$btc_price|$eth_value|$sol_value|$btc_value"
}

# Log portfolio snapshot
log_portfolio_snapshot() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local portfolio_data=$(get_portfolio_value)

    if [ "$portfolio_data" = "error"* ]; then
        return 1
    fi

    echo "$timestamp|$portfolio_data" >> "$PORTFOLIO_HISTORY"
}

# Calculate 24h change
calculate_24h_change() {
    if [ ! -f "$PORTFOLIO_HISTORY" ]; then
        echo "0"
        return
    fi

    local current_value=$(tail -1 "$PORTFOLIO_HISTORY" | cut -d'|' -f2)
    local yesterday_value=$(grep "$(date -u -v-1d +"%Y-%m-%d" 2>/dev/null || date -u -d "yesterday" +"%Y-%m-%d")" "$PORTFOLIO_HISTORY" 2>/dev/null | tail -1 | cut -d'|' -f2)

    if [ -z "$yesterday_value" ] || [ "$yesterday_value" = "0" ]; then
        echo "0"
        return
    fi

    local change=$(echo "scale=2; (($current_value - $yesterday_value) / $yesterday_value) * 100" | bc)
    echo "$change"
}

# Check for price alerts
check_price_alerts() {
    local change_pct=$1
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Remove negative sign for comparison
    local abs_change=$(echo "$change_pct" | sed 's/-//')

    if (( $(echo "$abs_change >= $ALERT_THRESHOLD_CRITICAL" | bc -l) )); then
        local alert_msg="CRITICAL: Portfolio changed ${change_pct}% in 24h"
        echo "$timestamp|critical|$alert_msg" >> "$ALERTS_LOG"

        # Log to MEMORY
        ~/memory-system.sh log updated "[CORPORATE]+[CRYPTO]+[ALERT] Critical Price Change" "$alert_msg" "corporate-crypto-tracker" 2>/dev/null

        return 2
    elif (( $(echo "$abs_change >= $ALERT_THRESHOLD_WARNING" | bc -l) )); then
        local alert_msg="WARNING: Portfolio changed ${change_pct}% in 24h"
        echo "$timestamp|warning|$alert_msg" >> "$ALERTS_LOG"
        return 1
    fi

    return 0
}

# Show real-time dashboard
show_crypto_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}  ${ORANGE}💰${RESET} ${BOLD}CORPORATE CRYPTO PORTFOLIO TRACKER${RESET}                             ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "  ${TEXT_MUTED}Real-time update: $(date)${RESET}"
    echo ""

    # Get current portfolio data
    local portfolio_data=$(get_portfolio_value)

    if [ "$portfolio_data" = "error"* ]; then
        echo -e "  ${RED}Failed to fetch prices${RESET}\n"
        return
    fi

    IFS='|' read -r total_value eth_price sol_price btc_price eth_value sol_value btc_value <<< "$portfolio_data"

    # Portfolio overview
    echo -e "${TEXT_MUTED}╭─ PORTFOLIO OVERVIEW ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Portfolio Value:${RESET}  ${BOLD}${GREEN}\$$(printf "%'.2f" $total_value)${RESET}"
    echo ""

    # 24h change
    local change_24h=$(calculate_24h_change)
    local change_color="${GREEN}"
    local change_icon="↗"

    if (( $(echo "$change_24h < 0" | bc -l) )); then
        change_color="${RED}"
        change_icon="↘"
    fi

    echo -e "  ${BOLD}${TEXT_PRIMARY}24h Change:${RESET}             ${change_color}${change_icon} ${change_24h}%${RESET}"
    echo ""

    # Holdings breakdown
    echo -e "${TEXT_MUTED}╭─ HOLDINGS BREAKDOWN ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    # ETH
    local eth_pct=$(echo "scale=2; ($eth_value / $total_value) * 100" | bc)
    echo -e "  ${ORANGE}◆${RESET} ${BOLD}Ethereum (ETH)${RESET}"
    echo -e "    Amount:     ${CYAN}$ETH_AMOUNT ETH${RESET}"
    echo -e "    Price:      ${TEXT_MUTED}\$$(printf "%'.2f" $eth_price)${RESET}"
    echo -e "    Value:      ${GREEN}\$$(printf "%'.2f" $eth_value)${RESET} ${TEXT_MUTED}(${eth_pct}%)${RESET}"
    echo ""

    # SOL
    local sol_pct=$(echo "scale=2; ($sol_value / $total_value) * 100" | bc)
    echo -e "  ${PURPLE}◆${RESET} ${BOLD}Solana (SOL)${RESET}"
    echo -e "    Amount:     ${CYAN}$SOL_AMOUNT SOL${RESET}"
    echo -e "    Price:      ${TEXT_MUTED}\$$(printf "%'.2f" $sol_price)${RESET}"
    echo -e "    Value:      ${GREEN}\$$(printf "%'.2f" $sol_value)${RESET} ${TEXT_MUTED}(${sol_pct}%)${RESET}"
    echo ""

    # BTC
    local btc_pct=$(echo "scale=2; ($btc_value / $total_value) * 100" | bc)
    echo -e "  ${GOLD}◆${RESET} ${BOLD}Bitcoin (BTC)${RESET}"
    echo -e "    Amount:     ${CYAN}$BTC_AMOUNT BTC${RESET}"
    echo -e "    Price:      ${TEXT_MUTED}\$$(printf "%'.2f" $btc_price)${RESET}"
    echo -e "    Value:      ${GREEN}\$$(printf "%'.2f" $btc_value)${RESET} ${TEXT_MUTED}(${btc_pct}%)${RESET}"
    echo ""

    # Wallet addresses
    echo -e "${TEXT_MUTED}╭─ WALLET ADDRESSES ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}ETH/SOL:${RESET}         ${CYAN}MetaMask/Phantom (iPhone)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}BTC:${RESET}             ${GOLD}1Ak2fc5N2q4imYxqVMqBNEQDFq8J2Zs9TZ${RESET}"
    echo ""

    # Recent alerts
    echo -e "${TEXT_MUTED}╭─ RECENT ALERTS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$ALERTS_LOG" ]; then
        local alert_count=$(wc -l < "$ALERTS_LOG" | xargs)

        if [ "$alert_count" -gt 0 ]; then
            tail -5 "$ALERTS_LOG" | while IFS='|' read -r timestamp severity message; do
                local color="${CYAN}"
                local icon="ℹ"

                [ "$severity" = "warning" ] && color="${ORANGE}" && icon="⚠"
                [ "$severity" = "critical" ] && color="${RED}" && icon="🚨"

                local time=$(echo "$timestamp" | cut -d'T' -f2 | cut -d':' -f1-2)
                echo -e "  ${color}${icon}${RESET} ${TEXT_MUTED}[$time]${RESET} $message"
            done
        else
            echo -e "  ${GREEN}✓${RESET} ${TEXT_MUTED}No alerts${RESET}"
        fi
    else
        echo -e "  ${GREEN}✓${RESET} ${TEXT_MUTED}No alerts${RESET}"
    fi
    echo ""

    # Price history (last 24h)
    echo -e "${TEXT_MUTED}╭─ PORTFOLIO TREND (24H) ───────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$PORTFOLIO_HISTORY" ]; then
        # Show mini chart (last 10 data points)
        tail -10 "$PORTFOLIO_HISTORY" | while IFS='|' read -r ts val eth sol btc ethv solv btcv; do
            local time=$(echo "$ts" | cut -d'T' -f2 | cut -d':' -f1-2)
            local bar_length=$(echo "scale=0; ($val / 1000)" | bc)
            [ "$bar_length" -lt 1 ] && bar_length=1
            [ "$bar_length" -gt 50 ] && bar_length=50

            printf "  ${TEXT_MUTED}%s${RESET} ${PURPLE}%s${RESET} \$%'.0f\n" "$time" "$(printf '█%.0s' $(seq 1 $bar_length))" "$val"
        done
    else
        echo -e "  ${TEXT_MUTED}No history data yet${RESET}"
    fi
    echo ""

    # Actions
    echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[U]${RESET} Update Now  ${TEXT_SECONDARY}[A]${RESET} Auto Track  ${TEXT_SECONDARY}[H]${RESET} History  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Auto-tracking loop
auto_track_loop() {
    local cycle=0

    echo -e "${BOLD}${GREEN}Starting auto-tracking mode...${RESET}\n"
    echo -e "Tracking portfolio every 5 minutes\n"

    while true; do
        ((cycle++))

        clear
        echo -e "${BOLD}${GOLD}AUTO CRYPTO TRACKER - CYCLE #$cycle${RESET}"
        echo -e "${TEXT_MUTED}$(date)${RESET}\n"

        # Update portfolio
        log_portfolio_snapshot

        # Check for alerts
        local change_24h=$(calculate_24h_change)
        check_price_alerts "$change_24h"
        local alert_status=$?

        # Show current status
        local portfolio_data=$(get_portfolio_value)
        IFS='|' read -r total_value eth_price sol_price btc_price eth_value sol_value btc_value <<< "$portfolio_data"

        echo -e "${BOLD}${GREEN}Portfolio Value: \$$(printf "%'.2f" $total_value)${RESET}"
        echo -e "${BOLD}24h Change: ${change_24h}%${RESET}"

        if [ "$alert_status" = "2" ]; then
            echo -e "${RED}🚨 CRITICAL ALERT: Large price movement!${RESET}"
        elif [ "$alert_status" = "1" ]; then
            echo -e "${ORANGE}⚠ WARNING: Significant price change${RESET}"
        else
            echo -e "${GREEN}✓ Portfolio stable${RESET}"
        fi

        echo -e "\n${TEXT_MUTED}Next update in 5 minutes... Press Q to stop${RESET}\n"

        # Wait with interrupt
        read -t 300 -n1 key

        if [ "$key" = "q" ] || [ "$key" = "Q" ]; then
            echo -e "\n${ORANGE}Auto-tracking stopped${RESET}\n"
            return
        fi
    done
}

# Show portfolio history
show_history() {
    clear
    echo -e "${BOLD}${CYAN}PORTFOLIO HISTORY${RESET}\n"

    if [ ! -f "$PORTFOLIO_HISTORY" ]; then
        echo -e "${TEXT_MUTED}No history data available${RESET}\n"
        return
    fi

    echo -e "${TEXT_MUTED}Timestamp                Total Value    ETH Price   SOL Price   BTC Price${RESET}"
    echo -e "${TEXT_MUTED}───────────────────────────────────────────────────────────────────────${RESET}"

    tail -20 "$PORTFOLIO_HISTORY" | while IFS='|' read -r ts val eth sol btc ethv solv btcv; do
        printf "%s  \$%'10.2f  \$%'7.2f  \$%'6.2f  \$%'8.2f\n" "$ts" "$val" "$eth" "$sol" "$btc"
    done

    echo ""
}

# Main loop
main() {
    # Initial snapshot
    log_portfolio_snapshot

    while true; do
        show_crypto_dashboard

        read -n1 key

        case "$key" in
            'u'|'U')
                clear
                echo -e "${CYAN}Updating portfolio...${RESET}\n"
                log_portfolio_snapshot
                sleep 1
                ;;
            'a'|'A')
                clear
                auto_track_loop
                ;;
            'h'|'H')
                show_history
                echo -e "${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            'q'|'Q')
                clear
                echo -e "\n${CYAN}Crypto tracker stopped${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
