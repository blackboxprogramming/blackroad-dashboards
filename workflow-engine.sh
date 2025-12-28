#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗███████╗██╗      ██████╗ ██╗    ██╗
#  ██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██║     ██╔═══██╗██║    ██║
#  ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ █████╗  ██║     ██║   ██║██║ █╗ ██║
#  ██║███╗██║██║   ██║██╔══██╗██╔═██╗ ██╔══╝  ██║     ██║   ██║██║███╗██║
#  ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗██║     ███████╗╚██████╔╝╚███╔███╔╝
#   ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD WORKFLOW AUTOMATION ENGINE v3.0
#  Visual Workflows, Triggers, Conditions, Actions, Schedules
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

WORKFLOW_DIR="${BLACKROAD_DATA:-$HOME/.blackroad-dashboards}/workflows"
WORKFLOW_LOGS="$WORKFLOW_DIR/logs"
WORKFLOW_STATE="$WORKFLOW_DIR/state"
mkdir -p "$WORKFLOW_DIR" "$WORKFLOW_LOGS" "$WORKFLOW_STATE" 2>/dev/null

# Workflow registry
declare -A WORKFLOWS
declare -A WORKFLOW_STATUS
declare -A WORKFLOW_LAST_RUN

# Execution tracking
declare -a EXECUTION_QUEUE
EXECUTION_RUNNING=0

#───────────────────────────────────────────────────────────────────────────────
# WORKFLOW DEFINITION
#───────────────────────────────────────────────────────────────────────────────

# Create a new workflow
workflow_create() {
    local name="$1"
    local description="${2:-}"
    local workflow_file="$WORKFLOW_DIR/${name}.workflow"

    cat > "$workflow_file" << EOF
{
    "name": "$name",
    "description": "$description",
    "version": "1.0.0",
    "enabled": true,
    "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "triggers": [],
    "conditions": [],
    "actions": [],
    "on_success": [],
    "on_failure": [],
    "settings": {
        "timeout": 300,
        "retry_count": 3,
        "retry_delay": 10,
        "parallel": false,
        "log_level": "info"
    }
}
EOF

    WORKFLOWS[$name]="$workflow_file"
    log_info "Workflow created: $name"
    echo "$workflow_file"
}

# Load workflow from file
workflow_load() {
    local workflow_file="$1"

    [[ ! -f "$workflow_file" ]] && return 1

    if command -v jq &>/dev/null; then
        local name=$(jq -r '.name' "$workflow_file" 2>/dev/null)
        [[ -n "$name" ]] && WORKFLOWS[$name]="$workflow_file"
    fi
}

