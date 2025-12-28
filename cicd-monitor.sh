#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#   ██████╗██╗   ██╗ ██████╗██████╗     ███╗   ███╗ ██████╗ ███╗   ██╗██╗████████╗ ██████╗ ██████╗
#  ██╔════╝██║   ██║██╔════╝██╔══██╗    ████╗ ████║██╔═══██╗████╗  ██║██║╚══██╔══╝██╔═══██╗██╔══██╗
#  ██║     ██║   ██║██║     ██║  ██║    ██╔████╔██║██║   ██║██╔██╗ ██║██║   ██║   ██║   ██║██████╔╝
#  ██║     ██║   ██║██║     ██║  ██║    ██║╚██╔╝██║██║   ██║██║╚██╗██║██║   ██║   ██║   ██║██╔══██╗
#  ╚██████╗██║   ██║╚██████╗██████╔╝    ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║   ██║   ╚██████╔╝██║  ██║
#   ╚═════╝╚═╝   ╚═╝ ╚═════╝╚═════╝     ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD CI/CD PIPELINE MONITOR v3.0
#  GitHub Actions, GitLab CI, Jenkins & CircleCI Dashboard
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

CACHE_DIR="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}/cache/cicd"
CONFIG_FILE="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}/cicd_config.json"

mkdir -p "$CACHE_DIR" 2>/dev/null

# API Tokens (from environment or config)
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"
JENKINS_TOKEN="${JENKINS_TOKEN:-}"
CIRCLECI_TOKEN="${CIRCLECI_TOKEN:-}"

#───────────────────────────────────────────────────────────────────────────────
# GITHUB ACTIONS
#───────────────────────────────────────────────────────────────────────────────

gh_get_workflows() {
    local repo="$1"

    if command -v gh &>/dev/null; then
        gh api "repos/$repo/actions/workflows" 2>/dev/null
    elif [[ -n "$GITHUB_TOKEN" ]]; then
        curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/$repo/actions/workflows" 2>/dev/null
    else
        echo '{"workflows":[]}'
    fi
}

gh_get_runs() {
    local repo="$1"
    local workflow_id="${2:-}"
    local per_page="${3:-10}"

    local url="repos/$repo/actions/runs?per_page=$per_page"
    [[ -n "$workflow_id" ]] && url+="&workflow_id=$workflow_id"

    if command -v gh &>/dev/null; then
        gh api "$url" 2>/dev/null
    elif [[ -n "$GITHUB_TOKEN" ]]; then
        curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/$url" 2>/dev/null
    else
        echo '{"workflow_runs":[]}'
    fi
}

gh_get_run_jobs() {
    local repo="$1"
    local run_id="$2"

    if command -v gh &>/dev/null; then
        gh api "repos/$repo/actions/runs/$run_id/jobs" 2>/dev/null
    elif [[ -n "$GITHUB_TOKEN" ]]; then
        curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/$repo/actions/runs/$run_id/jobs" 2>/dev/null
    else
        echo '{"jobs":[]}'
    fi
}

gh_rerun_workflow() {
    local repo="$1"
    local run_id="$2"

    if command -v gh &>/dev/null; then
        gh api -X POST "repos/$repo/actions/runs/$run_id/rerun" 2>/dev/null
    fi
}

