#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD PARALLEL EXECUTION LIBRARY v2.0
#  High-performance concurrent task execution with job management
#═══════════════════════════════════════════════════════════════════════════════

# Source core library if not already loaded
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "$BLACKROAD_CORE_LOADED" ]] && source "$SCRIPT_DIR/lib-core.sh"

# Prevent multiple inclusions
[[ -n "$BLACKROAD_PARALLEL_LOADED" ]] && return 0
export BLACKROAD_PARALLEL_LOADED=1

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

export PARALLEL_MAX_JOBS="${PARALLEL_MAX_JOBS:-8}"
export PARALLEL_TEMP_DIR="${BLACKROAD_TEMP:-/tmp/blackroad-$$}/parallel"
export PARALLEL_TIMEOUT="${PARALLEL_TIMEOUT:-30}"

# Ensure temp directory exists
mkdir -p "$PARALLEL_TEMP_DIR" 2>/dev/null

# Job tracking
declare -A PARALLEL_JOBS
declare -A PARALLEL_RESULTS
declare -A PARALLEL_STATUS
PARALLEL_JOB_COUNT=0

#───────────────────────────────────────────────────────────────────────────────
# JOB MANAGEMENT
#───────────────────────────────────────────────────────────────────────────────

# Generate unique job ID
parallel_job_id() {
    echo "job_$$_$((++PARALLEL_JOB_COUNT))_$(date +%s%N | tail -c 6)"
}

# Submit a job for parallel execution
parallel_submit() {
    local job_name="$1"
    shift
    local cmd=("$@")

    local job_id=$(parallel_job_id)
    local output_file="$PARALLEL_TEMP_DIR/${job_id}.out"
    local status_file="$PARALLEL_TEMP_DIR/${job_id}.status"
    local time_file="$PARALLEL_TEMP_DIR/${job_id}.time"

    # Wait if at max capacity
    while [[ $(jobs -r | wc -l) -ge $PARALLEL_MAX_JOBS ]]; do
        sleep 0.1
    done

    # Execute in background with timing
    (
        local start_time=$(date +%s%N)
        "${cmd[@]}" > "$output_file" 2>&1
        local exit_code=$?
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))  # milliseconds

        echo "$exit_code" > "$status_file"
        echo "$duration" > "$time_file"
    ) &

    local pid=$!
    PARALLEL_JOBS[$job_id]="$pid"
    PARALLEL_STATUS[$job_id]="running"

    log_debug "Parallel job submitted: $job_id ($job_name) - PID: $pid"
    echo "$job_id"
}

# Wait for a specific job to complete
parallel_wait_job() {
    local job_id="$1"
    local timeout="${2:-$PARALLEL_TIMEOUT}"

    local pid="${PARALLEL_JOBS[$job_id]}"
    [[ -z "$pid" ]] && return 1

    local start_time=$(date +%s)

    while kill -0 "$pid" 2>/dev/null; do
        local now=$(date +%s)
        if [[ $((now - start_time)) -gt $timeout ]]; then
            log_warn "Job $job_id timed out, killing..."
            kill -9 "$pid" 2>/dev/null
            PARALLEL_STATUS[$job_id]="timeout"
            return 124
        fi
        sleep 0.1
    done

    wait "$pid" 2>/dev/null
    PARALLEL_STATUS[$job_id]="completed"

    return 0
}

# Wait for all jobs to complete
parallel_wait_all() {
    local timeout="${1:-$PARALLEL_TIMEOUT}"

    for job_id in "${!PARALLEL_JOBS[@]}"; do
        parallel_wait_job "$job_id" "$timeout"
    done
}

# Get job result
parallel_get_result() {
    local job_id="$1"
    local output_file="$PARALLEL_TEMP_DIR/${job_id}.out"

    [[ -f "$output_file" ]] && cat "$output_file"
}

