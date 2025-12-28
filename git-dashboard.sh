#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#   ██████╗ ██╗████████╗    ██████╗  █████╗ ███████╗██╗  ██╗██████╗  ██████╗  █████╗ ██████╗ ██████╗
#  ██╔════╝ ██║╚══██╔══╝    ██╔══██╗██╔══██╗██╔════╝██║  ██║██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔══██╗
#  ██║  ███╗██║   ██║       ██║  ██║███████║███████╗███████║██████╔╝██║   ██║███████║██████╔╝██║  ██║
#  ██║   ██║██║   ██║       ██║  ██║██╔══██║╚════██║██╔══██║██╔══██╗██║   ██║██╔══██║██╔══██╗██║  ██║
#  ╚██████╔╝██║   ██║       ██████╔╝██║  ██║███████║██║  ██║██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝
#   ╚═════╝ ╚═╝   ╚═╝       ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD GIT OPERATIONS DASHBOARD v3.0
#  Visual Git Management, History, Branches, Commits
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# GIT DETECTION
#───────────────────────────────────────────────────────────────────────────────

is_git_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null
}

get_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null
}

get_current_branch() {
    git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null
}

get_remote_url() {
    git remote get-url origin 2>/dev/null
}

#───────────────────────────────────────────────────────────────────────────────
# GIT STATISTICS
#───────────────────────────────────────────────────────────────────────────────

get_commit_count() {
    git rev-list --count HEAD 2>/dev/null || echo "0"
}

get_branch_count() {
    git branch -a 2>/dev/null | wc -l | tr -d ' '
}

get_contributor_count() {
    git shortlog -sn 2>/dev/null | wc -l | tr -d ' '
}

get_file_count() {
    git ls-files 2>/dev/null | wc -l | tr -d ' '
}

get_repo_size() {
    local size=$(du -sh "$(get_repo_root)/.git" 2>/dev/null | awk '{print $1}')
    echo "${size:-0}"
}

get_last_commit() {
    git log -1 --format="%h|%s|%ar|%an" 2>/dev/null
}

get_uncommitted_changes() {
    git status --porcelain 2>/dev/null | wc -l | tr -d ' '
}

#───────────────────────────────────────────────────────────────────────────────
# GIT VISUALIZATION
#───────────────────────────────────────────────────────────────────────────────

# Commit activity graph (last 7 days)
render_commit_graph() {
    local days=7
    local -a counts=()
    local max_count=1

    for ((i=days-1; i>=0; i--)); do
        local date_str=$(date -d "$i days ago" +%Y-%m-%d 2>/dev/null || date -v-${i}d +%Y-%m-%d 2>/dev/null)
        local count=$(git log --oneline --since="$date_str 00:00" --until="$date_str 23:59" 2>/dev/null | wc -l | tr -d ' ')
        counts+=("$count")
        [[ $count -gt $max_count ]] && max_count=$count
    done

    printf "${BOLD}Commit Activity (7 days)${RST}\n"

    # Bar chart
    for ((row=5; row>=1; row--)); do
        printf "  "
        for count in "${counts[@]}"; do
            local height=$((count * 5 / max_count))
            if [[ $height -ge $row ]]; then
                printf "${BR_GREEN}██${RST} "
            else
                printf "   "
            fi
        done
        printf "\n"
    done

    # Labels
    printf "  "
    for ((i=days-1; i>=0; i--)); do
        local day=$(date -d "$i days ago" +%a 2>/dev/null || date -v-${i}d +%a 2>/dev/null)
        printf "${TEXT_MUTED}%-3s${RST}" "${day:0:2}"
    done
    printf "\n"
}

# Branch visualization
render_branch_tree() {
    printf "${BOLD}Branches${RST}\n\n"

    local current=$(get_current_branch)

    # Local branches
    while IFS= read -r branch; do
        branch="${branch#  }"
        branch="${branch#\* }"

        if [[ "$branch" == "$current" ]]; then
            printf "  ${BR_GREEN}●${RST} ${BOLD}${BR_CYAN}%s${RST} ${BR_GREEN}(current)${RST}\n" "$branch"
        else
            printf "  ${TEXT_MUTED}○${RST} ${TEXT_SECONDARY}%s${RST}\n" "$branch"
        fi
    done < <(git branch 2>/dev/null | head -10)

    local branch_count=$(git branch 2>/dev/null | wc -l)
    [[ $branch_count -gt 10 ]] && printf "  ${TEXT_MUTED}... and %d more${RST}\n" "$((branch_count - 10))"
}

