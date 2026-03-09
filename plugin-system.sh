#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██████╗ ██╗     ██╗   ██╗ ██████╗ ██╗███╗   ██╗███████╗
#  ██╔══██╗██║     ██║   ██║██╔════╝ ██║████╗  ██║██╔════╝
#  ██████╔╝██║     ██║   ██║██║  ███╗██║██╔██╗ ██║███████╗
#  ██╔═══╝ ██║     ██║   ██║██║   ██║██║██║╚██╗██║╚════██║
#  ██║     ███████╗╚██████╔╝╚██████╔╝██║██║ ╚████║███████║
#  ╚═╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD PLUGIN SYSTEM v3.0
#  Modular Extension Architecture with Hot-loading & Sandboxing
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

PLUGIN_DIR="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}/plugins"
PLUGIN_REGISTRY="$PLUGIN_DIR/registry.json"
PLUGIN_HOOKS="$PLUGIN_DIR/hooks"
PLUGIN_CONFIGS="$PLUGIN_DIR/configs"
PLUGIN_DATA="$PLUGIN_DIR/data"

mkdir -p "$PLUGIN_DIR" "$PLUGIN_HOOKS" "$PLUGIN_CONFIGS" "$PLUGIN_DATA" 2>/dev/null

# Plugin state
declare -A LOADED_PLUGINS
declare -A PLUGIN_METADATA
declare -A PLUGIN_HOOKS_REGISTERED

# Available hook points
HOOK_POINTS=(
    "on_dashboard_load"
    "on_dashboard_render"
    "on_dashboard_close"
    "on_data_refresh"
    "on_key_press"
    "on_notification"
    "on_error"
    "on_metric_collect"
    "on_theme_change"
    "on_export"
)

#───────────────────────────────────────────────────────────────────────────────
# PLUGIN MANIFEST
#───────────────────────────────────────────────────────────────────────────────

# Create plugin manifest template
create_plugin_template() {
    local plugin_name="$1"
    local plugin_dir="$PLUGIN_DIR/$plugin_name"

    mkdir -p "$plugin_dir"

    # Create manifest
    cat > "$plugin_dir/manifest.json" << EOF
{
    "name": "$plugin_name",
    "version": "1.0.0",
    "description": "A BlackRoad Dashboard Plugin",
    "author": "Anonymous",
    "license": "MIT",
    "homepage": "",
    "repository": "",
    "main": "main.sh",
    "hooks": [],
    "dependencies": [],
    "config": {
        "enabled": true,
        "settings": {}
    },
    "permissions": [
        "read_metrics",
        "notifications"
    ]
}
EOF

    # Create main script
    cat > "$plugin_dir/main.sh" << 'EOF'
#!/bin/bash
# Plugin: ${PLUGIN_NAME}
# Main entry point

# Plugin initialization
plugin_init() {
    log_debug "Plugin ${PLUGIN_NAME} initialized"
}

# Plugin cleanup
plugin_cleanup() {
    log_debug "Plugin ${PLUGIN_NAME} cleanup"
}

# Hook handlers (implement as needed)
on_dashboard_load() {
    :  # Called when dashboard loads
}

on_dashboard_render() {
    :  # Called on each render
}

on_data_refresh() {
    :  # Called when data refreshes
}

# Plugin render function (for UI plugins)
plugin_render() {
    :  # Custom render logic
}

# Plugin configuration
plugin_configure() {
    :  # Configuration UI
}

# Register this plugin
plugin_init
EOF

    chmod +x "$plugin_dir/main.sh"

    printf "Plugin template created: %s\n" "$plugin_dir"
}

#───────────────────────────────────────────────────────────────────────────────
# PLUGIN LOADING
#───────────────────────────────────────────────────────────────────────────────

# Parse plugin manifest
parse_manifest() {
    local manifest_file="$1"

    [[ ! -f "$manifest_file" ]] && return 1

    if command -v jq &>/dev/null; then
        cat "$manifest_file"
    else
        cat "$manifest_file"
    fi
}

