#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#   ██████╗ ██████╗ ███╗   ███╗███╗   ███╗ █████╗ ███╗   ██╗██████╗
#  ██╔════╝██╔═══██╗████╗ ████║████╗ ████║██╔══██╗████╗  ██║██╔══██╗
#  ██║     ██║   ██║██╔████╔██║██╔████╔██║███████║██╔██╗ ██║██║  ██║
#  ██║     ██║   ██║██║╚██╔╝██║██║╚██╔╝██║██╔══██║██║╚██╗██║██║  ██║
#  ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║██████╔╝
#   ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD COMMAND CENTER v3.0 ULTIMATE
#  Unified Control Interface - All Systems Under One Roof
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"
[[ -f "$SCRIPT_DIR/lib-cache.sh" ]] && source "$SCRIPT_DIR/lib-cache.sh"
[[ -f "$SCRIPT_DIR/lib-parallel.sh" ]] && source "$SCRIPT_DIR/lib-parallel.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

COMMAND_CENTER_VERSION="3.0.0"
STARTUP_TIME=$(date +%s)

# Module availability
declare -A MODULES=(
    [analytics]="analytics-dashboard.sh|📊 Analytics"
    [ai]="ai-insights-engine.sh|🧠 AI Insights"
    [security]="security-ops.sh|🔒 Security"
    [workflows]="workflow-engine.sh|⚡ Workflows"
    [3d]="terminal-3d.sh|🎮 3D Viz"
    [plugins]="plugin-system.sh|🔌 Plugins"
    [health]="health-check.sh|🏥 Health"
    [export]="data-export.sh|📤 Export"
    [notify]="notification-system.sh|🔔 Notify"
    [themes]="themes-premium.sh|🎨 Themes"
    [logs]="log-streaming.sh|📜 Logs"
)

# Current state
CURRENT_MODULE="home"
CURRENT_TAB=1
COMMAND_MODE=false
COMMAND_BUFFER=""

#───────────────────────────────────────────────────────────────────────────────
# ANIMATED INTRO
#───────────────────────────────────────────────────────────────────────────────