# Recent commits list
render_recent_commits() {
    printf "${BOLD}Recent Commits${RST}\n\n"

    local format="%C(yellow)%h%C(reset) %C(cyan)%s%C(reset) %C(dim)(%ar by %an)%C(reset)"

    git log --oneline --decorate -10 2>/dev/null | while IFS= read -r line; do
        local hash=$(echo "$line" | awk '{print $1}')
        local msg=$(echo "$line" | cut -d' ' -f2-)

        printf "  ${BR_YELLOW}%s${RST} ${TEXT_SECONDARY}%s${RST}\n" "$hash" "${msg:0:50}"
    done
}

# File changes summary
render_changes_summary() {
    printf "${BOLD}Working Tree${RST}\n\n"

    local staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    local unstaged=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    local untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    printf "  ${BR_GREEN}●${RST} Staged:    %d files\n" "$staged"
    printf "  ${BR_YELLOW}●${RST} Modified:  %d files\n" "$unstaged"
    printf "  ${BR_RED}●${RST} Untracked: %d files\n" "$untracked"

    # Show actual changes
    if [[ $((staged + unstaged + untracked)) -gt 0 ]]; then
        printf "\n"
        git status --porcelain 2>/dev/null | head -8 | while IFS= read -r line; do
            local status="${line:0:2}"
            local file="${line:3}"

            case "$status" in
                "A "*|"M "*) printf "  ${BR_GREEN}+${RST} %s\n" "$file" ;;
                " M"|"MM")   printf "  ${BR_YELLOW}~${RST} %s\n" "$file" ;;
                "??")        printf "  ${BR_RED}?${RST} %s\n" "$file" ;;
                "D "*|" D")  printf "  ${BR_RED}-${RST} %s\n" "$file" ;;
                *)           printf "  ${TEXT_MUTED}%s${RST} %s\n" "$status" "$file" ;;
            esac
        done
    fi
}

# Contributor stats
render_contributors() {
    printf "${BOLD}Top Contributors${RST}\n\n"

    git shortlog -sn --no-merges 2>/dev/null | head -5 | while IFS=$'\t' read -r count name; do
        local bar_len=$((count / 10))
        [[ $bar_len -gt 20 ]] && bar_len=20

        printf "  ${BR_CYAN}%-20s${RST} " "${name:0:20}"
        printf "${BR_PURPLE}"
        printf "%0.s█" $(seq 1 "$bar_len" 2>/dev/null) || true
        printf "${RST} ${TEXT_MUTED}%d${RST}\n" "$count"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# GIT OPERATIONS
#───────────────────────────────────────────────────────────────────────────────

git_quick_commit() {
    local message="$1"

    if [[ -z "$message" ]]; then
        printf "${BR_CYAN}Commit message: ${RST}"
        read -r message
    fi

    [[ -z "$message" ]] && message="Quick commit $(date '+%Y-%m-%d %H:%M')"

    git add -A
    git commit -m "$message"
}

git_sync() {
    printf "${BR_CYAN}Syncing with remote...${RST}\n"
    git pull --rebase && git push
}

git_stash_menu() {
    printf "\n${BOLD}Stash Menu${RST}\n"
    printf "  ${BR_YELLOW}1.${RST} Stash changes\n"
    printf "  ${BR_YELLOW}2.${RST} Pop stash\n"
    printf "  ${BR_YELLOW}3.${RST} List stashes\n"
    printf "  ${BR_YELLOW}4.${RST} Clear stashes\n"

    read -rsn1 choice
    case "$choice" in
        1) git stash push -m "Stash $(date '+%Y-%m-%d %H:%M')" ;;
        2) git stash pop ;;
        3) git stash list ;;
        4) git stash clear ;;
    esac
}

