#!/bin/bash

# BlackRoad OS - Timeline Visualizer
# Visualize events, milestones, and project timelines

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
    echo -e "${BOLD}${PURPLE}║${RESET}  ${CYAN}📅${RESET} ${BOLD}PROJECT TIMELINE${RESET}                                                 ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Project Overview
    echo -e "${TEXT_MUTED}╭─ PROJECT: BlackRoad OS v2.0 ──────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Start Date:${RESET}         ${BOLD}${CYAN}Jan 1, 2026${RESET}        ${TEXT_MUTED}6 months ago${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Target Date:${RESET}        ${BOLD}${ORANGE}Dec 31, 2026${RESET}      ${TEXT_MUTED}5 months remaining${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Progress:${RESET}           ${BOLD}${GREEN}54.7%${RESET}              ${TEXT_MUTED}On track${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Milestones:${RESET}         ${BOLD}${PURPLE}12${RESET} / ${BOLD}${PINK}22${RESET}          ${TEXT_MUTED}6 completed, 6 active, 10 upcoming${RESET}"
    echo ""

    # Timeline
    echo -e "${TEXT_MUTED}╭─ TIMELINE ────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}2026${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}"
    echo -e "  ${GREEN}●${RESET}${TEXT_MUTED}─${RESET} ${BOLD}Jan${RESET}  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Project Kickoff${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}      ${GREEN}✓${RESET} ${TEXT_SECONDARY}Requirements Gathering${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}"
    echo -e "  ${GREEN}●${RESET}${TEXT_MUTED}─${RESET} ${BOLD}Feb${RESET}  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Design Phase Complete${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}      ${GREEN}✓${RESET} ${TEXT_SECONDARY}Architecture Finalized${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}"
    echo -e "  ${GREEN}●${RESET}${TEXT_MUTED}─${RESET} ${BOLD}Mar${RESET}  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Core Module Development${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}      ${GREEN}✓${RESET} ${TEXT_SECONDARY}API Endpoints Created${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}"
    echo -e "  ${CYAN}●${RESET}${TEXT_MUTED}─${RESET} ${BOLD}Apr${RESET}  ${CYAN}◐${RESET} ${TEXT_SECONDARY}Feature Implementation${RESET}        ${ORANGE}(in progress)${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}      ${GREEN}✓${RESET} ${TEXT_SECONDARY}AI Integration${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}"
    echo -e "  ${CYAN}●${RESET}${TEXT_MUTED}─${RESET} ${BOLD}May${RESET}  ${CYAN}◐${RESET} ${TEXT_SECONDARY}Testing Phase${RESET}                 ${ORANGE}(in progress)${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}      ${YELLOW}●${RESET} ${TEXT_SECONDARY}Unit Tests${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}"
    echo -e "  ${CYAN}●${RESET}${TEXT_MUTED}─${RESET} ${BOLD}Jun${RESET}  ${YELLOW}○${RESET} ${TEXT_SECONDARY}Beta Release${RESET}                  ${TEXT_MUTED}(upcoming)${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}"
    echo -e "  ${TEXT_MUTED}●${RESET}${TEXT_MUTED}─${RESET} ${BOLD}Jul${RESET}  ${TEXT_MUTED}○ Bug Fixes & Optimization${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}"
    echo -e "  ${TEXT_MUTED}●${RESET}${TEXT_MUTED}─${RESET} ${BOLD}Aug${RESET}  ${TEXT_MUTED}○ Performance Tuning${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}"
    echo -e "  ${TEXT_MUTED}●${RESET}${TEXT_MUTED}─${RESET} ${BOLD}Sep${RESET}  ${TEXT_MUTED}○ Security Audit${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}"
    echo -e "  ${TEXT_MUTED}●${RESET}${TEXT_MUTED}─${RESET} ${BOLD}Oct${RESET}  ${TEXT_MUTED}○ Documentation${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}"
    echo -e "  ${TEXT_MUTED}●${RESET}${TEXT_MUTED}─${RESET} ${BOLD}Nov${RESET}  ${TEXT_MUTED}○ Release Candidate${RESET}"
    echo -e "  ${TEXT_MUTED}│${RESET}"
    echo -e "  ${PURPLE}●${RESET}${TEXT_MUTED}─${RESET} ${BOLD}Dec${RESET}  ${TEXT_MUTED}○${RESET} ${BOLD}${PURPLE}v2.0 Launch${RESET}                ${TEXT_MUTED}(target)${RESET}"
    echo ""

    # Sprint Status
    echo -e "${TEXT_MUTED}╭─ CURRENT SPRINT ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Sprint:${RESET}             ${BOLD}${CYAN}Sprint 12${RESET}           ${TEXT_MUTED}(May 15 - May 29)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Story Points:${RESET}       ${BOLD}${ORANGE}34${RESET} / ${BOLD}${PURPLE}55${RESET}        ${TEXT_MUTED}61.8% complete${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Days Remaining:${RESET}     ${BOLD}${PINK}5${RESET}                  ${TEXT_MUTED}of 14${RESET}"
    echo ""
    echo -e "  ${CYAN}████████████████████████${TEXT_MUTED}████████████${RESET}  ${BOLD}62%${RESET}"
    echo ""

    # Milestones
    echo -e "${TEXT_MUTED}╭─ KEY MILESTONES ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Milestone${RESET}                  ${CYAN}Date${RESET}         ${ORANGE}Status${RESET}"
    echo -e "  ${TEXT_MUTED}───────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}Alpha Release${RESET}             ${CYAN}Mar 15${RESET}       ${GREEN}✓ Complete${RESET}"
    echo -e "  ${BOLD}Feature Freeze${RESET}            ${CYAN}May 31${RESET}       ${ORANGE}◐ In Progress${RESET}"
    echo -e "  ${BOLD}Beta Release${RESET}              ${CYAN}Jun 30${RESET}       ${YELLOW}○ Pending${RESET}"
    echo -e "  ${BOLD}RC1 Release${RESET}               ${CYAN}Nov 15${RESET}       ${TEXT_MUTED}○ Scheduled${RESET}"
    echo -e "  ${BOLD}GA Release${RESET}                ${CYAN}Dec 31${RESET}       ${TEXT_MUTED}○ Scheduled${RESET}"
    echo ""

    # Team Velocity
    echo -e "${TEXT_MUTED}╭─ TEAM VELOCITY ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}Sprint Velocity (Story Points)${RESET}"
    echo ""
    echo -e "  Sprint 8   ${CYAN}▆▆▆▆▆▆▆▆${RESET}                    ${BOLD}42${RESET}"
    echo -e "  Sprint 9   ${CYAN}▆▆▆▆▆▆▆▆▆${RESET}                   ${BOLD}47${RESET}"
    echo -e "  Sprint 10  ${GREEN}▆▆▆▆▆▆▆▆▆▆▆${RESET}                 ${BOLD}55${RESET}"
    echo -e "  Sprint 11  ${GREEN}▆▆▆▆▆▆▆▆▆▆${RESET}                  ${BOLD}52${RESET}"
    echo -e "  Sprint 12  ${ORANGE}▆▆▆▆▆▆${RESET}                      ${BOLD}34${RESET} ${TEXT_MUTED}(ongoing)${RESET}"
    echo ""

    # Blockers
    echo -e "${TEXT_MUTED}╭─ BLOCKERS & RISKS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${RED}🔴${RESET} ${BOLD}Critical${RESET}    API rate limits affecting performance"
    echo -e "  ${ORANGE}🟡${RESET} ${BOLD}High${RESET}        Third-party dependency upgrade needed"
    echo -e "  ${YELLOW}🟡${RESET} ${BOLD}Medium${RESET}      Database migration pending approval"
    echo ""

    # Team Activity
    echo -e "${TEXT_MUTED}╭─ RECENT ACTIVITY ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Completed: Authentication module${RESET}          ${TEXT_MUTED}Sarah • 2h ago${RESET}"
    echo -e "  ${CYAN}⚡${RESET} ${TEXT_SECONDARY}Started: Real-time notifications${RESET}           ${TEXT_MUTED}Mike • 3h ago${RESET}"
    echo -e "  ${PURPLE}🔀${RESET} ${TEXT_SECONDARY}Merged: PR #847 - Dashboard redesign${RESET}     ${TEXT_MUTED}Alex • 5h ago${RESET}"
    echo -e "  ${ORANGE}📝${RESET} ${TEXT_SECONDARY}Updated: API documentation${RESET}                ${TEXT_MUTED}Emma • 1d ago${RESET}"
    echo ""

    # Dependencies
    echo -e "${TEXT_MUTED}╭─ DEPENDENCIES ────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}●${RESET} ${BOLD}Auth Service${RESET}       ${GREEN}✓ Ready${RESET}      ${TEXT_MUTED}Completed Mar 15${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}Payment Gateway${RESET}    ${ORANGE}◐ In Review${RESET}  ${TEXT_MUTED}Blocking: Beta${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Email Service${RESET}      ${GREEN}✓ Ready${RESET}      ${TEXT_MUTED}Completed Apr 2${RESET}"
    echo -e "  ${PINK}●${RESET} ${BOLD}Analytics${RESET}          ${YELLOW}○ Pending${RESET}    ${TEXT_MUTED}Needed for RC1${RESET}"
    echo ""

    # Footer
    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}Updated: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Team: ${RESET}${BOLD}12 members${RESET}  ${TEXT_SECONDARY}|  Burndown: ${RESET}${BOLD}On track${RESET}"
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
