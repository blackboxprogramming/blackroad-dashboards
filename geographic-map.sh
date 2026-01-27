#!/bin/bash

# BlackRoad OS - Geographic Data Map
# Visualize global data distribution with ASCII world map

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
    echo -e "${BOLD}${CYAN}║${RESET}  ${BLUE}🌍${RESET} ${BOLD}GEOGRAPHIC DATA MAP${RESET}                                              ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Global Statistics
    echo -e "${TEXT_MUTED}╭─ GLOBAL OVERVIEW ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Active Regions:${RESET}     ${BOLD}${CYAN}47${RESET}               ${TEXT_SECONDARY}across 6 continents${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Users:${RESET}        ${BOLD}${GREEN}2.4M${RESET}             ${TEXT_SECONDARY}online now${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Data Centers:${RESET}       ${BOLD}${PURPLE}12${RESET}               ${TEXT_SECONDARY}strategically located${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Avg Latency:${RESET}        ${BOLD}${ORANGE}47ms${RESET}             ${TEXT_SECONDARY}global${RESET}"
    echo ""

    # ASCII World Map
    echo -e "${TEXT_MUTED}╭─ WORLD MAP ───────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "                      ${TEXT_MUTED}.${RESET}            ${GREEN}●${RESET}                      "
    echo -e "           ${TEXT_MUTED}___${RESET}     ${ORANGE}●${RESET}  ${TEXT_MUTED}._____.${RESET}  ${PINK}●${RESET}  ${TEXT_MUTED}.${RESET}  ${RED}●${RESET}                "
    echo -e "          ${TEXT_MUTED}(   )${RESET}  ${CYAN}●${RESET}  ${TEXT_MUTED}(       )${RESET}  ${PURPLE}●${RESET}  ${TEXT_MUTED}(  )${RESET}                 "
    echo -e "          ${TEXT_MUTED}|   |${RESET}      ${TEXT_MUTED}|  ${BLUE}●${RESET}  ${TEXT_MUTED}|${RESET}        ${TEXT_MUTED}|__|${RESET}                 "
    echo -e "          ${TEXT_MUTED}|${ORANGE}●${RESET} ${TEXT_MUTED}|${RESET}      ${TEXT_MUTED}|     |${RESET}                           "
    echo -e "          ${TEXT_MUTED}\\___/${RESET}      ${TEXT_MUTED}\\${PINK}●${RESET}  ${TEXT_MUTED}/${RESET}                            "
    echo -e "                      ${TEXT_MUTED}\\___/${RESET}    ${PURPLE}●${RESET}                       "
    echo -e "                                                        "
    echo -e "              ${CYAN}●${RESET}                      ${GREEN}●${RESET}                 "
    echo -e "          ${TEXT_MUTED}____${RESET}                  ${TEXT_MUTED}____${RESET}                   "
    echo -e "         ${TEXT_MUTED}/    \\${RESET}   ${ORANGE}●${RESET}          ${TEXT_MUTED}/    \\${RESET}    ${PINK}●${RESET}            "
    echo -e "        ${TEXT_MUTED}(  ${BLUE}●${RESET}  ${TEXT_MUTED})${RESET}             ${TEXT_MUTED}(  ${PURPLE}●${RESET}  ${TEXT_MUTED})${RESET}                 "
    echo -e "         ${TEXT_MUTED}\\____/${RESET}               ${TEXT_MUTED}\\____/${RESET}                   "
    echo ""

    # Regional Breakdown
    echo -e "${TEXT_MUTED}╭─ REGIONAL BREAKDOWN ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Region${RESET}              ${CYAN}Users${RESET}      ${ORANGE}Traffic${RESET}    ${PINK}Latency${RESET}"
    echo -e "  ${TEXT_MUTED}─────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}🇺🇸 North America${RESET}   ${CYAN}847K${RESET}       ${ORANGE}2.4 TB/s${RESET}   ${PINK}23ms${RESET}"
    echo -e "  ${BOLD}🇪🇺 Europe${RESET}          ${CYAN}623K${RESET}       ${ORANGE}1.8 TB/s${RESET}   ${PINK}31ms${RESET}"
    echo -e "  ${BOLD}🇨🇳 Asia Pacific${RESET}    ${CYAN}547K${RESET}       ${ORANGE}1.6 TB/s${RESET}   ${PINK}42ms${RESET}"
    echo -e "  ${BOLD}🇧🇷 South America${RESET}   ${CYAN}234K${RESET}       ${ORANGE}0.8 TB/s${RESET}   ${PINK}67ms${RESET}"
    echo -e "  ${BOLD}🇦🇺 Oceania${RESET}         ${CYAN}89K${RESET}        ${ORANGE}0.3 TB/s${RESET}   ${PINK}89ms${RESET}"
    echo -e "  ${BOLD}🇿🇦 Africa${RESET}          ${CYAN}47K${RESET}        ${ORANGE}0.2 TB/s${RESET}   ${PINK}124ms${RESET}"
    echo ""

    # Top Cities
    echo -e "${TEXT_MUTED}╭─ TOP CITIES ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}1.${RESET} ${BOLD}New York${RESET}        ${CYAN}234K users${RESET}    ${GREEN}↑ 12%${RESET}    Lat: ${PINK}19ms${RESET}"
    echo -e "  ${PINK}2.${RESET} ${BOLD}London${RESET}          ${CYAN}198K users${RESET}    ${GREEN}↑ 8%${RESET}     Lat: ${PINK}28ms${RESET}"
    echo -e "  ${PURPLE}3.${RESET} ${BOLD}Tokyo${RESET}           ${CYAN}187K users${RESET}    ${GREEN}↑ 15%${RESET}    Lat: ${PINK}35ms${RESET}"
    echo -e "  ${BLUE}4.${RESET} ${BOLD}Singapore${RESET}       ${CYAN}156K users${RESET}    ${GREEN}↑ 21%${RESET}    Lat: ${PINK}42ms${RESET}"
    echo -e "  ${CYAN}5.${RESET} ${BOLD}Frankfurt${RESET}       ${CYAN}142K users${RESET}    ${GREEN}↑ 9%${RESET}     Lat: ${PINK}25ms${RESET}"
    echo ""

    # Traffic Patterns
    echo -e "${TEXT_MUTED}╭─ TRAFFIC HEAT MAP ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}Activity by Hour (UTC)${RESET}"
    echo ""
    echo -e "  00:00  ${TEXT_MUTED}▁▁▁▁${RESET}                    ${TEXT_SECONDARY}Low${RESET}"
    echo -e "  06:00  ${CYAN}▃▃▃▃▃▃${RESET}                  ${TEXT_SECONDARY}Rising${RESET}"
    echo -e "  12:00  ${ORANGE}▆▆▆▆▆▆▆▆▆▆${RESET}            ${TEXT_SECONDARY}Peak${RESET}"
    echo -e "  18:00  ${GREEN}▇▇▇▇▇▇▇▇▇▇▇▇${RESET}          ${TEXT_SECONDARY}Peak${RESET}"
    echo -e "  23:00  ${PURPLE}▅▅▅▅▅▅${RESET}                  ${TEXT_SECONDARY}Declining${RESET}"
    echo ""

    # Connection Quality
    echo -e "${TEXT_MUTED}╭─ CONNECTION QUALITY ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}Excellent${RESET}      ${GREEN}███████████████████████${RESET}            67%"
    echo -e "  ${CYAN}Good${RESET}           ${CYAN}████████${RESET}                           23%"
    echo -e "  ${ORANGE}Fair${RESET}           ${ORANGE}███${RESET}                                 8%"
    echo -e "  ${RED}Poor${RESET}           ${RED}█${RESET}                                   2%"
    echo ""

    # Data Centers
    echo -e "${TEXT_MUTED}╭─ DATA CENTER STATUS ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${BOLD}US-East-1${RESET}      Load: ${CYAN}67%${RESET}   Capacity: ${ORANGE}847 TB${RESET}   ${GREEN}✓ Healthy${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}EU-West-1${RESET}      Load: ${CYAN}54%${RESET}   Capacity: ${ORANGE}623 TB${RESET}   ${GREEN}✓ Healthy${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}AP-Southeast${RESET}   Load: ${CYAN}72%${RESET}   Capacity: ${ORANGE}547 TB${RESET}   ${GREEN}✓ Healthy${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}SA-East-1${RESET}      Load: ${CYAN}34%${RESET}   Capacity: ${ORANGE}234 TB${RESET}   ${GREEN}✓ Healthy${RESET}"
    echo ""

    # Recent Events
    echo -e "${TEXT_MUTED}╭─ RECENT EVENTS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}↑${RESET} ${TEXT_SECONDARY}Traffic spike in Asia Pacific +47%${RESET}          ${TEXT_MUTED}Tokyo • 5m${RESET}"
    echo -e "  ${CYAN}○${RESET} ${TEXT_SECONDARY}New edge location deployed${RESET}                  ${TEXT_MUTED}Mumbai • 12m${RESET}"
    echo -e "  ${ORANGE}⚠${RESET} ${TEXT_SECONDARY}High latency detected in Africa${RESET}            ${TEXT_MUTED}Lagos • 23m${RESET}"
    echo -e "  ${PURPLE}★${RESET} ${TEXT_SECONDARY}Load balancing optimized${RESET}                   ${TEXT_MUTED}Global • 1h${RESET}"
    echo ""

    # Footer
    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}Updated: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Coverage: ${RESET}${BOLD}195 countries${RESET}  ${TEXT_SECONDARY}|  Uptime: ${RESET}${BOLD}99.99%${RESET}"
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
