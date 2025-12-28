#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██╗  ██╗███████╗██╗   ██╗███████╗
#  ██║ ██╔╝██╔════╝╚██╗ ██╔╝██╔════╝
#  █████╔╝ █████╗   ╚████╔╝ ███████╗
#  ██╔═██╗ ██╔══╝    ╚██╔╝  ╚════██║
#  ██║  ██╗███████╗   ██║   ███████║
#  ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD KEYBOARD SHORTCUTS SYSTEM v2.0
#  Unified keybindings with help overlay and customization
#═══════════════════════════════════════════════════════════════════════════════

# Source core library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

SHORTCUTS_CONFIG="${BLACKROAD_CONFIG:-$HOME/.blackroad-dashboards}/shortcuts.json"

# Default keyboard shortcuts
declare -A DEFAULT_SHORTCUTS=(
    # Navigation
    ["q"]="quit|Quit/Exit"
    ["Q"]="quit_force|Force Quit"
    ["h"]="help|Show Help"
    ["?"]="help|Show Help"

    # Actions
    ["r"]="refresh|Refresh Data"
    ["R"]="refresh_full|Full Refresh"
    ["e"]="export|Export Data"
    ["E"]="export_all|Export All Formats"

    # Navigation
    ["j"]="down|Move Down"
    ["k"]="up|Move Up"
    ["l"]="right|Move Right"
    ["h"]="left|Move Left"
    ["g"]="top|Go to Top"
    ["G"]="bottom|Go to Bottom"

    # Arrow keys (escape sequences)
    ["\e[A"]="up|Move Up"
    ["\e[B"]="down|Move Down"
    ["\e[C"]="right|Move Right"
    ["\e[D"]="left|Move Left"

    # Tabs/Panels
    ["1"]="tab_1|Tab 1"
    ["2"]="tab_2|Tab 2"
    ["3"]="tab_3|Tab 3"
    ["4"]="tab_4|Tab 4"
    ["5"]="tab_5|Tab 5"
    ["Tab"]="next_tab|Next Tab"

    # Views
    ["s"]="ssh|SSH Connect"
    ["t"]="themes|Theme Selector"
    ["n"]="notifications|Notifications"
    ["a"]="analytics|Analytics View"
    ["m"]="metrics|System Metrics"
    ["d"]="details|Show Details"
    ["c"]="config|Configuration"

    # Search/Filter
    ["/"]="search|Search"
    ["f"]="filter|Filter"
    ["x"]="clear_filter|Clear Filter"

    # Toggle
    ["Space"]="select|Select/Toggle"
    ["Enter"]="confirm|Confirm/Open"
    ["Escape"]="cancel|Cancel/Back"

    # Special
    ["!"]="command|Command Mode"
    [":"]="command|Command Mode"
    ["p"]="pause|Pause Updates"
    ["z"]="zoom|Zoom Panel"
)

# Current active shortcuts (can be customized)
declare -A SHORTCUTS
for key in "${!DEFAULT_SHORTCUTS[@]}"; do
    SHORTCUTS[$key]="${DEFAULT_SHORTCUTS[$key]}"
done

#───────────────────────────────────────────────────────────────────────────────
# KEY READING
#───────────────────────────────────────────────────────────────────────────────

# Read a single key with timeout
read_key() {
    local timeout="${1:-0}"
    local key=""

    # Read first character
    if [[ $timeout -gt 0 ]]; then
        read -rsn1 -t "$timeout" key 2>/dev/null || return 1
    else
        read -rsn1 key 2>/dev/null || return 1
    fi

    # Handle escape sequences
    if [[ "$key" == $'\e' ]]; then
        local seq=""
        read -rsn1 -t 0.01 seq 2>/dev/null
        if [[ -n "$seq" ]]; then
            read -rsn1 -t 0.01 seq2 2>/dev/null
            key="$key$seq$seq2"

            # Extended sequences (F-keys, etc.)
            if [[ "$seq2" =~ [0-9] ]]; then
                local more=""
                read -rsn1 -t 0.01 more 2>/dev/null
                key="$key$more"
            fi
        fi
    fi

    echo "$key"
}

# Convert key to readable name
key_name() {
    local key="$1"

    case "$key" in
        $'\e')      echo "Escape" ;;
        $'\e[A')    echo "Up" ;;
        $'\e[B')    echo "Down" ;;
        $'\e[C')    echo "Right" ;;
        $'\e[D')    echo "Left" ;;
        $'\e[H')    echo "Home" ;;
        $'\e[F')    echo "End" ;;
        $'\e[5~')   echo "PageUp" ;;
        $'\e[6~')   echo "PageDown" ;;
        $'\e[2~')   echo "Insert" ;;
        $'\e[3~')   echo "Delete" ;;
        $'\eOP')    echo "F1" ;;
        $'\eOQ')    echo "F2" ;;
        $'\eOR')    echo "F3" ;;
        $'\eOS')    echo "F4" ;;
        $'\e[15~')  echo "F5" ;;
        $'\e[17~')  echo "F6" ;;
        $'\e[18~')  echo "F7" ;;
        $'\e[19~')  echo "F8" ;;
        $'\e[20~')  echo "F9" ;;
        $'\e[21~')  echo "F10" ;;
        $'\e[23~')  echo "F11" ;;
        $'\e[24~')  echo "F12" ;;
        $'\t')      echo "Tab" ;;
        $'\n')      echo "Enter" ;;
        ' ')        echo "Space" ;;
        $'\177')    echo "Backspace" ;;
        *)          echo "$key" ;;
    esac
}