# Get job status
parallel_get_status() {
    local job_id="$1"
    local status_file="$PARALLEL_TEMP_DIR/${job_id}.status"

    if [[ -f "$status_file" ]]; then
        cat "$status_file"
    else
        echo "-1"
    fi
}

# Get job execution time (ms)
parallel_get_time() {
    local job_id="$1"
    local time_file="$PARALLEL_TEMP_DIR/${job_id}.time"

    if [[ -f "$time_file" ]]; then
        cat "$time_file"
    else
        echo "0"
    fi
}

# Check if job is complete
parallel_is_complete() {
    local job_id="$1"
    local status_file="$PARALLEL_TEMP_DIR/${job_id}.status"

    [[ -f "$status_file" ]]
}

#───────────────────────────────────────────────────────────────────────────────
# BATCH OPERATIONS
#───────────────────────────────────────────────────────────────────────────────

# Run multiple commands in parallel, return results as array
parallel_batch() {
    local -a commands=("$@")
    local -a job_ids=()
    local -a results=()

    # Submit all jobs
    for cmd in "${commands[@]}"; do
        local job_id=$(parallel_submit "batch" bash -c "$cmd")
        job_ids+=("$job_id")
    done

    # Wait for all to complete
    for job_id in "${job_ids[@]}"; do
        parallel_wait_job "$job_id"
        results+=("$(parallel_get_result "$job_id")")
    done

    # Return results (newline separated)
    printf '%s\n' "${results[@]}"
}

