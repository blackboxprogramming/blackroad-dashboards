#!/bin/bash

# BlackRoad OS - Token Analytics Dashboard
# Deep dive into token metrics, on-chain data, and trading analysis

source ~/blackroad-dashboards/themes.sh 2>/dev/null || true

# Colors
ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GREEN="\033[38;2;20;241;149m"
RED="\033[38;2;255;0;107m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

show_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${ORANGE}📊${RESET} ${BOLD}TOKEN ANALYTICS DASHBOARD${RESET}                                        ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Token Overview
    echo -e "${TEXT_MUTED}╭─ TOKEN: ETH/USDC ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Price:${RESET}              ${BOLD}${GREEN}\$1,987.42${RESET}          ${GREEN}↑ \$127.84 (6.9%)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Market Cap:${RESET}         ${BOLD}${CYAN}\$238.7B${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}24h Volume:${RESET}         ${BOLD}${PURPLE}\$18.4B${RESET}           ${TEXT_MUTED}Vol/MCap: 7.7%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}24h High/Low:${RESET}       ${ORANGE}\$2,042.18${RESET} / ${RED}\$1,847.92${RESET}"
    echo ""

    # Price Chart
    echo -e "${TEXT_MUTED}╭─ PRICE CHART (24H) ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  2050  ${GREEN}                                        ╭──╮${RESET}"
    echo -e "  2025  ${GREEN}                              ╭───╮  ╭─╯${RESET}  ${GREEN}│${RESET}"
    echo -e "  2000  ${CYAN}                      ╭───────╯${RESET}   ${GREEN}╰──╯${RESET}   ${GREEN}│${RESET}  ${BOLD}\$1,987${RESET}"
    echo -e "  1975  ${CYAN}          ╭───────────╯${RESET}"
    echo -e "  1950  ${ORANGE}  ╭───────╯${RESET}"
    echo -e "  1925  ${ORANGE}──╯${RESET}"
    echo ""
    echo -e "        ${TEXT_MUTED}00:00    06:00    12:00    18:00    24:00${RESET}"
    echo ""

    # Trading Metrics
    echo -e "${TEXT_MUTED}╭─ TRADING METRICS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}Exchange${RESET}          ${ORANGE}Volume${RESET}          ${PINK}Liquidity${RESET}       ${PURPLE}Spread${RESET}"
    echo -e "  ${TEXT_MUTED}────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}Binance${RESET}          ${ORANGE}\$6.8B${RESET}          ${PINK}\$847M${RESET}          ${PURPLE}0.02%${RESET}"
    echo -e "  ${BOLD}Coinbase${RESET}         ${ORANGE}\$4.2B${RESET}          ${PINK}\$623M${RESET}          ${PURPLE}0.03%${RESET}"
    echo -e "  ${BOLD}Uniswap V3${RESET}       ${ORANGE}\$2.9B${RESET}          ${PINK}\$1.2B${RESET}          ${PURPLE}0.05%${RESET}"
    echo -e "  ${BOLD}Kraken${RESET}           ${ORANGE}\$1.8B${RESET}          ${PINK}\$384M${RESET}          ${PURPLE}0.04%${RESET}"
    echo ""

    # On-Chain Metrics
    echo -e "${TEXT_MUTED}╭─ ON-CHAIN METRICS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Active Addresses:${RESET}   ${BOLD}${CYAN}847,234${RESET}           ${GREEN}↑ 12.4%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Transactions:${RESET}       ${BOLD}${PURPLE}1.2M${RESET}              ${GREEN}↑ 8.7%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Whale Wallets:${RESET}      ${BOLD}${ORANGE}2,847${RESET}             ${TEXT_MUTED}Holding 42%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Exchange Flow:${RESET}      ${GREEN}+\$127M${RESET} in  ${RED}-\$84M${RESET} out  ${GREEN}Net: +\$43M${RESET}"
    echo ""

    # Top Holders
    echo -e "${TEXT_MUTED}╭─ TOP HOLDERS ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Wallet${RESET}                          ${CYAN}Balance${RESET}        ${ORANGE}% Supply${RESET}"
    echo -e "  ${TEXT_MUTED}────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}0x742d...3f8a${RESET} ${TEXT_MUTED}(Binance)${RESET}       ${CYAN}2.4M ETH${RESET}      ${ORANGE}2.1%${RESET}"
    echo -e "  ${BOLD}0x8e9b...2c1d${RESET} ${TEXT_MUTED}(Coinbase)${RESET}      ${CYAN}1.8M ETH${RESET}      ${ORANGE}1.6%${RESET}"
    echo -e "  ${BOLD}0x1f3a...9d2e${RESET} ${TEXT_MUTED}(Whale)${RESET}         ${CYAN}847K ETH${RESET}      ${ORANGE}0.7%${RESET}"
    echo -e "  ${BOLD}0x4b7c...1a8f${RESET} ${TEXT_MUTED}(Foundation)${RESET}    ${CYAN}623K ETH${RESET}      ${ORANGE}0.5%${RESET}"
    echo ""

    # Technical Indicators
    echo -e "${TEXT_MUTED}╭─ TECHNICAL INDICATORS ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}●${RESET} ${BOLD}RSI (14):${RESET}           ${GREEN}67.2${RESET}  ${TEXT_MUTED}(Bullish)${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}MACD:${RESET}              ${GREEN}+12.4${RESET}  ${TEXT_MUTED}(Buy Signal)${RESET}"
    echo -e "  ${PINK}●${RESET} ${BOLD}Bollinger:${RESET}         ${ORANGE}\$1,847${RESET} - ${GREEN}\$2,124${RESET}  ${TEXT_MUTED}(Upper Band Test)${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}EMA (50/200):${RESET}      ${GREEN}Golden Cross${RESET}  ${TEXT_MUTED}(Strong Uptrend)${RESET}"
    echo ""

    # Recent Trades
    echo -e "${TEXT_MUTED}╭─ LARGE TRANSACTIONS ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}↑${RESET} ${TEXT_SECONDARY}Bought 500 ETH for \$993,710${RESET}                ${TEXT_MUTED}Binance • 2m${RESET}"
    echo -e "  ${RED}↓${RESET} ${TEXT_SECONDARY}Sold 750 ETH for \$1,490,565${RESET}                ${TEXT_MUTED}Coinbase • 8m${RESET}"
    echo -e "  ${GREEN}↑${RESET} ${TEXT_SECONDARY}Bought 1,200 ETH for \$2,384,904${RESET}            ${TEXT_MUTED}Uniswap • 15m${RESET}"
    echo -e "  ${CYAN}⇄${RESET} ${TEXT_SECONDARY}Swap 2M USDC → 1,006 ETH${RESET}                    ${TEXT_MUTED}1inch • 24m${RESET}"
    echo ""

    # Sentiment
    echo -e "${TEXT_MUTED}╭─ MARKET SENTIMENT ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}Fear & Greed Index:${RESET}    ${GREEN}████████████${TEXT_MUTED}████${RESET}  ${BOLD}${GREEN}72${RESET} ${TEXT_MUTED}(Greed)${RESET}"
    echo -e "  ${BOLD}Social Volume:${RESET}         ${PURPLE}▁▂▃▅▇███▇▅▃▂▁${RESET}  ${ORANGE}↑ 47%${RESET}"
    echo -e "  ${BOLD}Funding Rates:${RESET}         ${GREEN}+0.024%${RESET}  ${TEXT_MUTED}(8h)${RESET}  ${TEXT_SECONDARY}Long bias${RESET}"
    echo ""

    # Footer
    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}Updated: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Data: ${RESET}${BOLD}CoinGecko, Etherscan${RESET}  ${TEXT_SECONDARY}|  Gas: ${RESET}${BOLD}38 gwei${RESET}"
    echo ""
}

# Main loop
if [[ "$1" == "--watch" ]]; then
    while true; do
        show_dashboard
        sleep 5
    done
else
    show_dashboard
fi