# Get action for key
get_action() {
    local key="$1"
    local shortcut="${SHORTCUTS[$key]:-}"

    if [[ -n "$shortcut" ]]; then
        echo "${shortcut%%|*}"
    fi
}

# Get description for key
get_description() {
    local key="$1"
    local shortcut="${SHORTCUTS[$key]:-}"

    if [[ -n "$shortcut" ]]; then
        echo "${shortcut#*|}"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# HELP OVERLAY
#───────────────────────────────────────────────────────────────────────────────

# Show help overlay
show_help_overlay() {
    local width=70
    local height=25

    # Calculate position (centered)
    get_term_size
    local start_row=$(( (TERM_ROWS - height) / 2 ))
    local start_col=$(( (TERM_COLS - width) / 2 ))

    # Draw overlay background
    for ((row=0; row<height; row++)); do
        cursor_to $((start_row + row)) $start_col
        printf "${BR_BG_DARK}%${width}s${RST}" ""
    done

    # Draw border and content
    cursor_to $start_row $start_col
    printf "${BR_CYAN}╔"
    printf "%0.s═" $(seq 1 $((width - 2)))
    printf "╗${RST}"

    cursor_to $((start_row + 1)) $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}"
    printf "             ${BOLD}${BR_ORANGE}⌨️  KEYBOARD SHORTCUTS${RST}${BR_BG_DARK}              "
    printf "${BR_CYAN}║${RST}"

    cursor_to $((start_row + 2)) $start_col
    printf "${BR_CYAN}╠"
    printf "%0.s═" $(seq 1 $((width - 2)))
    printf "╣${RST}"

    # Categories
    local row=$((start_row + 3))

    # Navigation section
    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK} ${BOLD}${BR_GREEN}Navigation${RST}${BR_BG_DARK}%-56s${BR_CYAN}║${RST}" ""
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}   ${BR_YELLOW}↑/k${RST}${BR_BG_DARK} Up   ${BR_YELLOW}↓/j${RST}${BR_BG_DARK} Down   ${BR_YELLOW}←/h${RST}${BR_BG_DARK} Left   ${BR_YELLOW}→/l${RST}${BR_BG_DARK} Right     ${BR_CYAN}║${RST}"
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}   ${BR_YELLOW}g${RST}${BR_BG_DARK} Top   ${BR_YELLOW}G${RST}${BR_BG_DARK} Bottom   ${BR_YELLOW}1-5${RST}${BR_BG_DARK} Switch Tabs              ${BR_CYAN}║${RST}"
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}%-$((width-2))s${BR_CYAN}║${RST}" ""
    ((row++))

    # Actions section
    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK} ${BOLD}${BR_PURPLE}Actions${RST}${BR_BG_DARK}%-59s${BR_CYAN}║${RST}" ""
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}   ${BR_YELLOW}r${RST}${BR_BG_DARK} Refresh   ${BR_YELLOW}e${RST}${BR_BG_DARK} Export   ${BR_YELLOW}/${RST}${BR_BG_DARK} Search   ${BR_YELLOW}f${RST}${BR_BG_DARK} Filter      ${BR_CYAN}║${RST}"
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}   ${BR_YELLOW}Space${RST}${BR_BG_DARK} Select   ${BR_YELLOW}Enter${RST}${BR_BG_DARK} Confirm   ${BR_YELLOW}Esc${RST}${BR_BG_DARK} Cancel       ${BR_CYAN}║${RST}"
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}%-$((width-2))s${BR_CYAN}║${RST}" ""
    ((row++))

    # Views section
    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK} ${BOLD}${BR_PINK}Views${RST}${BR_BG_DARK}%-61s${BR_CYAN}║${RST}" ""
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}   ${BR_YELLOW}s${RST}${BR_BG_DARK} SSH   ${BR_YELLOW}t${RST}${BR_BG_DARK} Themes   ${BR_YELLOW}n${RST}${BR_BG_DARK} Notifications   ${BR_YELLOW}a${RST}${BR_BG_DARK} Analytics${BR_CYAN}║${RST}"
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}   ${BR_YELLOW}m${RST}${BR_BG_DARK} Metrics   ${BR_YELLOW}d${RST}${BR_BG_DARK} Details   ${BR_YELLOW}c${RST}${BR_BG_DARK} Config             ${BR_CYAN}║${RST}"
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}%-$((width-2))s${BR_CYAN}║${RST}" ""
    ((row++))

    # System section
    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK} ${BOLD}${BR_ORANGE}System${RST}${BR_BG_DARK}%-60s${BR_CYAN}║${RST}" ""
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}   ${BR_YELLOW}q${RST}${BR_BG_DARK} Quit   ${BR_YELLOW}?${RST}${BR_BG_DARK} Help   ${BR_YELLOW}p${RST}${BR_BG_DARK} Pause   ${BR_YELLOW}z${RST}${BR_BG_DARK} Zoom           ${BR_CYAN}║${RST}"
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}   ${BR_YELLOW}:${RST}${BR_BG_DARK} Command Mode   ${BR_YELLOW}!${RST}${BR_BG_DARK} Shell Command                 ${BR_CYAN}║${RST}"
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}%-$((width-2))s${BR_CYAN}║${RST}" ""
    ((row++))

    # Footer
    cursor_to $row $start_col
    printf "${BR_CYAN}╠"
    printf "%0.s═" $(seq 1 $((width - 2)))
    printf "╣${RST}"
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}║${RST}${BR_BG_DARK}    ${TEXT_MUTED}Press any key to close this help overlay...${RST}${BR_BG_DARK}           ${BR_CYAN}║${RST}"
    ((row++))

    cursor_to $row $start_col
    printf "${BR_CYAN}╚"
    printf "%0.s═" $(seq 1 $((width - 2)))
    printf "╝${RST}"

    # Wait for keypress
    read -rsn1

    # Clear overlay (caller should redraw screen)
}