# Run function on each item in array (parallel map)
parallel_map() {
    local func="$1"
    shift
    local -a items=("$@")
    local -a job_ids=()

    # Submit jobs
    for item in "${items[@]}"; do
        local job_id=$(parallel_submit "map_$func" "$func" "$item")
        job_ids+=("$job_id")
    done

    # Collect results
    for job_id in "${job_ids[@]}"; do
        parallel_wait_job "$job_id"
        parallel_get_result "$job_id"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# API-SPECIFIC PARALLEL FETCHERS
#───────────────────────────────────────────────────────────────────────────────

# Fetch multiple URLs in parallel
parallel_fetch_urls() {
    local -a urls=("$@")
    local -a job_ids=()
    local -a results=()

    # Submit all fetch jobs
    for url in "${urls[@]}"; do
        local job_id=$(parallel_submit "fetch" curl -s --connect-timeout 10 "$url")
        job_ids+=("$job_id")
    done

    # Wait and collect results
    for i in "${!job_ids[@]}"; do
        parallel_wait_job "${job_ids[$i]}"
        local result=$(parallel_get_result "${job_ids[$i]}")
        local status=$(parallel_get_status "${job_ids[$i]}")
        local time=$(parallel_get_time "${job_ids[$i]}")

        # Output as JSON object
        printf '{"url":"%s","status":%s,"time_ms":%s,"data":%s}\n' \
            "${urls[$i]}" "$status" "$time" "${result:-null}"
    done
}

# Ping multiple hosts in parallel
parallel_ping_hosts() {
    local -a hosts=("$@")
    local -a job_ids=()

    # Submit ping jobs
    for host in "${hosts[@]}"; do
        local job_id=$(parallel_submit "ping_$host" ping -c 1 -W 2 "$host")
        job_ids+=("$job_id")
    done

    # Collect results
    for i in "${!job_ids[@]}"; do
        parallel_wait_job "${job_ids[$i]}"
        local status=$(parallel_get_status "${job_ids[$i]}")
        local time=$(parallel_get_time "${job_ids[$i]}")

        if [[ "$status" == "0" ]]; then
            printf '{"host":"%s","status":"online","latency_ms":%s}\n' "${hosts[$i]}" "$time"
        else
            printf '{"host":"%s","status":"offline","latency_ms":null}\n' "${hosts[$i]}"
        fi
    done
}

# Check multiple HTTP endpoints
parallel_http_check() {
    local -a endpoints=("$@")
    local -a job_ids=()

    for endpoint in "${endpoints[@]}"; do
        local job_id=$(parallel_submit "http_$endpoint" \
            curl -s -o /dev/null -w "%{http_code}|%{time_total}" --connect-timeout 5 "$endpoint")
        job_ids+=("$job_id")
    done

    for i in "${!job_ids[@]}"; do
        parallel_wait_job "${job_ids[$i]}"
        local result=$(parallel_get_result "${job_ids[$i]}")
        local code=$(echo "$result" | cut -d'|' -f1)
        local time=$(echo "$result" | cut -d'|' -f2)

        local status="up"
        [[ "$code" != "200" ]] && [[ "$code" != "201" ]] && [[ "$code" != "204" ]] && status="down"

        printf '{"url":"%s","http_code":%s,"response_time":"%s","status":"%s"}\n' \
            "${endpoints[$i]}" "${code:-0}" "${time:-0}" "$status"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# GITHUB API PARALLEL
#───────────────────────────────────────────────────────────────────────────────

# Fetch multiple GitHub repos in parallel
parallel_github_repos() {
    local -a repos=("$@")
    local -a job_ids=()
    local auth_header=""

    [[ -n "$GITHUB_TOKEN" ]] && auth_header="-H \"Authorization: token $GITHUB_TOKEN\""

    for repo in "${repos[@]}"; do
        local job_id=$(parallel_submit "gh_$repo" bash -c \
            "curl -s $auth_header 'https://api.github.com/repos/$repo'")
        job_ids+=("$job_id")
    done

    for job_id in "${job_ids[@]}"; do
        parallel_wait_job "$job_id"
        parallel_get_result "$job_id"
    done
}

# Fetch GitHub user data in parallel
parallel_github_users() {
    local -a users=("$@")
    local -a job_ids=()

    for user in "${users[@]}"; do
        local job_id=$(parallel_submit "gh_user_$user" \
            curl -s "https://api.github.com/users/$user")
        job_ids+=("$job_id")
    done

    for job_id in "${job_ids[@]}"; do
        parallel_wait_job "$job_id"
        parallel_get_result "$job_id"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# CLOUDFLARE API PARALLEL
#───────────────────────────────────────────────────────────────────────────────

# Fetch multiple Cloudflare zones in parallel
parallel_cloudflare_zones() {
    local -a zone_ids=("$@")
    local -a job_ids=()

    [[ -z "$CLOUDFLARE_TOKEN" ]] && { log_error "CLOUDFLARE_TOKEN not set"; return 1; }

    for zone_id in "${zone_ids[@]}"; do
        local job_id=$(parallel_submit "cf_$zone_id" bash -c \
            "curl -s -H 'Authorization: Bearer $CLOUDFLARE_TOKEN' \
             -H 'Content-Type: application/json' \
             'https://api.cloudflare.com/client/v4/zones/$zone_id'")
        job_ids+=("$job_id")
    done

    for job_id in "${job_ids[@]}"; do
        parallel_wait_job "$job_id"
        parallel_get_result "$job_id"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# DASHBOARD DATA PARALLEL FETCH
#───────────────────────────────────────────────────────────────────────────────

# Fetch all dashboard data in parallel (composite function)
parallel_fetch_dashboard_data() {
    local -a results=()

    # Submit all data fetches at once
    local github_job=$(parallel_submit "github" \
        curl -s "https://api.github.com/users/blackboxprogramming/repos?per_page=100")

    local crypto_btc=$(parallel_submit "btc" \
        curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true")

    local crypto_eth=$(parallel_submit "eth" \
        curl -s "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd&include_24hr_change=true")

    local crypto_sol=$(parallel_submit "sol" \
        curl -s "https://api.coingecko.com/api/v3/simple/price?ids=solana&vs_currencies=usd&include_24hr_change=true")

    local iss_job=$(parallel_submit "iss" \
        curl -s "http://api.open-notify.org/iss-now.json")

    local earthquakes_job=$(parallel_submit "earthquakes" \
        curl -s "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_hour.geojson")

    # Wait for all
    parallel_wait_all

    # Output combined results
    cat << EOF
{
    "github": $(parallel_get_result "$github_job"),
    "crypto": {
        "bitcoin": $(parallel_get_result "$crypto_btc"),
        "ethereum": $(parallel_get_result "$crypto_eth"),
        "solana": $(parallel_get_result "$crypto_sol")
    },
    "iss": $(parallel_get_result "$iss_job"),
    "earthquakes": $(parallel_get_result "$earthquakes_job"),
    "fetched_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "fetch_stats": {
        "github_ms": $(parallel_get_time "$github_job"),
        "crypto_btc_ms": $(parallel_get_time "$crypto_btc"),
        "crypto_eth_ms": $(parallel_get_time "$crypto_eth"),
        "crypto_sol_ms": $(parallel_get_time "$crypto_sol"),
        "iss_ms": $(parallel_get_time "$iss_job"),
        "earthquakes_ms": $(parallel_get_time "$earthquakes_job")
    }
}
EOF
}

#───────────────────────────────────────────────────────────────────────────────
# PROGRESS TRACKING
#───────────────────────────────────────────────────────────────────────────────

# Show parallel execution progress
parallel_show_progress() {
    local total="${1:-${#PARALLEL_JOBS[@]}}"
    local completed=0
    local running=0

    for job_id in "${!PARALLEL_JOBS[@]}"; do
        if parallel_is_complete "$job_id"; then
            ((completed++))
        else
            ((running++))
        fi
    done

    # Draw progress bar
    printf "\r${BR_CYAN}Jobs:${RST} "
    progress_bar "$completed" "$total" 20 "$BR_GREEN"
    printf " ${TEXT_SECONDARY}(%d/%d complete, %d running)${RST}" "$completed" "$total" "$running"
}

# Animated progress while waiting
parallel_progress_wait() {
    local refresh_interval="${1:-0.2}"
    local total=${#PARALLEL_JOBS[@]}
    local spin_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local spin_idx=0

    cursor_hide

    while true; do
        local completed=0
        local running=0

        for job_id in "${!PARALLEL_JOBS[@]}"; do
            if parallel_is_complete "$job_id"; then
                ((completed++))
            else
                ((running++))
            fi
        done

        # Draw progress
        printf "\r${BR_CYAN}${spin_chars:$spin_idx:1}${RST} Fetching data... "
        progress_bar "$completed" "$total" 25 "$BR_GREEN"
        printf " ${TEXT_MUTED}[%d/%d]${RST}" "$completed" "$total"

        [[ $completed -eq $total ]] && break

        spin_idx=$(( (spin_idx + 1) % 10 ))
        sleep "$refresh_interval"
    done

    cursor_show
    printf "\r%${TERM_COLS}s\r"  # Clear line
}

#───────────────────────────────────────────────────────────────────────────────
# CLEANUP
#───────────────────────────────────────────────────────────────────────────────

# Clean up parallel execution resources
parallel_cleanup() {
    # Kill any remaining jobs
    for job_id in "${!PARALLEL_JOBS[@]}"; do
        local pid="${PARALLEL_JOBS[$job_id]}"
        kill -9 "$pid" 2>/dev/null
    done

    # Clear temp files
    rm -rf "$PARALLEL_TEMP_DIR" 2>/dev/null

    # Reset state
    PARALLEL_JOBS=()
    PARALLEL_RESULTS=()
    PARALLEL_STATUS=()
    PARALLEL_JOB_COUNT=0

    log_debug "Parallel execution cleaned up"
}

# Add to cleanup trap
trap parallel_cleanup EXIT INT TERM

log_debug "BlackRoad Parallel Library v2.0 loaded"