gh_cancel_run() {
    local repo="$1"
    local run_id="$2"

    if command -v gh &>/dev/null; then
        gh api -X POST "repos/$repo/actions/runs/$run_id/cancel" 2>/dev/null
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# GITLAB CI
#───────────────────────────────────────────────────────────────────────────────

gitlab_get_pipelines() {
    local project_id="$1"
    local per_page="${2:-20}"

    [[ -z "$GITLAB_TOKEN" ]] && echo '[]' && return

    curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "https://gitlab.com/api/v4/projects/$project_id/pipelines?per_page=$per_page" 2>/dev/null
}

gitlab_get_pipeline_jobs() {
    local project_id="$1"
    local pipeline_id="$2"

    [[ -z "$GITLAB_TOKEN" ]] && echo '[]' && return

    curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "https://gitlab.com/api/v4/projects/$project_id/pipelines/$pipeline_id/jobs" 2>/dev/null
}

gitlab_retry_pipeline() {
    local project_id="$1"
    local pipeline_id="$2"

    [[ -z "$GITLAB_TOKEN" ]] && return

    curl -s -X POST -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "https://gitlab.com/api/v4/projects/$project_id/pipelines/$pipeline_id/retry" 2>/dev/null
}

gitlab_cancel_pipeline() {
    local project_id="$1"
    local pipeline_id="$2"

    [[ -z "$GITLAB_TOKEN" ]] && return

    curl -s -X POST -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "https://gitlab.com/api/v4/projects/$project_id/pipelines/$pipeline_id/cancel" 2>/dev/null
}

#───────────────────────────────────────────────────────────────────────────────
# JENKINS
#───────────────────────────────────────────────────────────────────────────────

jenkins_get_jobs() {
    local jenkins_url="$1"
    local user="${2:-}"
    local token="${3:-$JENKINS_TOKEN}"

    local auth=""
    [[ -n "$user" && -n "$token" ]] && auth="-u $user:$token"

    curl -s $auth "${jenkins_url}/api/json?tree=jobs[name,color,lastBuild[number,result,timestamp,duration]]" 2>/dev/null
}

jenkins_get_build() {
    local jenkins_url="$1"
    local job_name="$2"
    local build_number="$3"

    curl -s "${jenkins_url}/job/$job_name/$build_number/api/json" 2>/dev/null
}

jenkins_trigger_build() {
    local jenkins_url="$1"
    local job_name="$2"
    local user="${3:-}"
    local token="${4:-$JENKINS_TOKEN}"

    local auth=""
    [[ -n "$user" && -n "$token" ]] && auth="-u $user:$token"

    curl -s -X POST $auth "${jenkins_url}/job/$job_name/build" 2>/dev/null
}

#───────────────────────────────────────────────────────────────────────────────
# CIRCLECI
#───────────────────────────────────────────────────────────────────────────────

circleci_get_pipelines() {
    local project_slug="$1"  # e.g., gh/owner/repo

    [[ -z "$CIRCLECI_TOKEN" ]] && echo '{"items":[]}' && return

    curl -s -H "Circle-Token: $CIRCLECI_TOKEN" \
        "https://circleci.com/api/v2/project/$project_slug/pipeline?limit=20" 2>/dev/null
}

circleci_get_workflow() {
    local pipeline_id="$1"

    [[ -z "$CIRCLECI_TOKEN" ]] && echo '{"items":[]}' && return

    curl -s -H "Circle-Token: $CIRCLECI_TOKEN" \
        "https://circleci.com/api/v2/pipeline/$pipeline_id/workflow" 2>/dev/null
}

circleci_rerun_workflow() {
    local workflow_id="$1"

    [[ -z "$CIRCLECI_TOKEN" ]] && return

    curl -s -X POST -H "Circle-Token: $CIRCLECI_TOKEN" \
        "https://circleci.com/api/v2/workflow/$workflow_id/rerun" 2>/dev/null
}

#───────────────────────────────────────────────────────────────────────────────
# STATUS RENDERING
#───────────────────────────────────────────────────────────────────────────────

render_status_icon() {
    local status="$1"

    case "$status" in
        success|completed|passed|SUCCESS)
            printf "${BR_GREEN}✓${RST}"
            ;;
        failure|failed|FAILURE)
            printf "${BR_RED}✗${RST}"
            ;;
        running|in_progress|pending)
            printf "${BR_YELLOW}◐${RST}"
            ;;
        queued|waiting|created)
            printf "${BR_CYAN}◯${RST}"
            ;;
        cancelled|canceled|skipped)
            printf "${TEXT_MUTED}○${RST}"
            ;;
        *)
            printf "${TEXT_MUTED}?${RST}"
            ;;
    esac
}

