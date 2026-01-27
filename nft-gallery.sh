#!/bin/bash

# BlackRoad OS - NFT Gallery Dashboard
# Track your NFT collection, floor prices, and marketplace activity

source ~/blackroad-dashboards/themes.sh 2>/dev/null || true

# Colors
ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GREEN="\033[38;2;20;241;149m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

show_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${PINK}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PINK}║${RESET}  ${PURPLE}🎨${RESET} ${BOLD}NFT GALLERY DASHBOARD${RESET}                                            ${BOLD}${PINK}║${RESET}"
    echo -e "${BOLD}${PINK}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Portfolio Summary
    echo -e "${TEXT_MUTED}╭─ COLLECTION VALUE ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total NFTs:${RESET}             ${BOLD}${CYAN}47${RESET} across ${BOLD}${ORANGE}12${RESET} collections"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Portfolio Value:${RESET}        ${BOLD}${GREEN}124.8 ETH${RESET}  ${TEXT_MUTED}(\$248,392)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Cost Basis:${RESET}       ${BOLD}${ORANGE}89.2 ETH${RESET}   ${GREEN}↑ 39.9%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Unrealized Gain:${RESET}        ${BOLD}${GREEN}+35.6 ETH${RESET}  ${TEXT_MUTED}(\$70,848)${RESET}"
    echo ""

    # Top Collections
    echo -e "${TEXT_MUTED}╭─ YOUR COLLECTIONS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Collection${RESET}                ${CYAN}Owned${RESET}   ${ORANGE}Floor${RESET}      ${PINK}Value${RESET}      ${PURPLE}Change${RESET}"
    echo -e "  ${TEXT_MUTED}─────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}🐵 Bored Ape YC${RESET}          ${CYAN}2${RESET}      ${ORANGE}32.5Ξ${RESET}    ${PINK}65.0Ξ${RESET}     ${GREEN}↑ 12%${RESET}"
    echo -e "  ${BOLD}🪨 Azuki${RESET}                  ${CYAN}5${RESET}      ${ORANGE}9.8Ξ${RESET}     ${PINK}49.0Ξ${RESET}     ${GREEN}↑ 8%${RESET}"
    echo -e "  ${BOLD}🎭 Pudgy Penguins${RESET}         ${CYAN}3${RESET}      ${ORANGE}6.2Ξ${RESET}     ${PINK}18.6Ξ${RESET}     ${GREEN}↑ 15%${RESET}"
    echo -e "  ${BOLD}🔷 Art Blocks${RESET}             ${CYAN}8${RESET}      ${ORANGE}1.2Ξ${RESET}      ${PINK}9.6Ξ${RESET}     ${TEXT_MUTED}→ 0%${RESET}"
    echo -e "  ${BOLD}⚡ DeGods${RESET}                  ${CYAN}4${RESET}      ${ORANGE}7.1Ξ${RESET}     ${PINK}28.4Ξ${RESET}     ${GREEN}↑ 21%${RESET}"
    echo ""

    # Featured NFTs
    echo -e "${TEXT_MUTED}╭─ FEATURED PIECES ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    
    # NFT 1
    echo -e "  ${ORANGE}┌──────────────────────┐${RESET}  ${PINK}┌──────────────────────┐${RESET}  ${PURPLE}┌──────────────────────┐${RESET}"
    echo -e "  ${ORANGE}│${RESET}   ${BOLD}🐵${RESET}                ${ORANGE}│${RESET}  ${PINK}│${RESET}   ${BOLD}🪨${RESET}                ${PINK}│${RESET}  ${PURPLE}│${RESET}   ${BOLD}🎭${RESET}                ${PURPLE}│${RESET}"
    echo -e "  ${ORANGE}│${RESET}                      ${ORANGE}│${RESET}  ${PINK}│${RESET}                      ${PINK}│${RESET}  ${PURPLE}│${RESET}                      ${PURPLE}│${RESET}"
    echo -e "  ${ORANGE}│${RESET}   ${TEXT_SECONDARY}BAYC #4729${RESET}       ${ORANGE}│${RESET}  ${PINK}│${RESET}   ${TEXT_SECONDARY}Azuki #8472${RESET}      ${PINK}│${RESET}  ${PURPLE}│${RESET}   ${TEXT_SECONDARY}Pudgy #2341${RESET}      ${PURPLE}│${RESET}"
    echo -e "  ${ORANGE}│${RESET}   ${TEXT_MUTED}32.5 ETH${RESET}          ${ORANGE}│${RESET}  ${PINK}│${RESET}   ${TEXT_MUTED}9.8 ETH${RESET}           ${PINK}│${RESET}  ${PURPLE}│${RESET}   ${TEXT_MUTED}6.2 ETH${RESET}           ${PURPLE}│${RESET}"
    echo -e "  ${ORANGE}└──────────────────────┘${RESET}  ${PINK}└──────────────────────┘${RESET}  ${PURPLE}└──────────────────────┘${RESET}"
    echo ""

    # Market Activity
    echo -e "${TEXT_MUTED}╭─ RECENT MARKETPLACE ACTIVITY ─────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Listed Azuki #1234 for 12.5 ETH${RESET}            ${TEXT_MUTED}OpenSea • 1h${RESET}"
    echo -e "  ${CYAN}↑${RESET} ${TEXT_SECONDARY}Received offer 10.2 ETH on BAYC #4729${RESET}       ${TEXT_MUTED}Blur • 3h${RESET}"
    echo -e "  ${PURPLE}★${RESET} ${TEXT_SECONDARY}Minted Art Blocks Curated #847${RESET}             ${TEXT_MUTED}Chain • 8h${RESET}"
    echo -e "  ${ORANGE}$${RESET} ${TEXT_SECONDARY}Sold Pudgy Penguin #9876 for 8.4 ETH${RESET}       ${TEXT_MUTED}LooksRare • 1d${RESET}"
    echo ""

    # Trending
    echo -e "${TEXT_MUTED}╭─ TRENDING COLLECTIONS ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}1.${RESET} ${ORANGE}Doodles${RESET}           Floor: ${CYAN}5.2Ξ${RESET}   Vol: ${PURPLE}847Ξ${RESET}    ${GREEN}↑ 28%${RESET}"
    echo -e "  ${BOLD}2.${RESET} ${PINK}CloneX${RESET}            Floor: ${CYAN}3.8Ξ${RESET}   Vol: ${PURPLE}623Ξ${RESET}    ${GREEN}↑ 19%${RESET}"
    echo -e "  ${BOLD}3.${RESET} ${PURPLE}Moonbirds${RESET}         Floor: ${CYAN}7.1Ξ${RESET}   Vol: ${PURPLE}1.2KΞ${RESET}   ${GREEN}↑ 15%${RESET}"
    echo ""

    # Rarity Traits
    echo -e "${TEXT_MUTED}╭─ RARITY HIGHLIGHTS ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}●${RESET} ${BOLD}BAYC #4729${RESET}         Rarity: ${ORANGE}Top 5%${RESET}    Traits: ${PINK}Golden Fur, Laser Eyes${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}Azuki #8472${RESET}        Rarity: ${ORANGE}Top 12%${RESET}   Traits: ${PINK}Red Hoodie, Katana${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Art Block #847${RESET}     Edition: ${ORANGE}12/100${RESET}    Artist: ${PINK}Snowfro${RESET}"
    echo ""

    # Footer
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}Last updated: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Markets: ${RESET}${BOLD}OpenSea, Blur, LooksRare${RESET}"
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
