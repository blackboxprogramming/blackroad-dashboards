#!/bin/bash

# BlackRoad OS - Corporate GitHub Real-Time Monitor
# Monitors all 15 GitHub orgs and 113+ repos in real-time

source ~/blackroad-dashboards/themes.sh
load_theme

MONITOR_DIR="$HOME/.corporate-github-monitor"
EVENTS_LOG="$MONITOR_DIR/github-events.log"
PR_LOG="$MONITOR_DIR/pr-activity.log"
ISSUE_LOG="$MONITOR_DIR/issue-activity.log"
REPO_STATS="$MONITOR_DIR/repo-stats.json"

mkdir -p "$MONITOR_DIR"

# GitHub organizations
ORGS=(
    "BlackRoad-OS"
    "BlackRoad-AI"
    "BlackRoad-Archive"
    "BlackRoad-Cloud"
    "BlackRoad-Education"
    "BlackRoad-Foundation"
    "BlackRoad-Gov"
    "BlackRoad-Hardware"
    "BlackRoad-Interactive"
    "BlackRoad-Labs"
    "BlackRoad-Media"
    "BlackRoad-Security"
    "BlackRoad-Studio"
    "BlackRoad-Ventures"
    "Blackbox-Enterprises"
)

# Get all open PRs across all orgs
scan_all_prs() {
    echo -e "${CYAN}Scanning all PRs across 15 organizations...${RESET}\n"

    local total_prs=0
    local org_pr_count=0

    for org in "${ORGS[@]}"; do
        echo -e "${TEXT_MUTED}Checking $org...${RESET}"

        # Get PR count for this org
        org_pr_count=$(gh pr list --search "is:open org:$org" --limit 1000 --json number 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")

        if [ "$org_pr_count" -gt 0 ]; then
            total_prs=$((total_prs + org_pr_count))
            echo -e "  ${GREEN}✓${RESET} $org_pr_count open PRs"

            # Get detailed PR info
            gh pr list --search "is:open org:$org" --limit 100 --json number,title,author,createdAt,repository 2>/dev/null | \
            jq -r '.[] | "\(.createdAt)|\('"$org"')|\(.repository.name)|\(.number)|\(.title)|\(.author.login)"' >> "$PR_LOG.tmp"
        else
            echo -e "  ${TEXT_MUTED}No open PRs${RESET}"
        fi
    done

    # Update PR log
    if [ -f "$PR_LOG.tmp" ]; then
        mv "$PR_LOG.tmp" "$PR_LOG"
    fi

    echo -e "\n${BOLD}${GREEN}Total Open PRs: $total_prs${RESET}\n"

    # Log to MEMORY
    ~/memory-system.sh log updated "[CORPORATE]+[GITHUB] PR Scan" "Scanned all 15 orgs: $total_prs open PRs across BlackRoad ecosystem" "corporate-github-monitor" 2>/dev/null

    return $total_prs
}

# Get all open issues
scan_all_issues() {
    echo -e "${CYAN}Scanning all issues across 15 organizations...${RESET}\n"

    local total_issues=0
    local org_issue_count=0

    for org in "${ORGS[@]}"; do
        echo -e "${TEXT_MUTED}Checking $org...${RESET}"

        org_issue_count=$(gh issue list --search "is:open org:$org" --limit 1000 --json number 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")

        if [ "$org_issue_count" -gt 0 ]; then
            total_issues=$((total_issues + org_issue_count))
            echo -e "  ${ORANGE}●${RESET} $org_issue_count open issues"

            # Get detailed issue info
            gh issue list --search "is:open org:$org" --limit 100 --json number,title,author,createdAt,repository 2>/dev/null | \
            jq -r '.[] | "\(.createdAt)|\('"$org"')|\(.repository.name)|\(.number)|\(.title)|\(.author.login)"' >> "$ISSUE_LOG.tmp"
        else
            echo -e "  ${TEXT_MUTED}No open issues${RESET}"
        fi
    done

    # Update issue log
    if [ -f "$ISSUE_LOG.tmp" ]; then
        mv "$ISSUE_LOG.tmp" "$ISSUE_LOG"
    fi

    echo -e "\n${BOLD}${ORANGE}Total Open Issues: $total_issues${RESET}\n"

    return $total_issues
}

# Get repository statistics
get_repo_stats() {
    echo -e "${CYAN}Gathering repository statistics...${RESET}\n"

    local total_repos=0
    local total_stars=0
    local total_forks=0

    cat > "$REPO_STATS" <<EOF
{
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "organizations": []
}
EOF

    for org in "${ORGS[@]}"; do
        echo -e "${TEXT_MUTED}Analyzing $org...${RESET}"

        local repo_count=$(gh repo list "$org" --limit 1000 --json name 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")

        if [ "$repo_count" -gt 0 ]; then
            total_repos=$((total_repos + repo_count))

            # Get stars and forks (sample from first 10 repos)
            local org_stars=$(gh repo list "$org" --limit 10 --json stargazerCount 2>/dev/null | jq '[.[].stargazerCount] | add' 2>/dev/null || echo "0")
            local org_forks=$(gh repo list "$org" --limit 10 --json forkCount 2>/dev/null | jq '[.[].forkCount] | add' 2>/dev/null || echo "0")

            total_stars=$((total_stars + org_stars))
            total_forks=$((total_forks + org_forks))

            echo -e "  ${PURPLE}✓${RESET} $repo_count repos, $org_stars stars, $org_forks forks"
        fi
    done

    echo -e "\n${BOLD}${CYAN}Ecosystem Stats:${RESET}"
    echo -e "  Repositories: ${PURPLE}$total_repos${RESET}"
    echo -e "  Stars: ${GOLD}$total_stars${RESET}"
    echo -e "  Forks: ${GREEN}$total_forks${RESET}\n"
}

# Monitor recent activity (last 24 hours)
monitor_recent_activity() {
    echo -e "${PURPLE}Monitoring recent activity (last 24 hours)...${RESET}\n"

    local recent_prs=0
    local recent_issues=0
    local recent_commits=0

    # PRs created in last 24h
    if [ -f "$PR_LOG" ]; then
        local yesterday=$(date -u -v-1d +"%Y-%m-%d" 2>/dev/null || date -u -d "yesterday" +"%Y-%m-%d")
        recent_prs=$(grep "$yesterday\|$(date -u +"%Y-%m-%d")" "$PR_LOG" 2>/dev/null | wc -l | xargs)
    fi

    # Issues created in last 24h
    if [ -f "$ISSUE_LOG" ]; then
        local yesterday=$(date -u -v-1d +"%Y-%m-%d" 2>/dev/null || date -u -d "yesterday" +"%Y-%m-%d")
        recent_issues=$(grep "$yesterday\|$(date -u +"%Y-%m-%d")" "$ISSUE_LOG" 2>/dev/null | wc -l | xargs)
    fi

    echo -e "${BOLD}${GREEN}Recent Activity (24h):${RESET}"
    echo -e "  New PRs: ${CYAN}$recent_prs${RESET}"
    echo -e "  New Issues: ${ORANGE}$recent_issues${RESET}"
    echo -e "  Commits: ${PURPLE}${recent_commits}${RESET}\n"
}

# Show real-time dashboard
show_github_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${PURPLE}🐙${RESET} ${BOLD}CORPORATE GITHUB REAL-TIME MONITOR${RESET}                              ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "  ${TEXT_MUTED}Last updated: $(date)${RESET}"
    echo ""

    # Organization overview
    echo -e "${TEXT_MUTED}╭─ ORGANIZATION OVERVIEW ───────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Organizations:${RESET}  ${PURPLE}15${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Repositories:${RESET}   ${CYAN}113+${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Owner:${RESET}                ${GREEN}blackboxprogramming${RESET}"
    echo ""

    # PR Statistics
    echo -e "${TEXT_MUTED}╭─ PULL REQUEST ACTIVITY ───────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$PR_LOG" ]; then
        local total_prs=$(wc -l < "$PR_LOG" 2>/dev/null | xargs)
        echo -e "  ${BOLD}${TEXT_PRIMARY}Total Open PRs:${RESET}       ${CYAN}$total_prs${RESET}"

        # Recent PRs
        echo -e "\n  ${TEXT_MUTED}Recent PRs:${RESET}"
        tail -5 "$PR_LOG" | while IFS='|' read -r created_at org repo number title author; do
            local date=$(echo "$created_at" | cut -d'T' -f1)
            echo -e "    ${GREEN}●${RESET} ${TEXT_MUTED}#$number${RESET} $repo ${TEXT_MUTED}($org)${RESET}"
        done
    else
        echo -e "  ${TEXT_MUTED}No PR data yet${RESET}"
    fi
    echo ""

    # Issue Statistics
    echo -e "${TEXT_MUTED}╭─ ISSUE ACTIVITY ──────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$ISSUE_LOG" ]; then
        local total_issues=$(wc -l < "$ISSUE_LOG" 2>/dev/null | xargs)
        echo -e "  ${BOLD}${TEXT_PRIMARY}Total Open Issues:${RESET}    ${ORANGE}$total_issues${RESET}"

        # Recent issues
        echo -e "\n  ${TEXT_MUTED}Recent Issues:${RESET}"
        tail -5 "$ISSUE_LOG" | while IFS='|' read -r created_at org repo number title author; do
            local date=$(echo "$created_at" | cut -d'T' -f1)
            echo -e "    ${ORANGE}●${RESET} ${TEXT_MUTED}#$number${RESET} $repo ${TEXT_MUTED}($org)${RESET}"
        done
    else
        echo -e "  ${TEXT_MUTED}No issue data yet${RESET}"
    fi
    echo ""

    # Top active repos
    echo -e "${TEXT_MUTED}╭─ TOP ACTIVE REPOSITORIES ─────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$PR_LOG" ] && [ -f "$ISSUE_LOG" ]; then
        # Combine PR and issue logs and count by repo
        (cat "$PR_LOG" "$ISSUE_LOG" 2>/dev/null | cut -d'|' -f2-3 | sort | uniq -c | sort -rn | head -5) | while read count org repo; do
            echo -e "  ${PURPLE}●${RESET} ${BOLD}$repo${RESET} ${TEXT_MUTED}($org)${RESET} - $count activities"
        done
    else
        echo -e "  ${TEXT_MUTED}Gathering data...${RESET}"
    fi
    echo ""

    # Actions
    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[P]${RESET} Scan PRs  ${TEXT_SECONDARY}[I]${RESET} Scan Issues  ${TEXT_SECONDARY}[R]${RESET} Repo Stats  ${TEXT_SECONDARY}[A]${RESET} Auto Monitor  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Auto-monitoring loop
