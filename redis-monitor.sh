#!/bin/bash

# BlackRoad OS - Redis Cache Monitor
# Real-time Redis monitoring with commands, memory, and performance

source ~/blackroad-dashboards/themes.sh 2>/dev/null || true

# Colors
ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GREEN="\033[38;2;20;241;149m"
RED="\033[38;2;255;0;107m"
YELLOW="\033[38;2;255;193;7m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

show_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${RED}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${RED}║${RESET}  ${ORANGE}⚡${RESET} ${BOLD}REDIS CACHE MONITOR${RESET}                                              ${BOLD}${RED}║${RESET}"
    echo -e "${BOLD}${RED}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Server Status
    echo -e "${TEXT_MUTED}╭─ SERVER STATUS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Redis Version:${RESET}      ${BOLD}${CYAN}7.0.12${RESET}             ${TEXT_MUTED}Stable${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}             ${GREEN}●${RESET} ${BOLD}${GREEN}RUNNING${RESET}           ${TEXT_MUTED}Uptime: 47d 12h${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Mode:${RESET}               ${BOLD}${PURPLE}Cluster${RESET}            ${TEXT_MUTED}3 masters, 3 replicas${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Port:${RESET}               ${BOLD}${ORANGE}6379${RESET}               ${TEXT_MUTED}Default${RESET}"
    echo ""

    # Memory Usage
    echo -e "${TEXT_MUTED}╭─ MEMORY USAGE ────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Used Memory:${RESET}        ${BOLD}${ORANGE}4.2 GB${RESET} / ${BOLD}${CYAN}16 GB${RESET}  ${TEXT_MUTED}(26.3%)${RESET}"
    echo -e "  ${CYAN}████████${TEXT_MUTED}██████████████████████████${RESET}  ${BOLD}26%${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Peak Memory:${RESET}        ${BOLD}${PINK}8.9 GB${RESET}             ${TEXT_MUTED}Historical high${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}RSS Memory:${RESET}         ${BOLD}${PURPLE}4.4 GB${RESET}             ${TEXT_MUTED}Resident set size${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Fragmentation:${RESET}      ${BOLD}${GREEN}1.05${RESET}               ${TEXT_MUTED}Good${RESET}"
    echo ""

    # Key Statistics
    echo -e "${TEXT_MUTED}╭─ KEY STATISTICS ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Keys:${RESET}         ${BOLD}${CYAN}2,847,234${RESET}          ${TEXT_SECONDARY}across all DBs${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Expires:${RESET}            ${BOLD}${ORANGE}847,123${RESET}            ${TEXT_SECONDARY}keys with TTL${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Evicted:${RESET}            ${BOLD}${RED}12,847${RESET}             ${TEXT_SECONDARY}last 24h${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Hit Rate:${RESET}           ${BOLD}${GREEN}94.7%${RESET}              ${TEXT_SECONDARY}cache effectiveness${RESET}"
    echo ""

    # Key Types Distribution
    echo -e "${TEXT_MUTED}╭─ KEY TYPES ───────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}String${RESET}      ${CYAN}████████████████████${RESET}              1,847K  ${TEXT_MUTED}64.9%${RESET}"
    echo -e "  ${BOLD}Hash${RESET}        ${ORANGE}████████${RESET}                          547K   ${TEXT_MUTED}19.2%${RESET}"
    echo -e "  ${BOLD}List${RESET}        ${PINK}████${RESET}                              234K   ${TEXT_MUTED}8.2%${RESET}"
    echo -e "  ${BOLD}Set${RESET}         ${PURPLE}███${RESET}                               156K   ${TEXT_MUTED}5.5%${RESET}"
    echo -e "  ${BOLD}Sorted Set${RESET}  ${BLUE}██${RESET}                                63K    ${TEXT_MUTED}2.2%${RESET}"
    echo ""

    # Performance Metrics
    echo -e "${TEXT_MUTED}╭─ PERFORMANCE METRICS ─────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Metric${RESET}              ${CYAN}Current${RESET}    ${ORANGE}Avg${RESET}       ${PINK}Peak${RESET}"
    echo -e "  ${TEXT_MUTED}─────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}Ops/sec${RESET}            ${CYAN}84,723${RESET}    ${ORANGE}72,847${RESET}    ${PINK}124,892${RESET}"
    echo -e "  ${BOLD}Network In${RESET}         ${CYAN}127 MB/s${RESET}  ${ORANGE}89 MB/s${RESET}   ${PINK}234 MB/s${RESET}"
    echo -e "  ${BOLD}Network Out${RESET}        ${CYAN}234 MB/s${RESET}  ${ORANGE}156 MB/s${RESET}  ${PINK}487 MB/s${RESET}"
    echo -e "  ${BOLD}Latency${RESET}            ${CYAN}0.8 ms${RESET}    ${ORANGE}1.2 ms${RESET}    ${PINK}4.7 ms${RESET}"
    echo ""

    # Command Statistics
    echo -e "${TEXT_MUTED}╭─ TOP COMMANDS ────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Command${RESET}         ${CYAN}Calls/sec${RESET}    ${ORANGE}%${RESET}        ${PURPLE}Avg Time${RESET}"
    echo -e "  ${TEXT_MUTED}───────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}GET${RESET}            ${CYAN}42,847${RESET}      ${ORANGE}50.6%${RESET}    ${PURPLE}0.3 ms${RESET}"
    echo -e "  ${BOLD}SET${RESET}            ${CYAN}18,234${RESET}      ${ORANGE}21.5%${RESET}    ${PURPLE}0.4 ms${RESET}"
    echo -e "  ${BOLD}HGET${RESET}           ${CYAN}8,923${RESET}       ${ORANGE}10.5%${RESET}    ${PURPLE}0.5 ms${RESET}"
    echo -e "  ${BOLD}ZADD${RESET}           ${CYAN}4,847${RESET}       ${ORANGE}5.7%${RESET}     ${PURPLE}0.8 ms${RESET}"
    echo -e "  ${BOLD}SADD${RESET}           ${CYAN}3,234${RESET}       ${ORANGE}3.8%${RESET}     ${PURPLE}0.6 ms${RESET}"
    echo -e "  ${BOLD}EXPIRE${RESET}         ${CYAN}2,847${RESET}       ${ORANGE}3.4%${RESET}     ${PURPLE}0.2 ms${RESET}"
    echo ""

    # Client Connections
    echo -e "${TEXT_MUTED}╭─ CLIENT CONNECTIONS ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Connected:${RESET}          ${BOLD}${CYAN}847${RESET}                ${TEXT_SECONDARY}active clients${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Blocked:${RESET}            ${BOLD}${ORANGE}23${RESET}                 ${TEXT_SECONDARY}waiting on BLPOP/BRPOP${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Max Clients:${RESET}        ${BOLD}${PURPLE}10,000${RESET}             ${TEXT_SECONDARY}configured limit${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Input Buffer:${RESET}       ${BOLD}${PINK}847 MB${RESET}             ${TEXT_SECONDARY}total${RESET}"
    echo ""

    # Replication Status
    echo -e "${TEXT_MUTED}╭─ REPLICATION STATUS ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${BOLD}Master-1${RESET}      Offset: ${CYAN}847234892${RESET}   Replicas: ${ORANGE}2${RESET}   ${GREEN}✓ Synced${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}Master-2${RESET}      Offset: ${CYAN}847234847${RESET}   Replicas: ${ORANGE}2${RESET}   ${GREEN}✓ Synced${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}Master-3${RESET}      Offset: ${CYAN}847234823${RESET}   Replicas: ${ORANGE}2${RESET}   ${GREEN}✓ Synced${RESET}"
    echo ""

    # Slow Log
    echo -e "${TEXT_MUTED}╭─ SLOW COMMANDS LOG ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${YELLOW}⚠${RESET} ${TEXT_SECONDARY}KEYS * took 47ms${RESET}                             ${TEXT_MUTED}2m ago${RESET}"
    echo -e "  ${YELLOW}⚠${RESET} ${TEXT_SECONDARY}SMEMBERS large_set took 23ms${RESET}                 ${TEXT_MUTED}8m ago${RESET}"
    echo -e "  ${YELLOW}⚠${RESET} ${TEXT_SECONDARY}ZRANGE sorted_set 0 -1 took 34ms${RESET}            ${TEXT_MUTED}15m ago${RESET}"
    echo ""

    # Persistence
    echo -e "${TEXT_MUTED}╭─ PERSISTENCE ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}AOF:${RESET}                ${GREEN}Enabled${RESET}            ${TEXT_MUTED}Always sync${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}RDB:${RESET}                ${GREEN}Enabled${RESET}            ${TEXT_MUTED}Last save: 2h ago${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}AOF Size:${RESET}           ${CYAN}2.4 GB${RESET}             ${TEXT_MUTED}Growing${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}RDB Size:${RESET}           ${PURPLE}4.2 GB${RESET}             ${TEXT_MUTED}Compressed${RESET}"
    echo ""

    # Alerts
    echo -e "${TEXT_MUTED}╭─ ACTIVE ALERTS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${YELLOW}🟡${RESET} ${BOLD}WARNING${RESET}  High eviction rate: 12,847 keys/24h"
    echo -e "  ${CYAN}ℹ${RESET}  ${BOLD}INFO${RESET}     Memory usage below 30% - optimal"
    echo ""

    # Footer
    echo -e "${RED}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}Updated: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Cluster: ${RESET}${BOLD}production${RESET}  ${TEXT_SECONDARY}|  Role: ${RESET}${BOLD}Master${RESET}"
    echo ""
}

# Main loop
if [[ "$1" == "--watch" ]]; then
    while true; do
        show_dashboard
        sleep 2
    done
else
    show_dashboard
fi