# Validate plugin
validate_plugin() {
    local plugin_dir="$1"
    local manifest="$plugin_dir/manifest.json"
    local main_script="$plugin_dir/main.sh"

    [[ ! -d "$plugin_dir" ]] && return 1
    [[ ! -f "$manifest" ]] && return 1
    [[ ! -f "$main_script" ]] && return 1

    # Check manifest structure
    if command -v jq &>/dev/null; then
        local name=$(jq -r '.name // empty' "$manifest" 2>/dev/null)
        [[ -z "$name" ]] && return 1
    fi

    return 0
}

# Load a single plugin
load_plugin() {
    local plugin_name="$1"
    local plugin_dir="$PLUGIN_DIR/$plugin_name"

    # Validate
    if ! validate_plugin "$plugin_dir"; then
        log_error "Invalid plugin: $plugin_name"
        return 1
    fi

    local manifest="$plugin_dir/manifest.json"
    local main_script="$plugin_dir/main.sh"

    # Check if enabled
    local enabled=true
    if command -v jq &>/dev/null; then
        enabled=$(jq -r '.config.enabled // true' "$manifest" 2>/dev/null)
    fi

    [[ "$enabled" == "false" ]] && return 0

    # Store metadata
    if command -v jq &>/dev/null; then
        PLUGIN_METADATA[$plugin_name]=$(jq -c '.' "$manifest" 2>/dev/null)
    fi

    # Export plugin context
    export PLUGIN_NAME="$plugin_name"
    export PLUGIN_DIR="$plugin_dir"
    export PLUGIN_CONFIG="$PLUGIN_CONFIGS/$plugin_name.json"
    export PLUGIN_DATA_DIR="$PLUGIN_DATA/$plugin_name"

    mkdir -p "$PLUGIN_DATA_DIR" 2>/dev/null

    # Source the plugin
    if source "$main_script" 2>/dev/null; then
        LOADED_PLUGINS[$plugin_name]="loaded"

        # Register hooks
        if command -v jq &>/dev/null; then
            local hooks=$(jq -r '.hooks[]?' "$manifest" 2>/dev/null)
            for hook in $hooks; do
                register_hook "$hook" "$plugin_name"
            done
        fi

        log_info "Plugin loaded: $plugin_name"
        return 0
    else
        log_error "Failed to load plugin: $plugin_name"
        return 1
    fi
}