play_intro() {
    clear_screen
    cursor_hide

    local width=80
    local height=24

    # Matrix-style initialization effect
    for ((frame=0; frame<30; frame++)); do
        cursor_to 1 1

        for ((y=0; y<height; y++)); do
            for ((x=0; x<width; x++)); do
                if [[ $((RANDOM % 100)) -lt $((frame * 3)) ]]; then
                    printf " "
                else
                    local chars="01アイウエオカキクケコ"
                    local char="${chars:$((RANDOM % ${#chars})):1}"
                    printf "\033[38;2;0;$((50 + RANDOM % 200));$((RANDOM % 100))m%s" "$char"
                fi
            done
            printf "\n"
        done

        sleep 0.03
    done

    # Fade in logo
    for brightness in 30 60 90 120 150 180 210 240 255; do
        clear_screen
        printf "\033[38;2;%d;%d;%dm" "$brightness" "$((brightness/2))" "$((brightness/3))"

        cat << 'LOGO'


        ██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗  ██████╗  █████╗ ██████╗
        ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗
        ██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██║   ██║███████║██║  ██║
        ██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██╗██║   ██║██╔══██║██║  ██║
        ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝██║  ██║██████╔╝
        ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝

               ██████╗ ██████╗ ███╗   ███╗███╗   ███╗ █████╗ ███╗   ██╗██████╗
              ██╔════╝██╔═══██╗████╗ ████║████╗ ████║██╔══██╗████╗  ██║██╔══██╗
              ██║     ██║   ██║██╔████╔██║██╔████╔██║███████║██╔██╗ ██║██║  ██║
              ██║     ██║   ██║██║╚██╔╝██║██║╚██╔╝██║██╔══██║██║╚██╗██║██║  ██║
              ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║██████╔╝
               ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝

                      ██████╗███████╗███╗   ██╗████████╗███████╗██████╗
                     ██╔════╝██╔════╝████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
                     ██║     █████╗  ██╔██╗ ██║   ██║   █████╗  ██████╔╝
                     ██║     ██╔══╝  ██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗
                     ╚██████╗███████╗██║ ╚████║   ██║   ███████╗██║  ██║
                      ╚═════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝

LOGO
        printf "${RST}"
        sleep 0.05
    done

    # Show version
    printf "\n\n"
    printf "                           ${TEXT_MUTED}Version %s${RST}\n" "$COMMAND_CENTER_VERSION"
    printf "                    ${TEXT_SECONDARY}Initializing all systems...${RST}\n\n"

    # Loading bar
    local modules_count=${#MODULES[@]}
    local loaded=0

    for module in "${!MODULES[@]}"; do
        ((loaded++))
        local pct=$((loaded * 100 / modules_count))
        local filled=$((pct * 40 / 100))

        printf "\r                    ${BR_CYAN}"
        printf "%0.s█" $(seq 1 "$filled" 2>/dev/null) || true
        printf "${TEXT_MUTED}"
        printf "%0.s░" $(seq 1 $((40 - filled)) 2>/dev/null) || true
        printf "${RST} ${TEXT_SECONDARY}%3d%% Loading %s...${RST}" "$pct" "$module"

        sleep 0.1
    done

    printf "\n\n                    ${BR_GREEN}✓ All systems online${RST}\n"
    sleep 0.5
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN DASHBOARD PANELS
#───────────────────────────────────────────────────────────────────────────────

render_header() {
    local uptime_secs=$(($(date +%s) - STARTUP_TIME))
    local uptime_str=$(time_ago "$uptime_secs" 2>/dev/null || echo "${uptime_secs}s")

    printf "${BR_CYAN}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║  ██████╗  ██████╗ ███╗   ███╗███╗   ███╗ █████╗ ███╗   ██╗██████╗            ║\n"
    printf "║ ██╔════╝ ██╔═══██╗████╗ ████║████╗ ████║██╔══██╗████╗  ██║██╔══██╗           ║\n"
    printf "║ ██║      ██║   ██║██╔████╔██║██╔████╔██║███████║██╔██╗ ██║██║  ██║           ║\n"
    printf "║ ██║      ██║   ██║██║╚██╔╝██║██║╚██╔╝██║██╔══██║██║╚██╗██║██║  ██║           ║\n"
    printf "║ ╚██████╗ ╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║██████╔╝           ║\n"
    printf "║  ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝            ║\n"
    printf "║                     ${BR_ORANGE}C E N T E R   v%s${BR_CYAN}                               ║\n" "$COMMAND_CENTER_VERSION"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝${RST}\n"
    printf "  ${TEXT_MUTED}Session: %s │ Uptime: %s │ Modules: %d${RST}\n\n" "$(date '+%H:%M:%S')" "$uptime_str" "${#MODULES[@]}"
}

render_system_status() {
    local cpu=$(get_cpu_usage 2>/dev/null || echo "0")
    local mem=$(get_memory_usage 2>/dev/null || echo "0")
    local disk=$(get_disk_usage "/" 2>/dev/null || echo "0")

    printf "${BR_PURPLE}┌─ SYSTEM STATUS ──────────────────────────────────────────────────────────┐${RST}\n"
    printf "${BR_PURPLE}│${RST}                                                                          ${BR_PURPLE}│${RST}\n"

    # CPU Bar
    local cpu_color="$BR_GREEN"
    [[ $cpu -gt 70 ]] && cpu_color="$BR_YELLOW"
    [[ $cpu -gt 85 ]] && cpu_color="$BR_RED"

    printf "${BR_PURPLE}│${RST}  ${BOLD}CPU${RST}    "
    local cpu_filled=$((cpu * 30 / 100))
    printf "${cpu_color}"
    printf "%0.s█" $(seq 1 "$cpu_filled" 2>/dev/null) || true
    printf "${TEXT_MUTED}"
    printf "%0.s░" $(seq 1 $((30 - cpu_filled)) 2>/dev/null) || true
    printf "${RST} ${TEXT_SECONDARY}%3d%%${RST}                       ${BR_PURPLE}│${RST}\n" "$cpu"

    # Memory Bar
    local mem_color="$BR_GREEN"
    [[ $mem -gt 70 ]] && mem_color="$BR_YELLOW"
    [[ $mem -gt 85 ]] && mem_color="$BR_RED"

    printf "${BR_PURPLE}│${RST}  ${BOLD}MEM${RST}    "
    local mem_filled=$((mem * 30 / 100))
    printf "${mem_color}"
    printf "%0.s█" $(seq 1 "$mem_filled" 2>/dev/null) || true
    printf "${TEXT_MUTED}"
    printf "%0.s░" $(seq 1 $((30 - mem_filled)) 2>/dev/null) || true
    printf "${RST} ${TEXT_SECONDARY}%3d%%${RST}                       ${BR_PURPLE}│${RST}\n" "$mem"

    # Disk Bar
    local disk_color="$BR_GREEN"
    [[ $disk -gt 80 ]] && disk_color="$BR_YELLOW"
    [[ $disk -gt 90 ]] && disk_color="$BR_RED"

    printf "${BR_PURPLE}│${RST}  ${BOLD}DISK${RST}   "
    local disk_filled=$((disk * 30 / 100))
    printf "${disk_color}"
    printf "%0.s█" $(seq 1 "$disk_filled" 2>/dev/null) || true
    printf "${TEXT_MUTED}"
    printf "%0.s░" $(seq 1 $((30 - disk_filled)) 2>/dev/null) || true
    printf "${RST} ${TEXT_SECONDARY}%3d%%${RST}                       ${BR_PURPLE}│${RST}\n" "$disk"

    printf "${BR_PURPLE}│${RST}                                                                          ${BR_PURPLE}│${RST}\n"
    printf "${BR_PURPLE}└──────────────────────────────────────────────────────────────────────────┘${RST}\n\n"
}

render_module_grid() {
    printf "${BR_ORANGE}┌─ MODULES ─────────────────────────────────────────────────────────────────┐${RST}\n"
    printf "${BR_ORANGE}│${RST}                                                                          ${BR_ORANGE}│${RST}\n"

    local col=0
    local row_content=""

    for module in "${!MODULES[@]}"; do
        local info="${MODULES[$module]}"
        local file=$(echo "$info" | cut -d'|' -f1)
        local label=$(echo "$info" | cut -d'|' -f2)

        local available="${BR_GREEN}●${RST}"
        [[ ! -f "$SCRIPT_DIR/$file" ]] && available="${BR_RED}○${RST}"

        row_content+=$(printf "  ${available} ${BR_CYAN}%-2s${RST} ${TEXT_SECONDARY}%-12s${RST}" "${module:0:2}" "$label")

        ((col++))
        if [[ $col -ge 4 ]]; then
            printf "${BR_ORANGE}│${RST}%s${BR_ORANGE}│${RST}\n" "$row_content"
            row_content=""
            col=0
        fi
    done

    [[ -n "$row_content" ]] && printf "${BR_ORANGE}│${RST}%-74s${BR_ORANGE}│${RST}\n" "$row_content"

    printf "${BR_ORANGE}│${RST}                                                                          ${BR_ORANGE}│${RST}\n"
    printf "${BR_ORANGE}└──────────────────────────────────────────────────────────────────────────┘${RST}\n\n"
}

render_quick_actions() {
    printf "${BR_GREEN}┌─ QUICK ACTIONS ───────────────────────────────────────────────────────────┐${RST}\n"
    printf "${BR_GREEN}│${RST}                                                                          ${BR_GREEN}│${RST}\n"
    printf "${BR_GREEN}│${RST}  ${BR_YELLOW}[1]${RST} Analytics   ${BR_YELLOW}[2]${RST} AI Insights   ${BR_YELLOW}[3]${RST} Security   ${BR_YELLOW}[4]${RST} Workflows     ${BR_GREEN}│${RST}\n"
    printf "${BR_GREEN}│${RST}  ${BR_YELLOW}[5]${RST} 3D Viz      ${BR_YELLOW}[6]${RST} Plugins       ${BR_YELLOW}[7]${RST} Health     ${BR_YELLOW}[8]${RST} Logs          ${BR_GREEN}│${RST}\n"
    printf "${BR_GREEN}│${RST}                                                                          ${BR_GREEN}│${RST}\n"
    printf "${BR_GREEN}│${RST}  ${BR_PURPLE}[t]${RST} Themes   ${BR_PURPLE}[e]${RST} Export   ${BR_PURPLE}[n]${RST} Notify   ${BR_PURPLE}[:]${RST} Command   ${BR_PURPLE}[q]${RST} Quit       ${BR_GREEN}│${RST}\n"
    printf "${BR_GREEN}│${RST}                                                                          ${BR_GREEN}│${RST}\n"
    printf "${BR_GREEN}└──────────────────────────────────────────────────────────────────────────┘${RST}\n"
}

render_command_line() {
    if [[ "$COMMAND_MODE" == "true" ]]; then
        printf "\n${BR_YELLOW}:${RST}${COMMAND_BUFFER}█"
    else
        printf "\n${TEXT_MUTED}Press ':' for command mode${RST}"
    fi
}

render_home() {
    clear_screen
    render_header
    render_system_status
    render_module_grid
    render_quick_actions
    render_command_line
}

#───────────────────────────────────────────────────────────────────────────────
# MODULE LAUNCHER
#───────────────────────────────────────────────────────────────────────────────

launch_module() {
    local module_key="$1"

    local info="${MODULES[$module_key]:-}"
    [[ -z "$info" ]] && return 1

    local file=$(echo "$info" | cut -d'|' -f1)
    local label=$(echo "$info" | cut -d'|' -f2)

    local script="$SCRIPT_DIR/$file"
    [[ ! -f "$script" ]] && {
        printf "${BR_RED}Module not found: %s${RST}\n" "$file"
        sleep 1
        return 1
    }

    CURRENT_MODULE="$module_key"

    # Launch the module
    bash "$script"

    CURRENT_MODULE="home"
}

#───────────────────────────────────────────────────────────────────────────────
# COMMAND PROCESSOR
#───────────────────────────────────────────────────────────────────────────────

process_command() {
    local cmd="$1"

    case "$cmd" in
        q|quit|exit)
            return 1
            ;;
        help|h|\?)
            show_help
            ;;
        modules|mods)
            for m in "${!MODULES[@]}"; do
                echo "$m: ${MODULES[$m]}"
            done
            read -rsn1
            ;;
        open\ *)
            local module="${cmd#open }"
            launch_module "$module"
            ;;
        refresh|r)
            # Refresh current view
            ;;
        clear|cls)
            clear_screen
            ;;
        status)
            printf "CPU: %s%% | MEM: %s%% | DISK: %s%%\n" \
                "$(get_cpu_usage)" "$(get_memory_usage)" "$(get_disk_usage)"
            read -rsn1
            ;;
        version|ver)
            printf "BlackRoad Command Center v%s\n" "$COMMAND_CENTER_VERSION"
            read -rsn1
            ;;
        *)
            printf "${BR_RED}Unknown command: %s${RST}\n" "$cmd"
            sleep 1
            ;;
    esac

    return 0
}

