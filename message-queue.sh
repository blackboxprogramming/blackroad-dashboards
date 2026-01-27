#!/bin/bash

# BlackRoad OS - Message Queue Dashboard
# Monitor RabbitMQ/Kafka message queues with throughput and consumer metrics

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
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${PURPLE}📨${RESET} ${BOLD}MESSAGE QUEUE DASHBOARD${RESET}                                          ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Cluster Status
    echo -e "${TEXT_MUTED}╭─ CLUSTER STATUS ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Broker:${RESET}             ${BOLD}${CYAN}RabbitMQ 3.12${RESET}      ${TEXT_MUTED}+ Kafka 3.5${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}             ${GREEN}●${RESET} ${BOLD}${GREEN}RUNNING${RESET}           ${TEXT_MUTED}All nodes healthy${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Nodes:${RESET}              ${BOLD}${ORANGE}5${RESET} / ${BOLD}${GREEN}5${RESET} Active      ${TEXT_MUTED}Cluster mode${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Uptime:${RESET}             ${BOLD}${PURPLE}47d 12h${RESET}            ${TEXT_MUTED}Since last restart${RESET}"
    echo ""

    # Queue Overview
    echo -e "${TEXT_MUTED}╭─ QUEUE OVERVIEW ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Queues:${RESET}       ${BOLD}${CYAN}47${RESET}                 ${TEXT_SECONDARY}across all vhosts${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Messages:${RESET}           ${BOLD}${ORANGE}2,847,234${RESET}          ${TEXT_SECONDARY}total in queues${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Ready:${RESET}              ${BOLD}${GREEN}1,847,123${RESET}          ${TEXT_SECONDARY}available${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Unacked:${RESET}            ${BOLD}${YELLOW}1,000,111${RESET}          ${TEXT_SECONDARY}processing${RESET}"
    echo ""

    # Throughput
    echo -e "${TEXT_MUTED}╭─ THROUGHPUT METRICS ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Metric${RESET}              ${CYAN}Current${RESET}        ${ORANGE}Peak${RESET}          ${PINK}Avg${RESET}"
    echo -e "  ${TEXT_MUTED}───────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}Publish/sec${RESET}        ${CYAN}8,473${RESET}         ${ORANGE}12,847${RESET}       ${PINK}7,234${RESET}"
    echo -e "  ${BOLD}Consume/sec${RESET}        ${CYAN}8,234${RESET}         ${ORANGE}11,923${RESET}       ${PINK}7,089${RESET}"
    echo -e "  ${BOLD}Ack/sec${RESET}            ${CYAN}8,123${RESET}         ${ORANGE}11,847${RESET}       ${PINK}7,012${RESET}"
    echo -e "  ${BOLD}Throughput${RESET}         ${CYAN}847 MB/s${RESET}      ${ORANGE}1.2 GB/s${RESET}     ${PINK}623 MB/s${RESET}"
    echo ""

    # Message Rate
    echo -e "${TEXT_MUTED}╭─ MESSAGE RATE (LAST HOUR) ────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}Publish${RESET}     ${GREEN}▁▂▃▄▅▆▇█▇▆▅▄▃▂▁${RESET}           ${BOLD}8,473/s${RESET}"
    echo -e "  ${CYAN}Consume${RESET}     ${CYAN}▁▂▃▄▅▆▇█▇▆▅▄▃▂▁${RESET}           ${BOLD}8,234/s${RESET}"
    echo -e "  ${ORANGE}Deliver${RESET}     ${ORANGE}▁▂▃▄▅▆▇█▇▆▅▄▃▂▁${RESET}           ${BOLD}8,456/s${RESET}"
    echo ""

    # Top Queues
    echo -e "${TEXT_MUTED}╭─ TOP QUEUES ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Queue${RESET}                   ${CYAN}Messages${RESET}    ${ORANGE}Rate${RESET}      ${PINK}Consumers${RESET}"
    echo -e "  ${TEXT_MUTED}──────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}order-processing${RESET}       ${CYAN}847K${RESET}        ${ORANGE}2.4K/s${RESET}   ${PINK}12${RESET}"
    echo -e "  ${BOLD}email-queue${RESET}            ${CYAN}234K${RESET}        ${ORANGE}847/s${RESET}    ${PINK}8${RESET}"
    echo -e "  ${BOLD}webhook-events${RESET}         ${CYAN}156K${RESET}        ${ORANGE}623/s${RESET}    ${PINK}6${RESET}"
    echo -e "  ${BOLD}notification-push${RESET}      ${CYAN}89K${RESET}         ${ORANGE}423/s${RESET}    ${PINK}4${RESET}"
    echo -e "  ${BOLD}data-sync${RESET}              ${CYAN}47K${RESET}         ${ORANGE}234/s${RESET}    ${PINK}3${RESET}"
    echo ""

    # Consumer Status
    echo -e "${TEXT_MUTED}╭─ CONSUMER STATUS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Consumers:${RESET}    ${BOLD}${CYAN}47${RESET}                 ${TEXT_SECONDARY}active${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Healthy:${RESET}            ${BOLD}${GREEN}44${RESET}                 ${TEXT_SECONDARY}processing normally${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Slow:${RESET}               ${BOLD}${YELLOW}2${RESET}                  ${TEXT_SECONDARY}lagging behind${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Stalled:${RESET}            ${BOLD}${RED}1${RESET}                  ${TEXT_SECONDARY}not responding${RESET}"
    echo ""

    # Queue Details
    echo -e "${TEXT_MUTED}╭─ QUEUE HEALTH ────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${BOLD}order-processing${RESET}    Load: ${CYAN}84%${RESET}   Lag: ${ORANGE}2.3s${RESET}   ${GREEN}✓ Healthy${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}email-queue${RESET}         Load: ${CYAN}67%${RESET}   Lag: ${ORANGE}1.2s${RESET}   ${GREEN}✓ Healthy${RESET}"
    echo -e "  ${YELLOW}●${RESET} ${BOLD}webhook-events${RESET}      Load: ${CYAN}92%${RESET}   Lag: ${ORANGE}4.7s${RESET}   ${YELLOW}⚠ High${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}notification-push${RESET}   Load: ${CYAN}54%${RESET}   Lag: ${ORANGE}0.8s${RESET}   ${GREEN}✓ Healthy${RESET}"
    echo ""

    # Dead Letter Queues
    echo -e "${TEXT_MUTED}╭─ DEAD LETTER QUEUES ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Queue${RESET}                   ${RED}Failed${RESET}      ${ORANGE}Last 24h${RESET}"
    echo -e "  ${TEXT_MUTED}──────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}order-dlq${RESET}              ${RED}234${RESET}         ${ORANGE}+47${RESET}"
    echo -e "  ${BOLD}email-dlq${RESET}              ${RED}89${RESET}          ${ORANGE}+12${RESET}"
    echo -e "  ${BOLD}webhook-dlq${RESET}            ${RED}47${RESET}          ${ORANGE}+8${RESET}"
    echo ""

    # Message Age
    echo -e "${TEXT_MUTED}╭─ MESSAGE AGE DISTRIBUTION ────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}< 1s${RESET}        ${GREEN}███████████████████████████${RESET}        1.8M  ${TEXT_MUTED}63.2%${RESET}"
    echo -e "  ${CYAN}1-10s${RESET}       ${CYAN}████████████${RESET}                       687K  ${TEXT_MUTED}24.1%${RESET}"
    echo -e "  ${ORANGE}10-60s${RESET}      ${ORANGE}█████${RESET}                              234K  ${TEXT_MUTED}8.2%${RESET}"
    echo -e "  ${RED}> 60s${RESET}       ${RED}███${RESET}                                127K  ${TEXT_MUTED}4.5%${RESET}"
    echo ""

    # Connection Pool
    echo -e "${TEXT_MUTED}╭─ CONNECTIONS ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total:${RESET}              ${BOLD}${CYAN}234${RESET}                ${TEXT_SECONDARY}active connections${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Publishers:${RESET}         ${BOLD}${ORANGE}89${RESET}                 ${TEXT_SECONDARY}sending messages${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Consumers:${RESET}          ${BOLD}${PURPLE}145${RESET}                ${TEXT_SECONDARY}receiving messages${RESET}"
    echo ""

    # Recent Activity
    echo -e "${TEXT_MUTED}╭─ RECENT EVENTS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Consumer connected to webhook-events${RESET}       ${TEXT_MUTED}worker-3 • 2m${RESET}"
    echo -e "  ${YELLOW}⚠${RESET} ${TEXT_SECONDARY}Queue webhook-events high load (92%)${RESET}      ${TEXT_MUTED}warning • 5m${RESET}"
    echo -e "  ${RED}✗${RESET} ${TEXT_SECONDARY}Consumer disconnected from email-queue${RESET}     ${TEXT_MUTED}worker-8 • 8m${RESET}"
    echo -e "  ${CYAN}ℹ${RESET} ${TEXT_SECONDARY}Queue order-processing scaled to 12 workers${RESET} ${TEXT_MUTED}auto-scale • 15m${RESET}"
    echo ""

    # Performance
    echo -e "${TEXT_MUTED}╭─ PERFORMANCE ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Avg Latency:${RESET}        ${BOLD}${GREEN}1.2 ms${RESET}             ${TEXT_SECONDARY}message delivery${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}P95 Latency:${RESET}        ${BOLD}${CYAN}4.7 ms${RESET}             ${TEXT_SECONDARY}95th percentile${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}P99 Latency:${RESET}        ${BOLD}${ORANGE}12.4 ms${RESET}            ${TEXT_SECONDARY}99th percentile${RESET}"
    echo ""

    # Footer
    echo -e "${ORANGE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}Updated: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Cluster: ${RESET}${BOLD}production${RESET}  ${TEXT_SECONDARY}|  VHost: ${RESET}${BOLD}/app${RESET}"
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
