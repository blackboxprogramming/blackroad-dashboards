#!/bin/bash

# BlackRoad OS - Corporate Master Control Center
# Central command center for all corporate automation systems

source ~/blackroad-dashboards/themes.sh
load_theme

clear
echo ""
echo -e "${BOLD}${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GOLD}║${RESET}                                                                        ${BOLD}${GOLD}║${RESET}"
echo -e "${BOLD}${GOLD}║${RESET}  ${PURPLE}👑${RESET}  ${BOLD}BLACKROAD OS, INC. - CORPORATE MASTER CONTROL CENTER${RESET}          ${BOLD}${GOLD}║${RESET}"
echo -e "${BOLD}${GOLD}║${RESET}                                                                        ${BOLD}${GOLD}║${RESET}"
echo -e "${BOLD}${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Company info
echo -e "${TEXT_MUTED}╭─ COMPANY OVERVIEW ────────────────────────────────────────────────────╮${RESET}"
echo ""
echo -e "  ${BOLD}${TEXT_PRIMARY}Legal Name:${RESET}          ${GREEN}BlackRoad OS, Inc.${RESET}"
echo -e "  ${BOLD}${TEXT_PRIMARY}Incorporation:${RESET}       ${CYAN}Delaware C-Corp${RESET}"
echo -e "  ${BOLD}${TEXT_PRIMARY}CEO:${RESET}                 ${PURPLE}Alexa Louise Amundson${RESET}"
echo -e "  ${BOLD}${TEXT_PRIMARY}Verification:${RESET}        ${ORANGE}PS-SHA-∞ (Infinite Cascade)${RESET}"
echo ""
echo -e "  ${BOLD}${TEXT_PRIMARY}Organizations:${RESET}       ${CYAN}15${RESET} GitHub orgs"
echo -e "  ${BOLD}${TEXT_PRIMARY}Repositories:${RESET}        ${PURPLE}113+${RESET} repos"
echo -e "  ${BOLD}${TEXT_PRIMARY}AI Executives:${RESET}       ${GREEN}10${RESET} agents"
echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}              ${BOLD}${GREEN}✓ OPERATIONAL${RESET}"
echo ""

# Available systems
echo -e "${TEXT_MUTED}╭─ CORPORATE AUTOMATION SYSTEMS ────────────────────────────────────────╮${RESET}"
echo ""

echo -e "  ${GOLD}1.${RESET} ${BOLD}Auto CEO Mode${RESET}"
echo -e "     ${TEXT_MUTED}Autonomous CEO operations, decision engine, morning ops${RESET}"
echo ""

echo -e "  ${GOLD}2.${RESET} ${BOLD}Agent Coordinator${RESET}"
echo -e "     ${TEXT_MUTED}Orchestrates all 10 AI executives, task assignment${RESET}"
echo ""

echo -e "  ${GOLD}3.${RESET} ${BOLD}Corporate Agents Dashboard${RESET}"
echo -e "     ${TEXT_MUTED}Corporate command center, agent activation, monitoring${RESET}"
echo ""

echo -e "  ${GOLD}4.${RESET} ${BOLD}GitHub Real-Time Monitor${RESET}"
echo -e "     ${TEXT_MUTED}Track 15 orgs, 113+ repos, PRs, issues in real-time${RESET}"
echo ""

echo -e "  ${GOLD}5.${RESET} ${BOLD}Crypto Portfolio Tracker${RESET}"
echo -e "     ${TEXT_MUTED}Real-time ETH/SOL/BTC tracking, price alerts, 24h trends${RESET}"
echo ""

echo -e "  ${GOLD}6.${RESET} ${BOLD}Agent Communication Hub${RESET}"
echo -e "     ${TEXT_MUTED}Agent-to-agent messaging, broadcasts, inbox management${RESET}"
echo ""

echo -e "  ${CYAN}7.${RESET} ${BOLD}Launch ALL Systems${RESET}"
echo -e "     ${TEXT_MUTED}Start all 6 systems in parallel (tmux sessions)${RESET}"
echo ""