git_branch_menu() {
    printf "\n${BOLD}Branch Menu${RST}\n"

    local branches=($(git branch --format='%(refname:short)' 2>/dev/null))
    local idx=1

    for branch in "${branches[@]}"; do
        printf "  ${BR_YELLOW}%d.${RST} %s\n" "$idx" "$branch"
        ((idx++))
    done

    printf "\n  ${BR_GREEN}n.${RST} New branch\n"

    read -rsn1 choice
    if [[ "$choice" == "n" ]]; then
        printf "${BR_CYAN}New branch name: ${RST}"
        read -r new_branch
        git checkout -b "$new_branch"
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -le ${#branches[@]} ]]; then
        git checkout "${branches[$((choice-1))]}"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

render_git_dashboard() {
    clear_screen
    cursor_hide

    if ! is_git_repo; then
        printf "${BR_RED}Not a git repository!${RST}\n"
        printf "${TEXT_SECONDARY}Navigate to a git repo and try again.${RST}\n"
        sleep 2
        return 1
    fi

    # Header
    printf "${BR_ORANGE}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                         🔀 GIT OPERATIONS DASHBOARD                          ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    # Repository info
    local repo_name=$(basename "$(get_repo_root)")
    local branch=$(get_current_branch)
    local remote=$(get_remote_url)
    local commits=$(get_commit_count)
    local changes=$(get_uncommitted_changes)

    printf "  ${BOLD}Repository:${RST} ${BR_CYAN}%s${RST}\n" "$repo_name"
    printf "  ${BOLD}Branch:${RST}     ${BR_GREEN}%s${RST}\n" "$branch"
    printf "  ${BOLD}Remote:${RST}     ${TEXT_MUTED}%s${RST}\n" "${remote:-none}"
    printf "  ${BOLD}Commits:${RST}    ${TEXT_SECONDARY}%s${RST}  ${BOLD}Changes:${RST} " "$commits"
    if [[ $changes -gt 0 ]]; then
        printf "${BR_YELLOW}%d uncommitted${RST}\n" "$changes"
    else
        printf "${BR_GREEN}clean${RST}\n"
    fi
    printf "\n"

    # Two-column layout
    printf "${BR_CYAN}┌─────────────────────────────────┬──────────────────────────────────────────┐${RST}\n"

    # Left: Commit graph and branches
    printf "${BR_CYAN}│${RST} "
    render_commit_graph | head -1
    printf "%35s" ""
    printf "${BR_CYAN}│${RST} "
    render_branch_tree | head -1
    printf "\n"

    # Content rows (simplified for display)
    for ((i=0; i<8; i++)); do
        printf "${BR_CYAN}│${RST} %-33s ${BR_CYAN}│${RST} %-40s ${BR_CYAN}│${RST}\n" "" ""
    done

    printf "${BR_CYAN}├─────────────────────────────────┴──────────────────────────────────────────┤${RST}\n"

    # Recent commits
    printf "${BR_CYAN}│${RST} ${BOLD}Recent Commits${RST}%61s${BR_CYAN}│${RST}\n" ""

    git log --oneline -5 2>/dev/null | while IFS= read -r line; do
        local hash=$(echo "$line" | awk '{print $1}')
        local msg=$(echo "$line" | cut -d' ' -f2- | head -c 60)
        printf "${BR_CYAN}│${RST}   ${BR_YELLOW}%s${RST} %-64s ${BR_CYAN}│${RST}\n" "$hash" "$msg"
    done

    printf "${BR_CYAN}└──────────────────────────────────────────────────────────────────────────────┘${RST}\n"

    # Quick actions
    printf "\n${TEXT_SECONDARY}[c]ommit  [p]ush  [l]pull  [b]ranch  [s]tash  [d]iff  [r]efresh  [q]uit${RST}\n"
}

git_dashboard_loop() {
    while true; do
        render_git_dashboard

        if read -rsn1 -t 3 key 2>/dev/null; then
            case "$key" in
                c|C)
                    cursor_show
                    printf "\n${BR_CYAN}Commit message: ${RST}"
                    read -r msg
                    cursor_hide
                    git_quick_commit "$msg"
                    sleep 1
                    ;;
                p|P)
                    printf "\n${BR_CYAN}Pushing...${RST}\n"
                    git push 2>&1 | head -5
                    sleep 2
                    ;;
                l|L)
                    printf "\n${BR_CYAN}Pulling...${RST}\n"
                    git pull 2>&1 | head -5
                    sleep 2
                    ;;
                b|B)
                    cursor_show
                    git_branch_menu
                    cursor_hide
                    sleep 1
                    ;;
                s|S)
                    cursor_show
                    git_stash_menu
                    cursor_hide
                    sleep 1
                    ;;
                d|D)
                    git diff --stat 2>/dev/null | head -20
                    printf "\n${TEXT_MUTED}Press any key...${RST}"
                    read -rsn1
                    ;;
                r|R) continue ;;
                q|Q) break ;;
            esac
        fi
    done

    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-dashboard}" in
        dashboard) git_dashboard_loop ;;
        status)    git status ;;
        log)       git log --oneline -20 ;;
        commit)    git_quick_commit "$2" ;;
        sync)      git_sync ;;
        *)
            printf "Usage: %s [dashboard|status|log|commit|sync]\n" "$0"
            ;;
    esac
fi