# Show mini help bar
show_help_bar() {
    local shortcuts=("q:Quit" "r:Refresh" "e:Export" "t:Theme" "s:SSH" "?:Help")

    printf "${TEXT_MUTED}"
    for shortcut in "${shortcuts[@]}"; do
        local key="${shortcut%%:*}"
        local desc="${shortcut#*:}"
        printf "[${BR_YELLOW}%s${TEXT_MUTED}]%s  " "$key" "$desc"
    done
    printf "${RST}"
}

#───────────────────────────────────────────────────────────────────────────────
# KEY HANDLER INTEGRATION
#───────────────────────────────────────────────────────────────────────────────

# Main key handler - returns action name
handle_key() {
    local key="$1"
    local action=$(get_action "$key")

    echo "$action"
}

# Process key with callback
process_key_with_callback() {
    local key="$1"
    local callback="$2"

    local action=$(handle_key "$key")

    if [[ -n "$action" ]] && [[ -n "$callback" ]]; then
        "$callback" "$action" "$key"
    fi

    echo "$action"
}

# Interactive key handler loop
key_loop() {
    local callback="${1:-echo}"
    local timeout="${2:-0}"

    while true; do
        local key=$(read_key "$timeout")

        if [[ -n "$key" ]]; then
            local action=$(handle_key "$key")

            case "$action" in
                quit)       return 0 ;;
                quit_force) return 1 ;;
                help)       show_help_overlay ;;
                *)
                    if [[ -n "$action" ]]; then
                        "$callback" "$action" "$key"
                    fi
                    ;;
            esac
        fi
    done
}

#───────────────────────────────────────────────────────────────────────────────
# CUSTOMIZATION
#───────────────────────────────────────────────────────────────────────────────

# Add/modify shortcut
set_shortcut() {
    local key="$1"
    local action="$2"
    local description="$3"

    SHORTCUTS[$key]="$action|$description"
}

# Remove shortcut
remove_shortcut() {
    local key="$1"
    unset SHORTCUTS[$key]
}

# Reset to defaults
reset_shortcuts() {
    SHORTCUTS=()
    for key in "${!DEFAULT_SHORTCUTS[@]}"; do
        SHORTCUTS[$key]="${DEFAULT_SHORTCUTS[$key]}"
    done
}

# List all shortcuts
list_shortcuts() {
    printf "${BOLD}Current Keyboard Shortcuts:${RST}\n\n"

    printf "%-15s %-20s %s\n" "Key" "Action" "Description"
    printf "%s\n" "────────────────────────────────────────────────────────"

    for key in $(echo "${!SHORTCUTS[@]}" | tr ' ' '\n' | sort); do
        local action=$(get_action "$key")
        local desc=$(get_description "$key")
        local key_display=$(key_name "$key")

        printf "%-15s %-20s %s\n" "$key_display" "$action" "$desc"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        help)   show_help_overlay ;;
        bar)    show_help_bar; printf "\n" ;;
        list)   list_shortcuts ;;
        test)
            printf "Press keys to see their actions (q to quit):\n\n"
            key_loop echo
            ;;
        *)
            printf "Usage: %s [help|bar|list|test]\n" "$0"
            ;;
    esac
fi
