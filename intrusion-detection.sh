#!/bin/bash

# BlackRoad OS - Intrusion Detection System
# Real-time IDS alerts, attack patterns, and security monitoring

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
    echo -e "${BOLD}${RED}║${RESET}  ${ORANGE}🛡️${RESET}  ${BOLD}INTRUSION DETECTION SYSTEM${RESET}                                       ${BOLD}${RED}║${RESET}"
    echo -e "${BOLD}${RED}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Alert Summary
    echo -e "${TEXT_MUTED}╭─ ALERT SUMMARY ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}System Status:${RESET}      ${GREEN}●${RESET} ${BOLD}${GREEN}MONITORING${RESET}      ${TEXT_MUTED}Sensors: 12/12 online${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Alerts:${RESET}       ${BOLD}${RED}2,847${RESET}            ${TEXT_SECONDARY}today${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Critical:${RESET}           ${BOLD}${RED}23${RESET}               ${TEXT_SECONDARY}requiring immediate action${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Active Incidents:${RESET}   ${BOLD}${ORANGE}7${RESET}                ${TEXT_SECONDARY}under investigation${RESET}"
    echo ""

    # Severity Breakdown
    echo -e "${TEXT_MUTED}╭─ ALERTS BY SEVERITY ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${RED}Critical${RESET}    ${RED}████${RESET}                            23   ${TEXT_MUTED}0.8%${RESET}"
    echo -e "  ${ORANGE}High${RESET}        ${ORANGE}████████████${RESET}                    234  ${TEXT_MUTED}8.2%${RESET}"
    echo -e "  ${YELLOW}Medium${RESET}      ${YELLOW}████████████████████${RESET}            847  ${TEXT_MUTED}29.7%${RESET}"
    echo -e "  ${CYAN}Low${RESET}         ${CYAN}████████████████████████████${RESET}    1,743 ${TEXT_MUTED}61.3%${RESET}"
    echo ""

    # Critical Alerts
    echo -e "${TEXT_MUTED}╭─ CRITICAL ALERTS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${RED}🚨${RESET} ${BOLD}Ransomware Activity Detected${RESET}"
    echo -e "     ${TEXT_SECONDARY}Source: 192.168.47.18 → Target: File Server${RESET}"
    echo -e "     ${TEXT_MUTED}Pattern: WannaCry variant • Confidence: 98% • 2m ago${RESET}"
    echo ""
    echo -e "  ${RED}🚨${RESET} ${BOLD}SQL Injection Attempt${RESET}"
    echo -e "     ${TEXT_SECONDARY}Source: 10.234.89.123 → Target: Web App DB${RESET}"
    echo -e "     ${TEXT_MUTED}Attack: Boolean-based blind • Blocked • 8m ago${RESET}"
    echo ""
    echo -e "  ${RED}🚨${RESET} ${BOLD}Privilege Escalation${RESET}"
    echo -e "     ${TEXT_SECONDARY}User: admin@workstation-47 → Root access${RESET}"
    echo -e "     ${TEXT_MUTED}Method: Kernel exploit • Mitigated • 15m ago${RESET}"
    echo ""

    # Attack Types
    echo -e "${TEXT_MUTED}╭─ TOP ATTACK TYPES ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Type${RESET}                    ${RED}Count${RESET}     ${ORANGE}Blocked${RESET}    ${GREEN}Success Rate${RESET}"
    echo -e "  ${TEXT_MUTED}───────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}Brute Force${RESET}            ${RED}847${RESET}       ${ORANGE}842${RESET}        ${GREEN}99.4%${RESET}"
    echo -e "  ${BOLD}Port Scanning${RESET}          ${RED}623${RESET}       ${ORANGE}623${RESET}        ${GREEN}100%${RESET}"
    echo -e "  ${BOLD}SQL Injection${RESET}          ${RED}234${RESET}       ${ORANGE}233${RESET}        ${GREEN}99.6%${RESET}"
    echo -e "  ${BOLD}XSS Attack${RESET}             ${RED}156${RESET}       ${ORANGE}154${RESET}        ${GREEN}98.7%${RESET}"
    echo -e "  ${BOLD}DDoS${RESET}                   ${RED}89${RESET}        ${ORANGE}87${RESET}         ${GREEN}97.8%${RESET}"
    echo -e "  ${BOLD}Malware${RESET}                ${RED}47${RESET}        ${ORANGE}46${RESET}         ${GREEN}97.9%${RESET}"
    echo ""

    # Attack Sources
    echo -e "${TEXT_MUTED}╭─ ATTACK SOURCES ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}IP Address${RESET}              ${RED}Attacks${RESET}    ${ORANGE}Type${RESET}              ${PURPLE}Location${RESET}"
    echo -e "  ${TEXT_MUTED}────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}192.168.47.18${RESET}          ${RED}234${RESET}        ${ORANGE}Mixed${RESET}            ${PURPLE}🇨🇳 Beijing${RESET}"
    echo -e "  ${BOLD}10.234.89.123${RESET}          ${RED}156${RESET}        ${ORANGE}SQL Injection${RESET}    ${PURPLE}🇷🇺 Moscow${RESET}"
    echo -e "  ${BOLD}172.16.92.45${RESET}           ${RED}89${RESET}         ${ORANGE}Malware${RESET}          ${PURPLE}🇰🇵 Pyongyang${RESET}"
    echo -e "  ${BOLD}203.0.113.89${RESET}           ${RED}47${RESET}         ${ORANGE}DDoS${RESET}             ${PURPLE}🇺🇸 Dallas${RESET}"
    echo ""

    # Pattern Detection
    echo -e "${TEXT_MUTED}╭─ BEHAVIOR PATTERNS ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Coordinated Attack${RESET}     ${RED}Active${RESET}   ${TEXT_SECONDARY}12 IPs working in concert${RESET}"
    echo -e "  ${CYAN}●${RESET} ${BOLD}Reconnaissance${RESET}         ${ORANGE}Detected${RESET} ${TEXT_SECONDARY}Network mapping in progress${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}Lateral Movement${RESET}       ${RED}Alert${RESET}    ${TEXT_SECONDARY}Unusual internal traffic${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}Data Exfiltration${RESET}      ${YELLOW}Warning${RESET}  ${TEXT_SECONDARY}Large outbound transfers${RESET}"
    echo ""

    # Network Sensors
    echo -e "${TEXT_MUTED}╭─ NETWORK SENSORS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${BOLD}Gateway${RESET}          Events: ${CYAN}847/min${RESET}    Load: ${ORANGE}23%${RESET}     ${GREEN}✓ Healthy${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}DMZ${RESET}              Events: ${CYAN}623/min${RESET}    Load: ${ORANGE}18%${RESET}     ${GREEN}✓ Healthy${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}Internal${RESET}         Events: ${CYAN}234/min${RESET}    Load: ${ORANGE}12%${RESET}     ${GREEN}✓ Healthy${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}VPN${RESET}              Events: ${CYAN}89/min${RESET}     Load: ${ORANGE}8%${RESET}      ${GREEN}✓ Healthy${RESET}"
    echo ""

    # Real-time Events
    echo -e "${TEXT_MUTED}╭─ LIVE EVENT STREAM ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    local ts=$(date '+%H:%M:%S')
    echo -e "  ${RED}[${ts}] CRITICAL${RESET} Ransomware signature match: 192.168.47.18"
    echo -e "  ${ORANGE}[${ts}] HIGH${RESET}     SSH brute force: 10.234.89.123 (47 attempts)"
    echo -e "  ${YELLOW}[${ts}] MEDIUM${RESET}   Suspicious PowerShell: WORKSTATION-47"
    echo -e "  ${CYAN}[${ts}] LOW${RESET}      Port scan detected: 172.16.92.45"
    echo -e "  ${GREEN}[${ts}] INFO${RESET}     Signature database updated (v2.847)"
    echo ""

    # Response Actions
    echo -e "${TEXT_MUTED}╭─ AUTOMATED RESPONSES ─────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Blocked 192.168.47.18 for 24 hours${RESET}           ${TEXT_MUTED}Rule #234${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Isolated WORKSTATION-47 from network${RESET}         ${TEXT_MUTED}Quarantine${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Triggered incident response workflow${RESET}         ${TEXT_MUTED}IR-2847${RESET}"
    echo -e "  ${CYAN}⚡${RESET} ${TEXT_SECONDARY}Notified security team via Slack${RESET}             ${TEXT_MUTED}Alert sent${RESET}"
    echo ""

    # Footer
    echo -e "${RED}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}Last updated: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Engine: ${RESET}${BOLD}Snort + Suricata${RESET}  ${TEXT_SECONDARY}|  Rules: ${RESET}${BOLD}23,847${RESET}"
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