show_help() {
    clear_screen
    printf "${BR_CYAN}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════╗\n"
    printf "║                    COMMAND CENTER HELP                       ║\n"
    printf "╚══════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    printf "${BOLD}Quick Keys:${RST}\n"
    printf "  ${BR_YELLOW}1-8${RST}     Launch modules (Analytics, AI, Security, etc.)\n"
    printf "  ${BR_YELLOW}t${RST}       Theme selector\n"
    printf "  ${BR_YELLOW}e${RST}       Export data\n"
    printf "  ${BR_YELLOW}n${RST}       Notifications\n"
    printf "  ${BR_YELLOW}:${RST}       Enter command mode\n"
    printf "  ${BR_YELLOW}q${RST}       Quit\n"

    printf "\n${BOLD}Commands (in : mode):${RST}\n"
    printf "  ${BR_CYAN}open <module>${RST}   Launch a module\n"
    printf "  ${BR_CYAN}modules${RST}         List all modules\n"
    printf "  ${BR_CYAN}status${RST}          Show system status\n"
    printf "  ${BR_CYAN}refresh${RST}         Refresh display\n"
    printf "  ${BR_CYAN}clear${RST}           Clear screen\n"
    printf "  ${BR_CYAN}help${RST}            Show this help\n"
    printf "  ${BR_CYAN}quit${RST}            Exit command center\n"

    printf "\n${TEXT_MUTED}Press any key to return...${RST}"
    read -rsn1
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN LOOP
#───────────────────────────────────────────────────────────────────────────────

main_loop() {
    while true; do
        render_home

        if [[ "$COMMAND_MODE" == "true" ]]; then
            # Command mode input
            read -rsn1 key

            case "$key" in
                $'\e')  # Escape - exit command mode
                    COMMAND_MODE=false
                    COMMAND_BUFFER=""
                    ;;
                $'\177'|$'\b')  # Backspace
                    COMMAND_BUFFER="${COMMAND_BUFFER%?}"
                    ;;
                '')  # Enter
                    COMMAND_MODE=false
                    if ! process_command "$COMMAND_BUFFER"; then
                        cursor_show
                        return
                    fi
                    COMMAND_BUFFER=""
                    ;;
                *)
                    COMMAND_BUFFER+="$key"
                    ;;
            esac
        else
            # Normal mode input
            if read -rsn1 -t 2 key 2>/dev/null; then
                case "$key" in
                    1) launch_module "analytics" ;;
                    2) launch_module "ai" ;;
                    3) launch_module "security" ;;
                    4) launch_module "workflows" ;;
                    5) launch_module "3d" ;;
                    6) launch_module "plugins" ;;
                    7) launch_module "health" ;;
                    8) launch_module "logs" ;;
                    t|T) launch_module "themes" ;;
                    e|E) launch_module "export" ;;
                    n|N) launch_module "notify" ;;
                    :)
                        COMMAND_MODE=true
                        COMMAND_BUFFER=""
                        ;;
                    q|Q)
                        cursor_show
                        clear_screen
                        printf "${BR_GREEN}Thanks for using BlackRoad Command Center!${RST}\n"
                        return
                        ;;
                    \?|h|H)
                        show_help
                        ;;
                esac
            fi
        fi
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-run}" in
        run)
            cursor_hide
            stty -echo 2>/dev/null

            # Play intro animation
            [[ "$2" != "--skip-intro" ]] && play_intro

            # Run main loop
            main_loop

            stty echo 2>/dev/null
            cursor_show
            ;;
        quick)
            # Quick start without intro
            cursor_hide
            stty -echo 2>/dev/null
            main_loop
            stty echo 2>/dev/null
            cursor_show
            ;;
        *)
            printf "Usage: %s [run|quick]\n" "$0"
            printf "       %s run              # Full experience with intro\n" "$0"
            printf "       %s quick            # Skip intro animation\n" "$0"
            ;;
    esac
fi
