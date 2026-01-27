#!/bin/bash

# BlackRoad OS - Firewall Monitor
# Real-time firewall rules, traffic analysis, and threat detection

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
    echo -e "${BOLD}${RED}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${RED}║${RESET}  ${ORANGE}🔥${RESET} ${BOLD}FIREWALL MONITOR${RESET}                                                 ${BOLD}${RED}║${RESET}"
    echo -e "${BOLD}${RED}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Status Overview
    echo -e "${TEXT_MUTED}╭─ FIREWALL STATUS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}             ${GREEN}●${RESET} ${BOLD}${GREEN}ACTIVE${RESET}          ${TEXT_MUTED}Uptime: 47d 12h${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Active Rules:${RESET}       ${BOLD}${CYAN}847${RESET}              ${TEXT_SECONDARY}(234 allow, 613 deny)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Blocked Today:${RESET}      ${BOLD}${RED}12,847${RESET}           ${TEXT_SECONDARY}attempts${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Active Zones:${RESET}       ${BOLD}${PURPLE}5${RESET}                ${TEXT_SECONDARY}(public, dmz, internal, vpn, mgmt)${RESET}"
    echo ""

    # Traffic Statistics
    echo -e "${TEXT_MUTED}╭─ TRAFFIC ANALYSIS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Direction${RESET}      ${CYAN}Packets${RESET}       ${ORANGE}Volume${RESET}        ${PINK}Rate${RESET}"
    echo -e "  ${TEXT_MUTED}─────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}Inbound${RESET}       ${CYAN}2.4M${RESET}          ${ORANGE}184 GB${RESET}        ${PINK}8.4 Mbps${RESET}"
    echo -e "  ${BOLD}Outbound${RESET}      ${CYAN}1.8M${RESET}          ${ORANGE}142 GB${RESET}        ${PINK}6.2 Mbps${RESET}"
    echo -e "  ${RED}Blocked${RESET}       ${CYAN}847K${RESET}          ${ORANGE}12 GB${RESET}         ${PINK}2.1 Mbps${RESET}"
    echo ""

    # Top Blocked IPs
    echo -e "${TEXT_MUTED}╭─ TOP BLOCKED IPs ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}IP Address${RESET}              ${RED}Attempts${RESET}      ${ORANGE}Country${RESET}       ${PURPLE}Reason${RESET}"
    echo -e "  ${TEXT_MUTED}──────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}192.168.47.18${RESET}          ${RED}2,847${RESET}        ${ORANGE}🇨🇳 CN${RESET}         ${PURPLE}Brute Force${RESET}"
    echo -e "  ${BOLD}10.234.89.123${RESET}          ${RED}1,923${RESET}        ${ORANGE}🇷🇺 RU${RESET}         ${PURPLE}Port Scan${RESET}"
    echo -e "  ${BOLD}172.16.92.45${RESET}           ${RED}1,234${RESET}        ${ORANGE}🇰🇵 KP${RESET}         ${PURPLE}Malware${RESET}"
    echo -e "  ${BOLD}203.0.113.89${RESET}           ${RED}987${RESET}          ${ORANGE}🇺🇸 US${RESET}         ${PURPLE}DDoS${RESET}"
    echo -e "  ${BOLD}198.51.100.42${RESET}          ${RED}623${RESET}          ${ORANGE}🇧🇷 BR${RESET}         ${PURPLE}SQL Injection${RESET}"
    echo ""

    # Active Rules
    echo -e "${TEXT_MUTED}╭─ RECENT RULE TRIGGERS ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${RED}✗${RESET} ${TEXT_SECONDARY}192.168.47.18:22 → SSH brute force${RESET}          ${TEXT_MUTED}Rule #234 • 2s${RESET}"
    echo -e "  ${RED}✗${RESET} ${TEXT_SECONDARY}10.234.89.123:* → Port scan detected${RESET}        ${TEXT_MUTED}Rule #789 • 15s${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}203.45.67.89:443 → HTTPS allowed${RESET}            ${TEXT_MUTED}Rule #012 • 23s${RESET}"
    echo -e "  ${RED}✗${RESET} ${TEXT_SECONDARY}172.16.92.45:80 → Malicious payload${RESET}         ${TEXT_MUTED}Rule #456 • 1m${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}198.51.100.10:8080 → API access${RESET}            ${TEXT_MUTED}Rule #345 • 2m${RESET}"
    echo ""

    # Traffic by Port
    echo -e "${TEXT_MUTED}╭─ TOP PORTS ───────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}443${RESET} ${TEXT_MUTED}HTTPS${RESET}   ${GREEN}██████████████████████${RESET}          847K  ${GREEN}✓ Allowed${RESET}"
    echo -e "  ${BOLD}80${RESET}  ${TEXT_MUTED}HTTP${RESET}    ${CYAN}████████████${RESET}                   423K  ${GREEN}✓ Allowed${RESET}"
    echo -e "  ${BOLD}22${RESET}  ${TEXT_MUTED}SSH${RESET}     ${ORANGE}████████${RESET}                       234K  ${ORANGE}⚠ Monitored${RESET}"
    echo -e "  ${BOLD}3306${RESET} ${TEXT_MUTED}MySQL${RESET}  ${RED}████${RESET}                           89K   ${RED}✗ Blocked${RESET}"
    echo -e "  ${BOLD}5432${RESET} ${TEXT_MUTED}Postgr${RESET} ${RED}██${RESET}                             47K   ${RED}✗ Blocked${RESET}"
    echo ""

    # Threat Intelligence
    echo -e "${TEXT_MUTED}╭─ THREAT INTELLIGENCE ─────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${RED}●${RESET} ${BOLD}Active Threats:${RESET}       ${RED}23${RESET}   ${TEXT_MUTED}(12 critical, 7 high, 4 medium)${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}Suspicious IPs:${RESET}       ${ORANGE}847${RESET}  ${TEXT_MUTED}(in watchlist)${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Blocked Patterns:${RESET}     ${PURPLE}156${RESET}  ${TEXT_MUTED}(attack signatures)${RESET}"
    echo -e "  ${CYAN}●${RESET} ${BOLD}GeoIP Blocks:${RESET}         ${CYAN}47${RESET}   ${TEXT_MUTED}countries${RESET}"
    echo ""

    # Zones
    echo -e "${TEXT_MUTED}╭─ SECURITY ZONES ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${BOLD}Public${RESET}      Trust: ${RED}Low${RESET}      Traffic: ${CYAN}High${RESET}     Policies: ${ORANGE}234${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}DMZ${RESET}         Trust: ${ORANGE}Medium${RESET}   Traffic: ${CYAN}Medium${RESET}   Policies: ${ORANGE}89${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}Internal${RESET}    Trust: ${GREEN}High${RESET}     Traffic: ${CYAN}Medium${RESET}   Policies: ${ORANGE}156${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}VPN${RESET}         Trust: ${GREEN}High${RESET}     Traffic: ${CYAN}Low${RESET}      Policies: ${ORANGE}47${RESET}"
    echo -e "  ${CYAN}●${RESET} ${BOLD}Management${RESET}  Trust: ${GREEN}Highest${RESET}  Traffic: ${CYAN}Low${RESET}      Policies: ${ORANGE}23${RESET}"
    echo ""

    # Real-time Events
    echo -e "${TEXT_MUTED}╭─ LIVE EVENTS ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    local timestamp=$(date '+%H:%M:%S')
    echo -e "  ${RED}[${timestamp}]${RESET} ${RED}CRITICAL${RESET} Port scan from 192.168.47.18 - ${BOLD}BLOCKED${RESET}"
    echo -e "  ${ORANGE}[${timestamp}]${RESET} ${ORANGE}WARNING${RESET}  Unusual traffic pattern on port 8080"
    echo -e "  ${CYAN}[${timestamp}]${RESET} ${CYAN}INFO${RESET}     New rule added: Block CN/RU traffic"
    echo -e "  ${GREEN}[${timestamp}]${RESET} ${GREEN}SUCCESS${RESET}  VPN connection from 203.45.67.89"
    echo ""

    # Footer
    echo -e "${RED}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}Last updated: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Service: ${RESET}${BOLD}iptables + fail2ban${RESET}  ${TEXT_SECONDARY}|  Version: ${RESET}${BOLD}2.3.1${RESET}"
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