auto_monitor_loop() {
    local cycle=0

    echo -e "${BOLD}${GREEN}Starting auto-monitoring mode...${RESET}\n"
    echo -e "Monitoring all 15 GitHub organizations every 5 minutes\n"

    while true; do
        ((cycle++))

        clear
        echo -e "${BOLD}${CYAN}AUTO GITHUB MONITOR - CYCLE #$cycle${RESET}"
        echo -e "${TEXT_MUTED}$(date)${RESET}\n"

        # Scan everything
        scan_all_prs
        echo ""
        scan_all_issues
        echo ""
        monitor_recent_activity

        echo -e "${TEXT_MUTED}Next scan in 5 minutes... Press Q to stop${RESET}\n"

        # Wait with interrupt
        read -t 300 -n1 key

        if [ "$key" = "q" ] || [ "$key" = "Q" ]; then
            echo -e "\n${ORANGE}Auto-monitoring stopped${RESET}\n"
            return
        fi
    done
}

# Main loop
main() {
    while true; do
        show_github_dashboard

        read -n1 key

        case "$key" in
            'p'|'P')
                clear
                scan_all_prs
                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            'i'|'I')
                clear
                scan_all_issues
                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            'r'|'R')
                clear
                get_repo_stats
                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            'a'|'A')
                clear
                auto_monitor_loop
                ;;
            'q'|'Q')
                clear
                echo -e "\n${CYAN}GitHub monitor stopped${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