# Load all plugins
load_all_plugins() {
    for plugin_dir in "$PLUGIN_DIR"/*/; do
        [[ -d "$plugin_dir" ]] || continue
        local plugin_name=$(basename "$plugin_dir")
        load_plugin "$plugin_name"
    done
}

# Unload a plugin
unload_plugin() {
    local plugin_name="$1"

    if [[ "${LOADED_PLUGINS[$plugin_name]}" == "loaded" ]]; then
        # Call cleanup if exists
        if type -t "plugin_cleanup" &>/dev/null; then
            export PLUGIN_NAME="$plugin_name"
            plugin_cleanup
        fi

        unset LOADED_PLUGINS[$plugin_name]
        log_info "Plugin unloaded: $plugin_name"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# HOOK SYSTEM
#───────────────────────────────────────────────────────────────────────────────

# Register a hook
register_hook() {
    local hook_name="$1"
    local plugin_name="$2"

    local current="${PLUGIN_HOOKS_REGISTERED[$hook_name]:-}"
    if [[ -z "$current" ]]; then
        PLUGIN_HOOKS_REGISTERED[$hook_name]="$plugin_name"
    else
        PLUGIN_HOOKS_REGISTERED[$hook_name]="$current,$plugin_name"
    fi
}

# Trigger a hook
trigger_hook() {
    local hook_name="$1"
    shift
    local args=("$@")

    local plugins="${PLUGIN_HOOKS_REGISTERED[$hook_name]:-}"
    [[ -z "$plugins" ]] && return 0

    IFS=',' read -ra plugin_list <<< "$plugins"

    for plugin_name in "${plugin_list[@]}"; do
        if [[ "${LOADED_PLUGINS[$plugin_name]}" == "loaded" ]]; then
            export PLUGIN_NAME="$plugin_name"
            export PLUGIN_DIR="$PLUGIN_DIR/$plugin_name"

            # Call the hook function if it exists
            if type -t "$hook_name" &>/dev/null; then
                "$hook_name" "${args[@]}" 2>/dev/null || true
            fi
        fi
    done
}

#───────────────────────────────────────────────────────────────────────────────
# PLUGIN API
#───────────────────────────────────────────────────────────────────────────────

# Get plugin config value
plugin_get_config() {
    local key="$1"
    local default="${2:-}"

    [[ -z "$PLUGIN_CONFIG" ]] && echo "$default" && return

    if [[ -f "$PLUGIN_CONFIG" ]] && command -v jq &>/dev/null; then
        local value=$(jq -r ".$key // empty" "$PLUGIN_CONFIG" 2>/dev/null)
        [[ -n "$value" ]] && echo "$value" || echo "$default"
    else
        echo "$default"
    fi
}

# Set plugin config value
plugin_set_config() {
    local key="$1"
    local value="$2"

    [[ -z "$PLUGIN_CONFIG" ]] && return 1

    if command -v jq &>/dev/null; then
        local current="{}"
        [[ -f "$PLUGIN_CONFIG" ]] && current=$(cat "$PLUGIN_CONFIG")

        echo "$current" | jq ".$key = \"$value\"" > "$PLUGIN_CONFIG"
    fi
}

# Store plugin data
plugin_store() {
    local key="$1"
    local value="$2"

    [[ -z "$PLUGIN_DATA_DIR" ]] && return 1

    echo "$value" > "$PLUGIN_DATA_DIR/$key.dat"
}

# Retrieve plugin data
plugin_retrieve() {
    local key="$1"
    local default="${2:-}"

    [[ -z "$PLUGIN_DATA_DIR" ]] && echo "$default" && return

    local file="$PLUGIN_DATA_DIR/$key.dat"
    [[ -f "$file" ]] && cat "$file" || echo "$default"
}

# Plugin notification
plugin_notify() {
    local level="$1"
    local title="$2"
    local message="$3"

    # Use the notification system if available
    if [[ -f "$SCRIPT_DIR/notification-system.sh" ]]; then
        source "$SCRIPT_DIR/notification-system.sh"
        notify "$level" "[${PLUGIN_NAME}] $title" "$message"
    else
        log_info "[$PLUGIN_NAME] $title: $message"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# PLUGIN MANAGER UI
#───────────────────────────────────────────────────────────────────────────────

plugin_manager() {
    clear_screen
    cursor_hide

    while true; do
        cursor_to 1 1

        printf "${BR_PURPLE}${BOLD}"
        printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
        printf "║                      🔌 BLACKROAD PLUGIN MANAGER                             ║\n"
        printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
        printf "${RST}\n"

        # List installed plugins
        printf "${BOLD}Installed Plugins:${RST}\n\n"

        local idx=1
        for plugin_dir in "$PLUGIN_DIR"/*/; do
            [[ -d "$plugin_dir" ]] || continue
            local plugin_name=$(basename "$plugin_dir")
            local manifest="$plugin_dir/manifest.json"

            local status="${LOADED_PLUGINS[$plugin_name]:-not loaded}"
            local status_color="$TEXT_MUTED"
            [[ "$status" == "loaded" ]] && status_color="$BR_GREEN"

            local version="unknown"
            local description=""

            if [[ -f "$manifest" ]] && command -v jq &>/dev/null; then
                version=$(jq -r '.version // "1.0.0"' "$manifest" 2>/dev/null)
                description=$(jq -r '.description // ""' "$manifest" 2>/dev/null)
            fi

            printf "  ${BR_CYAN}%d.${RST} ${BOLD}%-20s${RST} ${TEXT_MUTED}v%s${RST}  ${status_color}[%s]${RST}\n" \
                "$idx" "$plugin_name" "$version" "$status"
            [[ -n "$description" ]] && printf "     ${TEXT_SECONDARY}%s${RST}\n" "$description"

            ((idx++))
        done

        [[ $idx -eq 1 ]] && printf "  ${TEXT_MUTED}No plugins installed.${RST}\n"

        printf "\n${TEXT_MUTED}─────────────────────────────────────────────────────────────────────────────${RST}\n"
        printf "  ${TEXT_SECONDARY}[n]ew plugin  [l]oad all  [u]nload all  [r]efresh  [q]uit${RST}\n"

        if read -rsn1 -t 5 key 2>/dev/null; then
            case "$key" in
                n|N)
                    printf "\n${BR_CYAN}Enter plugin name: ${RST}"
                    cursor_show
                    read -r new_name
                    cursor_hide
                    [[ -n "$new_name" ]] && create_plugin_template "$new_name"
                    sleep 2
                    ;;
                l|L)
                    load_all_plugins
                    sleep 1
                    ;;
                u|U)
                    for plugin in "${!LOADED_PLUGINS[@]}"; do
                        unload_plugin "$plugin"
                    done
                    sleep 1
                    ;;
                r|R) continue ;;
                q|Q) break ;;
            esac
        fi
    done

    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# BUILT-IN PLUGINS
