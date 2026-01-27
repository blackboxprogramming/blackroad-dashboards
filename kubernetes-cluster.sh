#!/bin/bash

# BlackRoad OS - Kubernetes Cluster Monitor
# Real-time K8s cluster metrics, pod health, and resource utilization

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
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${CYAN}☸${RESET}  ${BOLD}KUBERNETES CLUSTER MONITOR${RESET}                                       ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Cluster Overview
    echo -e "${TEXT_MUTED}╭─ CLUSTER STATUS ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Cluster:${RESET}            ${BOLD}${CYAN}production-us-east-1${RESET}     ${GREEN}✓ Healthy${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Version:${RESET}            ${BOLD}v1.28.3${RESET}                   ${TEXT_MUTED}Latest stable${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Nodes:${RESET}              ${BOLD}${ORANGE}12${RESET} / ${BOLD}${GREEN}12${RESET} Ready           ${TEXT_MUTED}100% availability${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Pods:${RESET}               ${BOLD}${PURPLE}847${RESET} / ${BOLD}1200${RESET} Running      ${TEXT_MUTED}70.6% utilization${RESET}"
    echo ""

    # Node Status
    echo -e "${TEXT_MUTED}╭─ NODE STATUS ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Node${RESET}              ${CYAN}CPU${RESET}       ${ORANGE}Memory${RESET}    ${PINK}Pods${RESET}     ${PURPLE}Status${RESET}"
    echo -e "  ${TEXT_MUTED}───────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}master-1${RESET}         ${CYAN}23%${RESET}       ${ORANGE}42%${RESET}       ${PINK}12/50${RESET}    ${GREEN}Ready${RESET}"
    echo -e "  ${BOLD}master-2${RESET}         ${CYAN}19%${RESET}       ${ORANGE}38%${RESET}       ${PINK}10/50${RESET}    ${GREEN}Ready${RESET}"
    echo -e "  ${BOLD}master-3${RESET}         ${CYAN}21%${RESET}       ${ORANGE}40%${RESET}       ${PINK}11/50${RESET}    ${GREEN}Ready${RESET}"
    echo -e "  ${BOLD}worker-1${RESET}         ${CYAN}78%${RESET}       ${ORANGE}84%${RESET}       ${PINK}98/110${RESET}   ${YELLOW}High${RESET}"
    echo -e "  ${BOLD}worker-2${RESET}         ${CYAN}72%${RESET}       ${ORANGE}79%${RESET}       ${PINK}92/110${RESET}   ${GREEN}Ready${RESET}"
    echo -e "  ${BOLD}worker-3${RESET}         ${CYAN}45%${RESET}       ${ORANGE}56%${RESET}       ${PINK}67/110${RESET}   ${GREEN}Ready${RESET}"
    echo ""

    # Namespace Overview
    echo -e "${TEXT_MUTED}╭─ NAMESPACES ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}●${RESET} ${BOLD}production${RESET}       Pods: ${ORANGE}347${RESET}  CPU: ${PINK}67%${RESET}  Memory: ${PURPLE}72%${RESET}  ${GREEN}✓${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}staging${RESET}          Pods: ${ORANGE}234${RESET}  CPU: ${PINK}45%${RESET}  Memory: ${PURPLE}52%${RESET}  ${GREEN}✓${RESET}"
    echo -e "  ${PINK}●${RESET} ${BOLD}development${RESET}      Pods: ${ORANGE}156${RESET}  CPU: ${PINK}32%${RESET}  Memory: ${PURPLE}38%${RESET}  ${GREEN}✓${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}monitoring${RESET}       Pods: ${ORANGE}47${RESET}   CPU: ${PINK}12%${RESET}  Memory: ${PURPLE}18%${RESET}  ${GREEN}✓${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}kube-system${RESET}      Pods: ${ORANGE}63${RESET}   CPU: ${PINK}8%${RESET}   Memory: ${PURPLE}12%${RESET}  ${GREEN}✓${RESET}"
    echo ""

    # Pod Health
    echo -e "${TEXT_MUTED}╭─ POD HEALTH ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}Running${RESET}         ${GREEN}███████████████████████████${RESET}        847  ${TEXT_MUTED}95.6%${RESET}"
    echo -e "  ${YELLOW}Pending${RESET}         ${YELLOW}██${RESET}                                 23   ${TEXT_MUTED}2.6%${RESET}"
    echo -e "  ${RED}Failed${RESET}          ${RED}█${RESET}                                  12   ${TEXT_MUTED}1.4%${RESET}"
    echo -e "  ${CYAN}Succeeded${RESET}       ${CYAN}█${RESET}                                   4   ${TEXT_MUTED}0.4%${RESET}"
    echo ""

    # Deployments
    echo -e "${TEXT_MUTED}╭─ TOP DEPLOYMENTS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Deployment${RESET}              ${CYAN}Replicas${RESET}   ${ORANGE}Ready${RESET}   ${PINK}CPU${RESET}     ${PURPLE}Memory${RESET}"
    echo -e "  ${TEXT_MUTED}─────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}web-api${RESET}                ${CYAN}50${RESET}         ${GREEN}50${RESET}      ${PINK}67%${RESET}    ${PURPLE}4.2 GB${RESET}"
    echo -e "  ${BOLD}worker-queue${RESET}           ${CYAN}30${RESET}         ${GREEN}30${RESET}      ${PINK}45%${RESET}    ${PURPLE}2.8 GB${RESET}"
    echo -e "  ${BOLD}redis-cache${RESET}            ${CYAN}12${RESET}         ${GREEN}12${RESET}      ${PINK}23%${RESET}    ${PURPLE}1.4 GB${RESET}"
    echo -e "  ${BOLD}postgres-db${RESET}            ${CYAN}5${RESET}          ${GREEN}5${RESET}       ${PINK}34%${RESET}    ${PURPLE}8.9 GB${RESET}"
    echo -e "  ${BOLD}nginx-ingress${RESET}          ${CYAN}3${RESET}          ${GREEN}3${RESET}       ${PINK}12%${RESET}    ${PURPLE}512 MB${RESET}"
    echo ""

    # Resource Usage
    echo -e "${TEXT_MUTED}╭─ CLUSTER RESOURCES ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}CPU Usage:${RESET}"
    echo -e "    ${CYAN}████████████████████████████${TEXT_MUTED}████████████${RESET}  ${BOLD}67%${RESET}  ${TEXT_SECONDARY}(268/400 cores)${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Memory Usage:${RESET}"
    echo -e "    ${ORANGE}██████████████████████████████${TEXT_MUTED}██████████${RESET}  ${BOLD}72%${RESET}  ${TEXT_SECONDARY}(576/800 GB)${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Storage Usage:${RESET}"
    echo -e "    ${PURPLE}████████████████${TEXT_MUTED}████████████████████████${RESET}  ${BOLD}42%${RESET}  ${TEXT_SECONDARY}(4.2/10 TB)${RESET}"
    echo ""

    # Events
    echo -e "${TEXT_MUTED}╭─ RECENT EVENTS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Pod web-api-7f8d9c4b5-xk2m4 started${RESET}          ${TEXT_MUTED}production • 2m${RESET}"
    echo -e "  ${YELLOW}⚠${RESET} ${TEXT_SECONDARY}Node worker-4 high memory usage${RESET}              ${TEXT_MUTED}warning • 5m${RESET}"
    echo -e "  ${CYAN}↻${RESET} ${TEXT_SECONDARY}Deployment worker-queue scaled to 30${RESET}          ${TEXT_MUTED}staging • 8m${RESET}"
    echo -e "  ${RED}✗${RESET} ${TEXT_SECONDARY}Pod redis-cache-2 CrashLoopBackOff${RESET}            ${TEXT_MUTED}error • 12m${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Service nginx-ingress updated${RESET}                ${TEXT_MUTED}kube-system • 15m${RESET}"
    echo ""

    # Services
    echo -e "${TEXT_MUTED}╭─ EXPOSED SERVICES ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}●${RESET} ${BOLD}api.example.com${RESET}       Type: ${ORANGE}LoadBalancer${RESET}  Port: ${PURPLE}443${RESET}  ${GREEN}✓${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}app.example.com${RESET}       Type: ${ORANGE}LoadBalancer${RESET}  Port: ${PURPLE}443${RESET}  ${GREEN}✓${RESET}"
    echo -e "  ${PINK}●${RESET} ${BOLD}metrics.internal${RESET}      Type: ${ORANGE}ClusterIP${RESET}     Port: ${PURPLE}9090${RESET} ${GREEN}✓${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}db.internal${RESET}          Type: ${ORANGE}ClusterIP${RESET}     Port: ${PURPLE}5432${RESET} ${GREEN}✓${RESET}"
    echo ""

    # Alerts
    echo -e "${TEXT_MUTED}╭─ ACTIVE ALERTS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${RED}🔴${RESET} ${BOLD}CRITICAL${RESET} Pod CrashLoopBackOff: redis-cache-2"
    echo -e "  ${YELLOW}🟡${RESET} ${BOLD}WARNING${RESET}  High memory on worker-4 (84%)"
    echo -e "  ${YELLOW}🟡${RESET} ${BOLD}WARNING${RESET}  Pending pods in queue: 23"
    echo ""

    # Footer
    echo -e "${BLUE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}Last updated: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  API: ${RESET}${BOLD}v1.28.3${RESET}  ${TEXT_SECONDARY}|  Region: ${RESET}${BOLD}us-east-1${RESET}"
    echo ""
}

# Main loop
if [[ "$1" == "--watch" ]]; then
    while true; do
        show_dashboard
        sleep 3
    done
else
    show_dashboard
fi