render_status_bar() {
    local jobs_json="$1"
    local max_width="${2:-40}"

    if ! command -v jq &>/dev/null; then
        return
    fi

    local success=0
    local failure=0
    local running=0
    local other=0

    while read -r status; do
        case "$status" in
            completed|success|passed) ((success++)) ;;
            failure|failed) ((failure++)) ;;
            in_progress|running|pending) ((running++)) ;;
            *) ((other++)) ;;
        esac
    done < <(echo "$jobs_json" | jq -r '.[].status // .[].conclusion // "unknown"' 2>/dev/null)

    local total=$((success + failure + running + other))
    [[ $total -eq 0 ]] && return

    local success_width=$((success * max_width / total))
    local failure_width=$((failure * max_width / total))
    local running_width=$((running * max_width / total))
    local other_width=$((max_width - success_width - failure_width - running_width))

    printf "${BR_GREEN}"
    printf "%0.s█" $(seq 1 $success_width 2>/dev/null) || true
    printf "${BR_RED}"
    printf "%0.s█" $(seq 1 $failure_width 2>/dev/null) || true
    printf "${BR_YELLOW}"
    printf "%0.s█" $(seq 1 $running_width 2>/dev/null) || true
    printf "${TEXT_MUTED}"
    printf "%0.s░" $(seq 1 $other_width 2>/dev/null) || true
    printf "${RST}"
}

render_duration() {
    local seconds="$1"

    if [[ $seconds -ge 3600 ]]; then
        printf "%dh %dm" $((seconds / 3600)) $(((seconds % 3600) / 60))
    elif [[ $seconds -ge 60 ]]; then
        printf "%dm %ds" $((seconds / 60)) $((seconds % 60))
    else
        printf "%ds" "$seconds"
    fi
}

render_time_ago() {
    local timestamp="$1"

    # Convert ISO timestamp to seconds
    local then_epoch=$(date -d "$timestamp" +%s 2>/dev/null || echo 0)
    local now_epoch=$(date +%s)
    local diff=$((now_epoch - then_epoch))

    if [[ $diff -lt 60 ]]; then
        printf "just now"
    elif [[ $diff -lt 3600 ]]; then
        printf "%dm ago" $((diff / 60))
    elif [[ $diff -lt 86400 ]]; then
        printf "%dh ago" $((diff / 3600))
    else
        printf "%dd ago" $((diff / 86400))
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# GITHUB ACTIONS DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

render_github_dashboard() {
    local repo="$1"

    printf "${BOLD}GitHub Actions: %s${RST}\n\n" "$repo"

    if ! command -v jq &>/dev/null; then
        printf "${TEXT_MUTED}jq required for parsing${RST}\n"
        return
    fi

    local runs=$(gh_get_runs "$repo" "" 15)

    printf "%-3s %-35s %-12s %-10s %-15s %-12s\n" "ST" "WORKFLOW" "STATUS" "DURATION" "BRANCH" "TRIGGERED"
    printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────────────────────────────────────────────────────────"

    echo "$runs" | jq -c '.workflow_runs[]?' 2>/dev/null | while read -r run; do
        local name=$(echo "$run" | jq -r '.name')
        local status=$(echo "$run" | jq -r '.status')
        local conclusion=$(echo "$run" | jq -r '.conclusion // "running"')
        local branch=$(echo "$run" | jq -r '.head_branch')
        local created=$(echo "$run" | jq -r '.created_at')
        local run_id=$(echo "$run" | jq -r '.id')

        # Calculate duration
        local started=$(echo "$run" | jq -r '.run_started_at // .created_at')
        local updated=$(echo "$run" | jq -r '.updated_at')
        local start_epoch=$(date -d "$started" +%s 2>/dev/null || echo 0)
        local end_epoch=$(date -d "$updated" +%s 2>/dev/null || echo 0)
        local duration=$((end_epoch - start_epoch))

        local display_status="$conclusion"
        [[ "$status" == "in_progress" ]] && display_status="running"

        printf " "
        render_status_icon "$display_status"
        printf " ${BOLD}%-35s${RST} " "${name:0:35}"

        case "$display_status" in
            success)  printf "${BR_GREEN}%-12s${RST} " "$display_status" ;;
            failure)  printf "${BR_RED}%-12s${RST} " "$display_status" ;;
            running)  printf "${BR_YELLOW}%-12s${RST} " "$display_status" ;;
            *)        printf "${TEXT_MUTED}%-12s${RST} " "$display_status" ;;
        esac

        printf "${TEXT_SECONDARY}%-10s${RST} " "$(render_duration $duration)"
        printf "${BR_CYAN}%-15s${RST} " "${branch:0:15}"
        printf "${TEXT_MUTED}%-12s${RST}\n" "$(render_time_ago "$created")"
    done
}