# Quick stats
echo -e "${TEXT_MUTED}╭─ QUICK STATS ─────────────────────────────────────────────────────────╮${RESET}"
echo ""

# Check if systems have been used
local ceo_log="$HOME/.auto-ceo-mode/operations.log"
local coord_log="$HOME/.auto-agent-coord/coordination.log"
local github_log="$HOME/.corporate-github-monitor/pr-activity.log"
local crypto_log="$HOME/.corporate-crypto-tracker/portfolio-history.log"
local comm_log="$HOME/.agent-communication-hub/messages.log"

local ceo_runs=0
local coord_cycles=0
local github_prs=0
local crypto_updates=0
local messages=0

[ -f "$ceo_log" ] && ceo_runs=$(wc -l < "$ceo_log" 2>/dev/null | xargs)
[ -f "$coord_log" ] && coord_cycles=$(wc -l < "$coord_log" 2>/dev/null | xargs)
[ -f "$github_log" ] && github_prs=$(wc -l < "$github_log" 2>/dev/null | xargs)
[ -f "$crypto_log" ] && crypto_updates=$(wc -l < "$crypto_log" 2>/dev/null | xargs)
[ -f "$comm_log" ] && messages=$(wc -l < "$comm_log" 2>/dev/null | xargs)

echo -e "  ${BOLD}${TEXT_PRIMARY}CEO Operations:${RESET}       ${CYAN}$ceo_runs${RESET} runs"
echo -e "  ${BOLD}${TEXT_PRIMARY}Agent Cycles:${RESET}         ${PURPLE}$coord_cycles${RESET} coordination cycles"
echo -e "  ${BOLD}${TEXT_PRIMARY}GitHub PRs Tracked:${RESET}   ${ORANGE}$github_prs${RESET} PRs"
echo -e "  ${BOLD}${TEXT_PRIMARY}Crypto Updates:${RESET}       ${GOLD}$crypto_updates${RESET} snapshots"
echo -e "  ${BOLD}${TEXT_PRIMARY}Agent Messages:${RESET}       ${GREEN}$messages${RESET} messages"
echo ""

# Infrastructure health
echo -e "${TEXT_MUTED}╭─ INFRASTRUCTURE HEALTH ───────────────────────────────────────────────╮${RESET}"
echo ""

# Quick checks
local gh_status=$(gh auth status 2>&1 | grep -q "Logged in" && echo "✓ Connected" || echo "✗ Not connected")
local memory_status=$([ -d "$HOME/.blackroad/memory" ] && echo "✓ Active" || echo "✗ Inactive")

echo -e "  ${BOLD}${TEXT_PRIMARY}GitHub CLI:${RESET}           ${GREEN}$gh_status${RESET}"
echo -e "  ${BOLD}${TEXT_PRIMARY}Memory System:${RESET}        ${GREEN}$memory_status${RESET}"
echo -e "  ${BOLD}${TEXT_PRIMARY}Dashboards:${RESET}           ${PURPLE}$(ls ~/blackroad-dashboards/*.sh 2>/dev/null | wc -l | xargs)${RESET} scripts"
echo ""

# Actions
echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${TEXT_SECONDARY}[1-6]${RESET} Launch System  ${TEXT_SECONDARY}[7]${RESET} Launch All  ${TEXT_SECONDARY}[S]${RESET} System Info  ${TEXT_SECONDARY}[Q]${RESET} Quit"
echo ""

echo -n "Selection: "
read -n1 choice
echo ""

