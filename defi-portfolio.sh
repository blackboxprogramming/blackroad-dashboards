#!/bin/bash

# BlackRoad OS - DeFi Portfolio Tracker
# Real-time DeFi positions, yields, and protocol analytics

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
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${ORANGE}💰${RESET} ${BOLD}DeFi PORTFOLIO TRACKER${RESET}                                           ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Total Value
    echo -e "${TEXT_MUTED}╭─ PORTFOLIO VALUE ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Value Locked:${RESET}     ${BOLD}${GREEN}\$847,293.42${RESET}  ${GREEN}↑ 12.3%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}24h Change:${RESET}             ${GREEN}+\$102,847.21${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}7d Change:${RESET}              ${GREEN}+\$287,392.84${RESET}"
    echo ""

    # DeFi Positions
    echo -e "${TEXT_MUTED}╭─ ACTIVE POSITIONS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}Protocol${RESET}          ${ORANGE}Value${RESET}           ${PINK}APY${RESET}      ${PURPLE}Rewards${RESET}"
    echo -e "  ${TEXT_MUTED}─────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}Uniswap V3${RESET}       ${ORANGE}\$324,847${RESET}      ${PINK}18.4%${RESET}    ${PURPLE}\$156.23/day${RESET}"
    echo -e "  ${BOLD}Aave${RESET}             ${ORANGE}\$198,234${RESET}       ${PINK}7.2%${RESET}    ${PURPLE}\$39.12/day${RESET}"
    echo -e "  ${BOLD}Curve${RESET}            ${ORANGE}\$156,789${RESET}      ${PINK}12.8%${RESET}    ${PURPLE}\$54.98/day${RESET}"
    echo -e "  ${BOLD}Compound${RESET}         ${ORANGE}\$89,456${RESET}        ${PINK}5.4%${RESET}    ${PURPLE}\$13.23/day${RESET}"
    echo -e "  ${BOLD}Yearn${RESET}            ${ORANGE}\$77,967${RESET}       ${PINK}9.7%${RESET}    ${PURPLE}\$20.71/day${RESET}"
    echo ""

    # Asset Allocation
    echo -e "${TEXT_MUTED}╭─ ASSET ALLOCATION ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}ETH${RESET}    ${CYAN}████████████████████████${RESET}          48%   \$407,181"
    echo -e "  ${BOLD}USDC${RESET}   ${ORANGE}███████████████${RESET}                 28%   \$237,242"
    echo -e "  ${BOLD}DAI${RESET}    ${PINK}█████████${RESET}                        15%   \$127,094"
    echo -e "  ${BOLD}Other${RESET}  ${PURPLE}████${RESET}                              9%   \$75,776"
    echo ""

    # Yield Farming
    echo -e "${TEXT_MUTED}╭─ ACTIVE FARMS ────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${BOLD}ETH-USDC LP${RESET}       Pool: ${CYAN}\$2.4M${RESET}   Share: ${ORANGE}13.5%${RESET}   APY: ${PINK}24.6%${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}DAI-USDC LP${RESET}       Pool: ${CYAN}\$1.8M${RESET}   Share: ${ORANGE}8.7%${RESET}    APY: ${PINK}16.3%${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}CRV Staking${RESET}       Locked: ${CYAN}\$89K${RESET}    veCRV: ${ORANGE}2.4x${RESET}   APY: ${PINK}32.1%${RESET}"
    echo ""

    # Impermanent Loss
    echo -e "${TEXT_MUTED}╭─ RISK METRICS ────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Impermanent Loss:${RESET}       ${RED}-\$12,847${RESET}  ${TEXT_MUTED}(-1.5%)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Gas Spent (30d):${RESET}        ${ORANGE}\$2,384${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Health Factor:${RESET}          ${GREEN}2.84${RESET}  ${GREEN}✓ Safe${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Liquidation Price:${RESET}      ${CYAN}\$1,247 ETH${RESET}"
    echo ""

    # Recent Transactions
    echo -e "${TEXT_MUTED}╭─ RECENT ACTIVITY ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}↑${RESET} ${TEXT_SECONDARY}Supplied 10 ETH to Aave${RESET}                    ${TEXT_MUTED}2h ago${RESET}"
    echo -e "  ${CYAN}⇄${RESET} ${TEXT_SECONDARY}Swapped 5,000 USDC → DAI on Uniswap${RESET}        ${TEXT_MUTED}5h ago${RESET}"
    echo -e "  ${ORANGE}↓${RESET} ${TEXT_SECONDARY}Withdrew 2.5 ETH from Curve${RESET}                ${TEXT_MUTED}1d ago${RESET}"
    echo -e "  ${PURPLE}★${RESET} ${TEXT_SECONDARY}Claimed \$234 in CRV rewards${RESET}                ${TEXT_MUTED}1d ago${RESET}"
    echo ""

    # Footer
    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}Last updated: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Network: ${RESET}${BOLD}Ethereum${RESET}  ${TEXT_SECONDARY}|  Gas: ${RESET}${BOLD}42 gwei${RESET}"
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