render_github_run_details() {
    local repo="$1"
    local run_id="$2"

    if ! command -v jq &>/dev/null; then
        return
    fi

    local jobs=$(gh_get_run_jobs "$repo" "$run_id")

    printf "\n${BOLD}Jobs for run #%s${RST}\n\n" "$run_id"

    echo "$jobs" | jq -c '.jobs[]?' 2>/dev/null | while read -r job; do
        local name=$(echo "$job" | jq -r '.name')
        local status=$(echo "$job" | jq -r '.status')
        local conclusion=$(echo "$job" | jq -r '.conclusion // "running"')

        printf "  "
        render_status_icon "$conclusion"
        printf " %-30s " "$name"

        # Steps
        local steps=$(echo "$job" | jq -c '.steps[]?' 2>/dev/null)
        echo "$steps" | while read -r step; do
            local step_conclusion=$(echo "$step" | jq -r '.conclusion // "pending"')
            render_status_icon "$step_conclusion"
        done
        printf "\n"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# PIPELINE VISUALIZATION
#───────────────────────────────────────────────────────────────────────────────

render_pipeline_ascii() {
    local -a stages=("$@")

    printf "\n"

    # Draw pipeline stages
    for ((i=0; i<${#stages[@]}; i++)); do
        IFS='|' read -r name status <<< "${stages[i]}"

        local color="$TEXT_MUTED"
        case "$status" in
            success|passed) color="$BR_GREEN" ;;
            failure|failed) color="$BR_RED" ;;
            running)        color="$BR_YELLOW" ;;
            pending)        color="$BR_CYAN" ;;
        esac

        # Stage box
        printf "${color}"
        printf "┌─────────────┐"
        printf "${RST}"

        if [[ $i -lt $((${#stages[@]} - 1)) ]]; then
            printf "──▶"
        fi
    done
    printf "\n"

    for ((i=0; i<${#stages[@]}; i++)); do
        IFS='|' read -r name status <<< "${stages[i]}"

        local color="$TEXT_MUTED"
        case "$status" in
            success|passed) color="$BR_GREEN" ;;
            failure|failed) color="$BR_RED" ;;
            running)        color="$BR_YELLOW" ;;
            pending)        color="$BR_CYAN" ;;
        esac

        printf "${color}"
        printf "│ %-11s │" "${name:0:11}"
        printf "${RST}"

        if [[ $i -lt $((${#stages[@]} - 1)) ]]; then
            printf "   "
        fi
    done
    printf "\n"

    for ((i=0; i<${#stages[@]}; i++)); do
        IFS='|' read -r name status <<< "${stages[i]}"

        local color="$TEXT_MUTED"
        case "$status" in
            success|passed) color="$BR_GREEN" ;;
            failure|failed) color="$BR_RED" ;;
            running)        color="$BR_YELLOW" ;;
            pending)        color="$BR_CYAN" ;;
        esac

        printf "${color}"
        printf "│     "
        render_status_icon "$status"
        printf "       │"
        printf "${RST}"

        if [[ $i -lt $((${#stages[@]} - 1)) ]]; then
            printf "   "
        fi
    done
    printf "\n"

    for ((i=0; i<${#stages[@]}; i++)); do
        IFS='|' read -r name status <<< "${stages[i]}"

        local color="$TEXT_MUTED"
        case "$status" in
            success|passed) color="$BR_GREEN" ;;
            failure|failed) color="$BR_RED" ;;
            running)        color="$BR_YELLOW" ;;
            pending)        color="$BR_CYAN" ;;
        esac

        printf "${color}"
        printf "└─────────────┘"
        printf "${RST}"

        if [[ $i -lt $((${#stages[@]} - 1)) ]]; then
            printf "   "
        fi
    done
    printf "\n\n"
}

#───────────────────────────────────────────────────────────────────────────────
# LOCAL CI SIMULATION
#───────────────────────────────────────────────────────────────────────────────

run_local_ci() {
    local config_file="${1:-.github/workflows}"

    clear_screen
    printf "${BOLD}Running Local CI Simulation${RST}\n\n"

    # Define common stages
    local -a stages=("checkout" "install" "lint" "test" "build" "deploy")
    local -a statuses=()

    for stage in "${stages[@]}"; do
        statuses+=("$stage|pending")
    done

    for ((i=0; i<${#stages[@]}; i++)); do
        local stage="${stages[i]}"
        statuses[i]="$stage|running"

        # Render current state
        cursor_to 4 1
        render_pipeline_ascii "${statuses[@]}"

        printf "  ${BR_YELLOW}Running: %s...${RST}\n" "$stage"

        # Simulate work
        case "$stage" in
            checkout)
                sleep 1
                ;;
            install)
                [[ -f "package.json" ]] && npm install --silent 2>/dev/null
                sleep 2
                ;;
            lint)
                if [[ -f "package.json" ]]; then
                    npm run lint --silent 2>/dev/null || {
                        statuses[i]="$stage|failure"
                        break
                    }
                fi
                sleep 1
                ;;
            test)
                if [[ -f "package.json" ]]; then
                    npm test --silent 2>/dev/null || {
                        statuses[i]="$stage|failure"
                        break
                    }
                fi
                sleep 2
                ;;
            build)
                [[ -f "package.json" ]] && npm run build --silent 2>/dev/null
                sleep 2
                ;;
            deploy)
                sleep 1
                ;;
        esac

        statuses[i]="$stage|success"
    done

    # Final render
    cursor_to 4 1
    render_pipeline_ascii "${statuses[@]}"

    # Summary
    local passed=0
    local failed=0
    for status in "${statuses[@]}"; do
        [[ "$status" == *"|success" ]] && ((passed++))
        [[ "$status" == *"|failure" ]] && ((failed++))
    done

    if [[ $failed -eq 0 ]]; then
        printf "  ${BR_GREEN}All stages passed!${RST}\n"
    else
        printf "  ${BR_RED}Pipeline failed: %d stage(s) failed${RST}\n" "$failed"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

render_cicd_dashboard() {
    clear_screen
    cursor_hide

    printf "${BR_ORANGE}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                        ⚙️  CI/CD PIPELINE MONITOR                             ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    # Detect repo
    local repo=""
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local remote=$(git remote get-url origin 2>/dev/null)
        if [[ "$remote" == *github.com* ]]; then
            repo=$(echo "$remote" | sed -E 's|.*github.com[:/]||' | sed 's|\.git$||')
        fi
    fi

    if [[ -n "$repo" ]]; then
        printf "  ${BOLD}Repository:${RST} ${BR_CYAN}%s${RST}\n\n" "$repo"
        render_github_dashboard "$repo"
    else
        printf "  ${TEXT_MUTED}Not in a Git repository or no remote detected${RST}\n\n"

        # Show demo pipeline
        printf "${BOLD}Demo Pipeline:${RST}\n"
        render_pipeline_ascii "Build|success" "Test|success" "Lint|success" "Deploy|running"
    fi

    printf "\n${TEXT_MUTED}─────────────────────────────────────────────────────────────────────────────${RST}\n"
    printf "  ${TEXT_SECONDARY}[r]efresh  [d]etails  [c]ancel  [t]rigger  [l]ocal CI  [q]uit${RST}\n"
}

cicd_dashboard_loop() {
    while true; do
        render_cicd_dashboard

        if read -rsn1 -t 5 key 2>/dev/null; then
            case "$key" in
                r|R) continue ;;
                d|D)
                    local repo=""
                    if git rev-parse --is-inside-work-tree &>/dev/null; then
                        local remote=$(git remote get-url origin 2>/dev/null)
                        repo=$(echo "$remote" | sed -E 's|.*github.com[:/]||' | sed 's|\.git$||')
                    fi

                    if [[ -n "$repo" ]]; then
                        printf "\n${BR_CYAN}Run ID to view details: ${RST}"
                        cursor_show
                        read -r run_id
                        cursor_hide
                        [[ -n "$run_id" ]] && render_github_run_details "$repo" "$run_id"
                        printf "\n${TEXT_MUTED}Press any key...${RST}"
                        read -rsn1
                    fi
                    ;;
                c|C)
                    local repo=""
                    if git rev-parse --is-inside-work-tree &>/dev/null; then
                        local remote=$(git remote get-url origin 2>/dev/null)
                        repo=$(echo "$remote" | sed -E 's|.*github.com[:/]||' | sed 's|\.git$||')
                    fi

                    if [[ -n "$repo" ]]; then
                        printf "\n${BR_CYAN}Run ID to cancel: ${RST}"
                        cursor_show
                        read -r run_id
                        cursor_hide
                        [[ -n "$run_id" ]] && gh_cancel_run "$repo" "$run_id"
                        printf "${BR_YELLOW}Cancelled run #%s${RST}\n" "$run_id"
                        sleep 1
                    fi
                    ;;
                t|T)
                    local repo=""
                    if git rev-parse --is-inside-work-tree &>/dev/null; then
                        local remote=$(git remote get-url origin 2>/dev/null)
                        repo=$(echo "$remote" | sed -E 's|.*github.com[:/]||' | sed 's|\.git$||')
                    fi

                    if [[ -n "$repo" ]]; then
                        printf "\n${BR_CYAN}Run ID to rerun: ${RST}"
                        cursor_show
                        read -r run_id
                        cursor_hide
                        [[ -n "$run_id" ]] && gh_rerun_workflow "$repo" "$run_id"
                        printf "${BR_GREEN}Triggered rerun for #%s${RST}\n" "$run_id"
                        sleep 1
                    fi
                    ;;
                l|L)
                    run_local_ci
                    printf "\n${TEXT_MUTED}Press any key...${RST}"
                    read -rsn1
                    ;;
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
        dashboard) cicd_dashboard_loop ;;
        github)    render_github_dashboard "$2" ;;
        gitlab)    gitlab_get_pipelines "$2" ;;
        local)     run_local_ci "$2" ;;
        status)
            if [[ -n "$2" ]]; then
                render_github_dashboard "$2"
            else
                # Try to detect from git remote
                local repo=""
                if git rev-parse --is-inside-work-tree &>/dev/null; then
                    local remote=$(git remote get-url origin 2>/dev/null)
                    repo=$(echo "$remote" | sed -E 's|.*github.com[:/]||' | sed 's|\.git$||')
                    render_github_dashboard "$repo"
                fi
            fi
            ;;
        *)
            printf "Usage: %s [dashboard|github|gitlab|local|status]\n" "$0"
            ;;
    esac
fi