case "$choice" in
    '1')
        clear
        exec ~/blackroad-dashboards/auto-ceo-mode.sh
        ;;
    '2')
        clear
        exec ~/blackroad-dashboards/auto-agent-coordinator.sh
        ;;
    '3')
        clear
        exec ~/blackroad-dashboards/corporate-agents.sh
        ;;
    '4')
        clear
        exec ~/blackroad-dashboards/corporate-github-monitor.sh
        ;;
    '5')
        clear
        exec ~/blackroad-dashboards/corporate-crypto-tracker.sh
        ;;
    '6')
        clear
        exec ~/blackroad-dashboards/agent-communication-hub.sh
        ;;
    '7')
        clear
        echo -e "${BOLD}${GREEN}Launching ALL corporate systems in tmux sessions...${RESET}\n"

        # Check if tmux is available
        if ! command -v tmux &> /dev/null; then
            echo -e "${RED}Error: tmux not installed${RESET}"
            echo -e "${TEXT_MUTED}Install with: brew install tmux${RESET}\n"
            exit 1
        fi

        # Create new tmux session
        tmux new-session -d -s blackroad-corporate -n "CEO"

        # Launch systems in separate windows
        tmux send-keys -t blackroad-corporate:CEO "~/blackroad-dashboards/auto-ceo-mode.sh" C-m
        tmux new-window -t blackroad-corporate -n "Coordinator"
        tmux send-keys -t blackroad-corporate:Coordinator "~/blackroad-dashboards/auto-agent-coordinator.sh" C-m
        tmux new-window -t blackroad-corporate -n "GitHub"
        tmux send-keys -t blackroad-corporate:GitHub "~/blackroad-dashboards/corporate-github-monitor.sh" C-m
        tmux new-window -t blackroad-corporate -n "Crypto"
        tmux send-keys -t blackroad-corporate:Crypto "~/blackroad-dashboards/corporate-crypto-tracker.sh" C-m
        tmux new-window -t blackroad-corporate -n "Comms"
        tmux send-keys -t blackroad-corporate:Comms "~/blackroad-dashboards/agent-communication-hub.sh" C-m

        echo -e "${GREEN}✓ All systems launched in tmux session 'blackroad-corporate'${RESET}\n"
        echo -e "To attach: ${CYAN}tmux attach -t blackroad-corporate${RESET}"
        echo -e "To detach: ${CYAN}Ctrl+B then D${RESET}"
        echo -e "To switch windows: ${CYAN}Ctrl+B then N${RESET} (next) or ${CYAN}Ctrl+B then P${RESET} (previous)"
        echo -e "To kill session: ${CYAN}tmux kill-session -t blackroad-corporate${RESET}\n"

        # Log to MEMORY
        ~/memory-system.sh log updated "[CORPORATE]+[LAUNCH] All Systems Activated" "Launched all 6 corporate automation systems in tmux: CEO mode, agent coordinator, GitHub monitor, crypto tracker, communication hub. Full autonomous operations active." "corporate-master-control" 2>/dev/null

        # Attach to session
        echo -e "${TEXT_MUTED}Attaching to session in 3 seconds...${RESET}"
        sleep 3
        tmux attach -t blackroad-corporate
        ;;
    's'|'S')
        clear
        echo -e "${BOLD}${CYAN}SYSTEM INFORMATION${RESET}\n"

        echo -e "${BOLD}Installed Scripts:${RESET}"
        ls -1 ~/blackroad-dashboards/*.sh | while read file; do
            local name=$(basename "$file" .sh)
            local size=$(wc -l < "$file" | xargs)
            echo -e "  ${GREEN}✓${RESET} $name ${TEXT_MUTED}($size lines)${RESET}"
        done

        echo -e "\n${BOLD}Data Directories:${RESET}"
        for dir in ~/.auto-ceo-mode ~/.auto-agent-coord ~/.corporate-github-monitor ~/.corporate-crypto-tracker ~/.agent-communication-hub; do
            if [ -d "$dir" ]; then
                local files=$(find "$dir" -type f | wc -l | xargs)
                echo -e "  ${PURPLE}●${RESET} $dir ${TEXT_MUTED}($files files)${RESET}"
            fi
        done

        echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
        read -n1
        exec ~/blackroad-dashboards/corporate-master-control.sh
        ;;
    'q'|'Q')
        clear
        echo -e "\n${CYAN}Corporate Master Control terminated${RESET}\n"
        exit 0
        ;;
    *)
        clear
        echo -e "\n${RED}Invalid selection${RESET}\n"
        sleep 1
        exec ~/blackroad-dashboards/corporate-master-control.sh
        ;;
esac
