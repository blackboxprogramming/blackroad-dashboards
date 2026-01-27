#!/bin/bash

# BlackRoad OS - Git Activity Dashboard
# Track repository activity, commits, contributors, and code changes

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
    echo -e "${BOLD}${PURPLE}║${RESET}  ${ORANGE}📊${RESET} ${BOLD}GIT ACTIVITY DASHBOARD${RESET}                                           ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Repository Overview
    echo -e "${TEXT_MUTED}╭─ REPOSITORY: blackroad-dashboards ────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Branch:${RESET}             ${BOLD}${CYAN}main${RESET}               ${TEXT_MUTED}128 commits ahead${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Commits:${RESET}      ${BOLD}${ORANGE}2,847${RESET}              ${TEXT_SECONDARY}since inception${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Contributors:${RESET}       ${BOLD}${PURPLE}12${RESET}                 ${TEXT_SECONDARY}active developers${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Last Commit:${RESET}        ${BOLD}${GREEN}2 hours ago${RESET}        ${TEXT_MUTED}by @alex${RESET}"
    echo ""

    # Activity Summary
    echo -e "${TEXT_MUTED}╭─ ACTIVITY (LAST 7 DAYS) ──────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Commits:${RESET}            ${BOLD}${CYAN}147${RESET}                ${GREEN}↑ 23%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Pull Requests:${RESET}      ${BOLD}${ORANGE}23${RESET}                 ${TEXT_SECONDARY}(18 merged, 5 open)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Lines Added:${RESET}        ${BOLD}${GREEN}+12,847${RESET}            ${TEXT_SECONDARY}across all files${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Lines Removed:${RESET}      ${BOLD}${RED}-3,234${RESET}             ${TEXT_SECONDARY}code cleanup${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Files Changed:${RESET}      ${BOLD}${PINK}847${RESET}                ${TEXT_SECONDARY}unique files${RESET}"
    echo ""

    # Commit Activity Chart
    echo -e "${TEXT_MUTED}╭─ COMMIT FREQUENCY ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}Last 14 Days${RESET}"
    echo ""
    echo -e "  Mon  ${GREEN}████████████${RESET}                     ${BOLD}24${RESET}"
    echo -e "  Tue  ${CYAN}█████████████████${RESET}                ${BOLD}34${RESET}"
    echo -e "  Wed  ${ORANGE}████████████████████${RESET}             ${BOLD}42${RESET}"
    echo -e "  Thu  ${PINK}███████████████${RESET}                  ${BOLD}31${RESET}"
    echo -e "  Fri  ${PURPLE}██████████${RESET}                       ${BOLD}21${RESET}"
    echo -e "  Sat  ${CYAN}████${RESET}                             ${BOLD}8${RESET}"
    echo -e "  Sun  ${BLUE}██${RESET}                               ${BOLD}4${RESET}"
    echo ""

    # Top Contributors
    echo -e "${TEXT_MUTED}╭─ TOP CONTRIBUTORS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Developer${RESET}           ${CYAN}Commits${RESET}    ${ORANGE}+Lines${RESET}     ${RED}-Lines${RESET}"
    echo -e "  ${TEXT_MUTED}──────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}@alex${RESET}              ${CYAN}47${RESET}         ${ORANGE}+4.2K${RESET}     ${RED}-847${RESET}"
    echo -e "  ${BOLD}@sarah${RESET}             ${CYAN}34${RESET}         ${ORANGE}+3.1K${RESET}     ${RED}-623${RESET}"
    echo -e "  ${BOLD}@mike${RESET}              ${CYAN}28${RESET}         ${ORANGE}+2.4K${RESET}     ${RED}-412${RESET}"
    echo -e "  ${BOLD}@emma${RESET}              ${CYAN}21${RESET}         ${ORANGE}+1.8K${RESET}     ${RED}-234${RESET}"
    echo -e "  ${BOLD}@david${RESET}             ${CYAN}17${RESET}         ${ORANGE}+1.2K${RESET}     ${RED}-118${RESET}"
    echo ""

    # Recent Commits
    echo -e "${TEXT_MUTED}╭─ RECENT COMMITS ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${BOLD}4f5d534${RESET} ${TEXT_SECONDARY}Add completion documentation${RESET}           ${TEXT_MUTED}@alex • 2h${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}195c856${RESET} ${TEXT_SECONDARY}Update template counts to 128${RESET}          ${TEXT_MUTED}@alex • 3h${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}fef41f1${RESET} ${TEXT_SECONDARY}Add 11 new dashboard templates${RESET}         ${TEXT_MUTED}@sarah • 4h${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}6f939df${RESET} ${TEXT_SECONDARY}Fix code review issues${RESET}                 ${TEXT_MUTED}@mike • 6h${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}be43886${RESET} ${TEXT_SECONDARY}Fix file paths in preview system${RESET}       ${TEXT_MUTED}@emma • 8h${RESET}"
    echo ""

    # File Changes
    echo -e "${TEXT_MUTED}╭─ MOST CHANGED FILES ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}File${RESET}                            ${CYAN}Changes${RESET}    ${ORANGE}Type${RESET}"
    echo -e "  ${TEXT_MUTED}───────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}previews/templates.json${RESET}        ${CYAN}47${RESET}         ${ORANGE}JSON${RESET}"
    echo -e "  ${BOLD}README.md${RESET}                      ${CYAN}23${RESET}         ${ORANGE}Docs${RESET}"
    echo -e "  ${BOLD}generate-previews.sh${RESET}           ${CYAN}18${RESET}         ${ORANGE}Script${RESET}"
    echo -e "  ${BOLD}previews/index.html${RESET}            ${CYAN}12${RESET}         ${ORANGE}HTML${RESET}"
    echo -e "  ${BOLD}launch.sh${RESET}                      ${CYAN}8${RESET}          ${ORANGE}Script${RESET}"
    echo ""

    # Language Statistics
    echo -e "${TEXT_MUTED}╭─ LANGUAGE DISTRIBUTION ───────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}Shell${RESET}       ${CYAN}██████████████████████████${RESET}        72.4%"
    echo -e "  ${BOLD}HTML${RESET}        ${ORANGE}█████████${RESET}                         14.2%"
    echo -e "  ${BOLD}Markdown${RESET}    ${PINK}█████${RESET}                             8.9%"
    echo -e "  ${BOLD}JSON${RESET}        ${PURPLE}███${RESET}                               4.5%"
    echo ""

    # Pull Requests
    echo -e "${TEXT_MUTED}╭─ OPEN PULL REQUESTS ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}#847${RESET} ${BOLD}Add new templates${RESET}                  ${TEXT_MUTED}@alex • 3 approvals${RESET}"
    echo -e "  ${CYAN}#846${RESET} ${BOLD}Update documentation${RESET}               ${TEXT_MUTED}@sarah • 2 approvals${RESET}"
    echo -e "  ${ORANGE}#845${RESET} ${BOLD}Fix preview system${RESET}                 ${TEXT_MUTED}@mike • 1 approval${RESET}"
    echo -e "  ${PURPLE}#844${RESET} ${BOLD}Improve performance${RESET}                ${TEXT_MUTED}@emma • in review${RESET}"
    echo ""

    # Branch Status
    echo -e "${TEXT_MUTED}╭─ ACTIVE BRANCHES ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${BOLD}main${RESET}                    ${TEXT_SECONDARY}Latest: 2h ago${RESET}     ${GREEN}✓ Protected${RESET}"
    echo -e "  ${CYAN}●${RESET} ${BOLD}feature/new-templates${RESET}   ${TEXT_SECONDARY}Latest: 3h ago${RESET}     ${CYAN}◐ Active${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}fix/preview-system${RESET}      ${TEXT_SECONDARY}Latest: 1d ago${RESET}     ${ORANGE}⚠ Stale${RESET}"
    echo ""

    # Repository Stats
    echo -e "${TEXT_MUTED}╭─ REPOSITORY STATS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Lines:${RESET}        ${BOLD}${CYAN}847,234${RESET}            ${TEXT_SECONDARY}across all files${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Files:${RESET}        ${BOLD}${ORANGE}234${RESET}                ${TEXT_SECONDARY}tracked${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Repo Size:${RESET}          ${BOLD}${PURPLE}47.2 MB${RESET}            ${TEXT_SECONDARY}on disk${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Stars:${RESET}              ${BOLD}${PINK}2,847${RESET}              ${GREEN}↑ 234 this week${RESET}"
    echo ""

    # Footer
    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}Updated: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Org: ${RESET}${BOLD}blackboxprogramming${RESET}  ${TEXT_SECONDARY}|  Repo: ${RESET}${BOLD}blackroad-dashboards${RESET}"
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