# Load all workflows
workflow_load_all() {
    for file in "$WORKFLOW_DIR"/*.workflow; do
        [[ -f "$file" ]] && workflow_load "$file"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# TRIGGERS
#───────────────────────────────────────────────────────────────────────────────

# Available trigger types
declare -A TRIGGER_TYPES=(
    [schedule]="Run on schedule (cron expression)"
    [webhook]="HTTP webhook trigger"
    [file_change]="File system changes"
    [metric_threshold]="Metric exceeds threshold"
    [event]="Custom event trigger"
    [startup]="Run on system startup"
    [manual]="Manual trigger only"
)

# Add trigger to workflow
workflow_add_trigger() {
    local workflow_name="$1"
    local trigger_type="$2"
    shift 2
    local trigger_config="$*"

    local workflow_file="${WORKFLOWS[$workflow_name]}"
    [[ ! -f "$workflow_file" ]] && return 1

    local trigger_json=$(cat << EOF
{
    "type": "$trigger_type",
    "config": $trigger_config,
    "enabled": true,
    "id": "trigger_$(date +%s)"
}
EOF
)

    if command -v jq &>/dev/null; then
        jq ".triggers += [$trigger_json]" "$workflow_file" > "${workflow_file}.tmp"
        mv "${workflow_file}.tmp" "$workflow_file"
    fi
}

# Check if trigger should fire
trigger_check() {
    local trigger_type="$1"
    local trigger_config="$2"

    case "$trigger_type" in
        schedule)
            # Parse cron expression and check
            local cron_expr="$trigger_config"
            # Simplified: check if current time matches (implement full cron later)
            return 0
            ;;
        metric_threshold)
            local metric=$(echo "$trigger_config" | jq -r '.metric' 2>/dev/null)
            local operator=$(echo "$trigger_config" | jq -r '.operator' 2>/dev/null)
            local value=$(echo "$trigger_config" | jq -r '.value' 2>/dev/null)

            local current
            case "$metric" in
                cpu) current=$(get_cpu_usage 2>/dev/null || echo "0") ;;
                memory) current=$(get_memory_usage 2>/dev/null || echo "0") ;;
                disk) current=$(get_disk_usage "/" 2>/dev/null || echo "0") ;;
            esac

            case "$operator" in
                ">"|"gt")  [[ $current -gt $value ]] && return 0 ;;
                "<"|"lt")  [[ $current -lt $value ]] && return 0 ;;
                ">="|"gte") [[ $current -ge $value ]] && return 0 ;;
                "<="|"lte") [[ $current -le $value ]] && return 0 ;;
                "="|"eq")  [[ $current -eq $value ]] && return 0 ;;
            esac
            return 1
            ;;
        manual)
            return 1  # Never auto-trigger
            ;;
        *)
            return 1
            ;;
    esac
}

#───────────────────────────────────────────────────────────────────────────────
# CONDITIONS
#───────────────────────────────────────────────────────────────────────────────

# Add condition to workflow
workflow_add_condition() {
    local workflow_name="$1"
    local condition_type="$2"
    local condition_config="$3"

    local workflow_file="${WORKFLOWS[$workflow_name]}"
    [[ ! -f "$workflow_file" ]] && return 1

    local condition_json=$(cat << EOF
{
    "type": "$condition_type",
    "config": $condition_config,
    "id": "cond_$(date +%s)"
}
EOF
)

    if command -v jq &>/dev/null; then
        jq ".conditions += [$condition_json]" "$workflow_file" > "${workflow_file}.tmp"
        mv "${workflow_file}.tmp" "$workflow_file"
    fi
}

# Evaluate condition
condition_evaluate() {
    local condition_type="$1"
    local condition_config="$2"

    case "$condition_type" in
        time_window)
            local start_hour=$(echo "$condition_config" | jq -r '.start_hour' 2>/dev/null)
            local end_hour=$(echo "$condition_config" | jq -r '.end_hour' 2>/dev/null)
            local current_hour=$(date +%H)

            [[ $current_hour -ge $start_hour && $current_hour -lt $end_hour ]] && return 0
            return 1
            ;;
        weekday)
            local allowed_days=$(echo "$condition_config" | jq -r '.days[]' 2>/dev/null)
            local current_day=$(date +%u)  # 1-7, Monday is 1

            echo "$allowed_days" | grep -q "$current_day" && return 0
            return 1
            ;;
        host_alive)
            local host=$(echo "$condition_config" | jq -r '.host' 2>/dev/null)
            ping -c 1 -W 2 "$host" &>/dev/null && return 0
            return 1
            ;;
        file_exists)
            local path=$(echo "$condition_config" | jq -r '.path' 2>/dev/null)
            [[ -f "$path" ]] && return 0
            return 1
            ;;
        always)
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

#───────────────────────────────────────────────────────────────────────────────
# ACTIONS
#───────────────────────────────────────────────────────────────────────────────

# Available action types
declare -A ACTION_TYPES=(
    [shell]="Execute shell command"
    [script]="Run script file"
    [notify]="Send notification"
    [http]="HTTP request"
    [ssh]="Remote SSH command"
    [email]="Send email"
    [slack]="Send Slack message"
    [wait]="Wait/delay"
    [log]="Log message"
    [export]="Export data"
    [restart_service]="Restart a service"
    [scale]="Scale resources"
)

# Add action to workflow
workflow_add_action() {
    local workflow_name="$1"
    local action_type="$2"
    local action_config="$3"

    local workflow_file="${WORKFLOWS[$workflow_name]}"
    [[ ! -f "$workflow_file" ]] && return 1

    local action_json=$(cat << EOF
{
    "type": "$action_type",
    "config": $action_config,
    "id": "action_$(date +%s)",
    "timeout": 60
}
EOF
)

    if command -v jq &>/dev/null; then
        jq ".actions += [$action_json]" "$workflow_file" > "${workflow_file}.tmp"
        mv "${workflow_file}.tmp" "$workflow_file"
    fi
}

# Execute action
action_execute() {
    local action_type="$1"
    local action_config="$2"
    local workflow_context="$3"

    local start_time=$(date +%s)
    local result=""
    local exit_code=0

    case "$action_type" in
        shell)
            local command=$(echo "$action_config" | jq -r '.command' 2>/dev/null)
            result=$(eval "$command" 2>&1) || exit_code=$?
            ;;
        script)
            local script_path=$(echo "$action_config" | jq -r '.path' 2>/dev/null)
            local args=$(echo "$action_config" | jq -r '.args // ""' 2>/dev/null)
            result=$(bash "$script_path" $args 2>&1) || exit_code=$?
            ;;
        notify)
            local level=$(echo "$action_config" | jq -r '.level // "info"' 2>/dev/null)
            local title=$(echo "$action_config" | jq -r '.title' 2>/dev/null)
            local message=$(echo "$action_config" | jq -r '.message' 2>/dev/null)

            if [[ -f "$SCRIPT_DIR/notification-system.sh" ]]; then
                source "$SCRIPT_DIR/notification-system.sh"
                notify "$level" "$title" "$message"
            fi
            result="Notification sent"
            ;;
        http)
            local url=$(echo "$action_config" | jq -r '.url' 2>/dev/null)
            local method=$(echo "$action_config" | jq -r '.method // "GET"' 2>/dev/null)
            local body=$(echo "$action_config" | jq -r '.body // ""' 2>/dev/null)

            case "$method" in
                GET)  result=$(curl -s "$url" 2>&1) || exit_code=$? ;;
                POST) result=$(curl -s -X POST -d "$body" "$url" 2>&1) || exit_code=$? ;;
            esac
            ;;
        ssh)
            local host=$(echo "$action_config" | jq -r '.host' 2>/dev/null)
            local command=$(echo "$action_config" | jq -r '.command' 2>/dev/null)
            result=$(ssh -o ConnectTimeout=10 "$host" "$command" 2>&1) || exit_code=$?
            ;;
        wait)
            local seconds=$(echo "$action_config" | jq -r '.seconds // 1' 2>/dev/null)
            sleep "$seconds"
            result="Waited ${seconds}s"
            ;;
        log)
            local message=$(echo "$action_config" | jq -r '.message' 2>/dev/null)
            local level=$(echo "$action_config" | jq -r '.level // "info"' 2>/dev/null)
            log "$level" "$message"
            result="Logged"
            ;;
        export)
            local format=$(echo "$action_config" | jq -r '.format // "json"' 2>/dev/null)
            local data_type=$(echo "$action_config" | jq -r '.data_type // "snapshot"' 2>/dev/null)

            if [[ -f "$SCRIPT_DIR/data-export.sh" ]]; then
                source "$SCRIPT_DIR/data-export.sh"
                result=$(scheduled_export "$data_type" "$format")
            fi
            ;;
        *)
            result="Unknown action type: $action_type"
            exit_code=1
            ;;
    esac

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo "{\"exit_code\": $exit_code, \"duration\": $duration, \"result\": \"$(echo "$result" | head -c 500 | tr '\n' ' ')\"}"
    return $exit_code
}

#───────────────────────────────────────────────────────────────────────────────
# WORKFLOW EXECUTION
#───────────────────────────────────────────────────────────────────────────────

# Execute a workflow
workflow_execute() {
    local workflow_name="$1"
    local trigger_source="${2:-manual}"

    local workflow_file="${WORKFLOWS[$workflow_name]}"
    [[ ! -f "$workflow_file" ]] && {
        log_error "Workflow not found: $workflow_name"
        return 1
    }

    local execution_id="exec_$(date +%s%N)"
    local log_file="$WORKFLOW_LOGS/${workflow_name}_${execution_id}.log"

    WORKFLOW_STATUS[$workflow_name]="running"
    log_info "Executing workflow: $workflow_name (ID: $execution_id)"

    {
        echo "=== Workflow Execution ==="
        echo "Name: $workflow_name"
        echo "ID: $execution_id"
        echo "Trigger: $trigger_source"
        echo "Started: $(date)"
        echo "=========================="
        echo ""
    } > "$log_file"

    # Check conditions
    if command -v jq &>/dev/null; then
        local conditions=$(jq -c '.conditions[]?' "$workflow_file" 2>/dev/null)

        while IFS= read -r condition; do
            [[ -z "$condition" ]] && continue

            local cond_type=$(echo "$condition" | jq -r '.type')
            local cond_config=$(echo "$condition" | jq -c '.config')

            if ! condition_evaluate "$cond_type" "$cond_config"; then
                log_warn "Workflow condition not met: $cond_type"
                echo "SKIPPED: Condition not met ($cond_type)" >> "$log_file"
                WORKFLOW_STATUS[$workflow_name]="skipped"
                return 0
            fi
        done <<< "$conditions"
    fi

    # Execute actions
    local success=true
    local action_count=0

    if command -v jq &>/dev/null; then
        local actions=$(jq -c '.actions[]?' "$workflow_file" 2>/dev/null)

        while IFS= read -r action; do
            [[ -z "$action" ]] && continue

            ((action_count++))
            local action_type=$(echo "$action" | jq -r '.type')
            local action_config=$(echo "$action" | jq -c '.config')
            local action_id=$(echo "$action" | jq -r '.id')

            echo "--- Action $action_count: $action_type ($action_id) ---" >> "$log_file"

            local result
            result=$(action_execute "$action_type" "$action_config" "$workflow_name")
            local exit_code=$?

            echo "Result: $result" >> "$log_file"
            echo "" >> "$log_file"

            if [[ $exit_code -ne 0 ]]; then
                success=false
                log_error "Action failed: $action_type (exit: $exit_code)"

                # Check if we should continue on error
                local continue_on_error=$(jq -r '.settings.continue_on_error // false' "$workflow_file" 2>/dev/null)
                [[ "$continue_on_error" != "true" ]] && break
            fi
        done <<< "$actions"
    fi

    # Execute on_success or on_failure hooks
    local hook_type="on_success"
    [[ "$success" != "true" ]] && hook_type="on_failure"

    if command -v jq &>/dev/null; then
        local hooks=$(jq -c ".${hook_type}[]?" "$workflow_file" 2>/dev/null)

        while IFS= read -r hook; do
            [[ -z "$hook" ]] && continue
            local hook_type=$(echo "$hook" | jq -r '.type')
            local hook_config=$(echo "$hook" | jq -c '.config')
            action_execute "$hook_type" "$hook_config" "$workflow_name" >> "$log_file" 2>&1
        done <<< "$hooks"
    fi

    # Update status
    local final_status="completed"
    [[ "$success" != "true" ]] && final_status="failed"

    WORKFLOW_STATUS[$workflow_name]="$final_status"
    WORKFLOW_LAST_RUN[$workflow_name]=$(date +%s)

    {
        echo ""
        echo "=========================="
        echo "Completed: $(date)"
        echo "Status: $final_status"
        echo "Actions: $action_count"
    } >> "$log_file"

    log_info "Workflow $workflow_name completed: $final_status"
    return $([[ "$success" == "true" ]] && echo 0 || echo 1)
}

#───────────────────────────────────────────────────────────────────────────────
# WORKFLOW BUILDER UI
#───────────────────────────────────────────────────────────────────────────────

workflow_builder() {
    clear_screen
    cursor_hide

    local current_workflow=""
    local mode="list"

    while true; do
        cursor_to 1 1

        printf "${BR_ORANGE}${BOLD}"
        printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
        printf "║                    ⚡ BLACKROAD WORKFLOW ENGINE                              ║\n"
        printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
        printf "${RST}\n"

        case "$mode" in
            list)
                printf "${BOLD}Available Workflows:${RST}\n\n"

                local idx=1
                for name in "${!WORKFLOWS[@]}"; do
                    local file="${WORKFLOWS[$name]}"
                    local status="${WORKFLOW_STATUS[$name]:-idle}"
                    local last_run="${WORKFLOW_LAST_RUN[$name]:-never}"

                    local status_color="$TEXT_MUTED"
                    case "$status" in
                        running)   status_color="$BR_CYAN" ;;
                        completed) status_color="$BR_GREEN" ;;
                        failed)    status_color="$BR_RED" ;;
                    esac

                    [[ "$last_run" != "never" ]] && last_run=$(time_ago "$(($(date +%s) - last_run))")

                    printf "  ${BR_ORANGE}%d.${RST} ${BOLD}%-25s${RST} ${status_color}[%-10s]${RST} ${TEXT_MUTED}Last: %s${RST}\n" \
                        "$idx" "$name" "$status" "$last_run"
                    ((idx++))
                done

                [[ $idx -eq 1 ]] && printf "  ${TEXT_MUTED}No workflows defined.${RST}\n"

                printf "\n${TEXT_MUTED}─────────────────────────────────────────────────────────────────────────────${RST}\n"
                printf "  ${TEXT_SECONDARY}[n]ew  [r]un <name>  [e]dit <name>  [d]elete <name>  [l]ogs  [q]uit${RST}\n"
                ;;
        esac

        printf "\n${BR_CYAN}> ${RST}"
        cursor_show
        read -r cmd args
        cursor_hide

        case "$cmd" in
            n|new)
                printf "${BR_CYAN}Workflow name: ${RST}"
                cursor_show
                read -r wf_name
                cursor_hide

                printf "${BR_CYAN}Description: ${RST}"
                cursor_show
                read -r wf_desc
                cursor_hide

                workflow_create "$wf_name" "$wf_desc"
                workflow_load_all
                printf "${BR_GREEN}Workflow created!${RST}"
                sleep 1
                ;;
            r|run)
                if [[ -n "$args" ]]; then
                    printf "${BR_CYAN}Running workflow: $args${RST}\n"
                    workflow_execute "$args" "manual"
                fi
                sleep 2
                ;;
            d|delete)
                if [[ -n "$args" ]] && [[ -f "${WORKFLOWS[$args]}" ]]; then
                    rm -f "${WORKFLOWS[$args]}"
                    unset WORKFLOWS[$args]
                    printf "${BR_GREEN}Workflow deleted.${RST}"
                    sleep 1
                fi
                ;;
            l|logs)
                printf "\n${BOLD}Recent Logs:${RST}\n"
                ls -lt "$WORKFLOW_LOGS"/*.log 2>/dev/null | head -10
                printf "\n${TEXT_MUTED}Press any key...${RST}"
                read -rsn1
                ;;
            q|quit)
                break
                ;;
        esac
    done

    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# SAMPLE WORKFLOWS
#───────────────────────────────────────────────────────────────────────────────

create_sample_workflows() {
    # High CPU Alert workflow
    workflow_create "high-cpu-alert" "Alert when CPU exceeds 90%"
    workflow_add_trigger "high-cpu-alert" "metric_threshold" '{"metric": "cpu", "operator": ">", "value": 90}'
    workflow_add_action "high-cpu-alert" "notify" '{"level": "warning", "title": "High CPU Alert", "message": "CPU usage exceeded 90%"}'
    workflow_add_action "high-cpu-alert" "log" '{"level": "warn", "message": "High CPU detected by workflow"}'

    # Daily backup workflow
    workflow_create "daily-backup" "Daily system state backup"
    workflow_add_condition "daily-backup" "time_window" '{"start_hour": 2, "end_hour": 4}'
    workflow_add_action "daily-backup" "export" '{"format": "json", "data_type": "snapshot"}'
    workflow_add_action "daily-backup" "notify" '{"level": "info", "title": "Backup Complete", "message": "Daily backup finished"}'

    # Health check workflow
    workflow_create "health-check" "Periodic health verification"
    workflow_add_action "health-check" "shell" '{"command": "echo Health check at $(date)"}'
    workflow_add_action "health-check" "http" '{"url": "https://api.github.com", "method": "GET"}'

    log_info "Sample workflows created"
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

# Auto-load workflows
workflow_load_all

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-builder}" in
        builder)    workflow_builder ;;
        run)        workflow_execute "$2" "${3:-cli}" ;;
        create)     workflow_create "$2" "$3" ;;
        list)
            for name in "${!WORKFLOWS[@]}"; do
                echo "$name: ${WORKFLOWS[$name]}"
            done
            ;;
        samples)    create_sample_workflows ;;
        *)
            printf "Usage: %s [builder|run|create|list|samples]\n" "$0"
            printf "       %s run <workflow_name>\n" "$0"
            ;;
    esac
fi