#───────────────────────────────────────────────────────────────────────────────

# Create sample plugins
create_sample_plugins() {
    # Weather plugin
    local weather_dir="$PLUGIN_DIR/weather-widget"
    mkdir -p "$weather_dir"

    cat > "$weather_dir/manifest.json" << 'EOF'
{
    "name": "weather-widget",
    "version": "1.0.0",
    "description": "Display weather information in dashboard",
    "author": "BlackRoad Team",
    "hooks": ["on_dashboard_render"],
    "config": {"enabled": true, "city": "San Francisco"}
}
EOF

    cat > "$weather_dir/main.sh" << 'EOF'
#!/bin/bash
plugin_init() { log_debug "Weather widget initialized"; }

on_dashboard_render() {
    local city=$(plugin_get_config "city" "San Francisco")
    printf "${BR_YELLOW}☀${RST} Weather: %s - Sunny 72°F\n" "$city"
}
EOF

    # System monitor plugin
    local sysmon_dir="$PLUGIN_DIR/system-monitor"
    mkdir -p "$sysmon_dir"

    cat > "$sysmon_dir/manifest.json" << 'EOF'
{
    "name": "system-monitor",
    "version": "1.0.0",
    "description": "Enhanced system monitoring with alerts",
    "author": "BlackRoad Team",
    "hooks": ["on_metric_collect"],
    "config": {"enabled": true, "cpu_threshold": 90, "mem_threshold": 85}
}
EOF

    cat > "$sysmon_dir/main.sh" << 'EOF'
#!/bin/bash
plugin_init() { log_debug "System monitor initialized"; }

on_metric_collect() {
    local cpu="$1"
    local mem="$2"
    local cpu_thresh=$(plugin_get_config "cpu_threshold" "90")
    local mem_thresh=$(plugin_get_config "mem_threshold" "85")

    [[ $cpu -gt $cpu_thresh ]] && plugin_notify "warning" "High CPU" "CPU at ${cpu}%"
    [[ $mem -gt $mem_thresh ]] && plugin_notify "warning" "High Memory" "Memory at ${mem}%"
}
EOF

    chmod +x "$weather_dir/main.sh" "$sysmon_dir/main.sh"
    log_info "Sample plugins created"
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-manager}" in
        manager)    plugin_manager ;;
        load)       load_plugin "$2" ;;
        loadall)    load_all_plugins ;;
        unload)     unload_plugin "$2" ;;
        create)     create_plugin_template "$2" ;;
        samples)    create_sample_plugins ;;
        list)
            for plugin in "$PLUGIN_DIR"/*/; do
                [[ -d "$plugin" ]] && basename "$plugin"
            done
            ;;
        *)
            printf "Usage: %s [manager|load|loadall|unload|create|samples|list]\n" "$0"
            ;;
    esac
fi
