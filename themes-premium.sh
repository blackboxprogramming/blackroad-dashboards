#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ████████╗██╗  ██╗███████╗███╗   ███╗███████╗███████╗
#  ╚══██╔══╝██║  ██║██╔════╝████╗ ████║██╔════╝██╔════╝
#     ██║   ███████║█████╗  ██╔████╔██║█████╗  ███████╗
#     ██║   ██╔══██║██╔══╝  ██║╚██╔╝██║██╔══╝  ╚════██║
#     ██║   ██║  ██║███████╗██║ ╚═╝ ██║███████╗███████║
#     ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD PREMIUM THEMES v2.0
#  Advanced color themes with gradients, animations, and presets
#═══════════════════════════════════════════════════════════════════════════════

# Source core library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# THEME CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

THEME_HOME="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}/themes"
CURRENT_THEME_FILE="$THEME_HOME/.current_theme"
mkdir -p "$THEME_HOME" 2>/dev/null

# Current active theme
CURRENT_THEME="${CURRENT_THEME:-cyberpunk}"

#───────────────────────────────────────────────────────────────────────────────
# PREMIUM THEME DEFINITIONS
#───────────────────────────────────────────────────────────────────────────────

# Each theme defines: PRIMARY, SECONDARY, ACCENT, SUCCESS, WARNING, ERROR, BG, TEXT

declare -A THEME_CYBERPUNK=(
    [name]="Cyberpunk"
    [description]="Neon-soaked futuristic vibes"
    [PRIMARY]="255;0;128"      # Hot pink
    [SECONDARY]="0;255;255"    # Cyan
    [ACCENT]="255;255;0"       # Yellow
    [SUCCESS]="0;255;128"      # Neon green
    [WARNING]="255;165;0"      # Orange
    [ERROR]="255;0;64"         # Red
    [BG]="15;15;35"            # Dark blue
    [TEXT]="255;255;255"       # White
    [MUTED]="128;128;180"      # Muted purple
    [BORDER]="128;0;255"       # Purple
    [GRADIENT1]="255;0;128"
    [GRADIENT2]="128;0;255"
    [GRADIENT3]="0;128;255"
)

declare -A THEME_MIDNIGHT=(
    [name]="Midnight"
    [description]="Deep space darkness"
    [PRIMARY]="100;149;237"    # Cornflower blue
    [SECONDARY]="138;43;226"   # Blue violet
    [ACCENT]="255;215;0"       # Gold
    [SUCCESS]="50;205;50"      # Lime green
    [WARNING]="255;140;0"      # Dark orange
    [ERROR]="220;20;60"        # Crimson
    [BG]="10;10;20"            # Near black
    [TEXT]="230;230;250"       # Lavender
    [MUTED]="70;70;90"         # Dark gray
    [BORDER]="72;61;139"       # Dark slate blue
    [GRADIENT1]="25;25;112"
    [GRADIENT2]="72;61;139"
    [GRADIENT3]="138;43;226"
)

declare -A THEME_AURORA=(
    [name]="Aurora"
    [description]="Northern lights inspired"
    [PRIMARY]="0;255;128"      # Spring green
    [SECONDARY]="0;191;255"    # Deep sky blue
    [ACCENT]="255;0;255"       # Magenta
    [SUCCESS]="127;255;0"      # Chartreuse
    [WARNING]="255;215;0"      # Gold
    [ERROR]="255;69;0"         # Orange red
    [BG]="5;15;25"             # Dark teal
    [TEXT]="240;255;255"       # Azure
    [MUTED]="95;158;160"       # Cadet blue
    [BORDER]="0;139;139"       # Dark cyan
    [GRADIENT1]="0;100;0"
    [GRADIENT2]="0;191;255"
    [GRADIENT3]="138;43;226"
)

declare -A THEME_VOLCANO=(
    [name]="Volcano"
    [description]="Fiery intensity"
    [PRIMARY]="255;69;0"       # Orange red
    [SECONDARY]="255;140;0"    # Dark orange
    [ACCENT]="255;215;0"       # Gold
    [SUCCESS]="50;205;50"      # Lime green
    [WARNING]="255;255;0"      # Yellow
    [ERROR]="139;0;0"          # Dark red
    [BG]="25;5;5"              # Dark red-brown
    [TEXT]="255;248;220"       # Cornsilk
    [MUTED]="139;69;19"        # Saddle brown
    [BORDER]="178;34;34"       # Firebrick
    [GRADIENT1]="139;0;0"
    [GRADIENT2]="255;69;0"
    [GRADIENT3]="255;215;0"
)

declare -A THEME_MATRIX=(
    [name]="Matrix"
    [description]="Digital rain aesthetics"
    [PRIMARY]="0;255;65"       # Matrix green
    [SECONDARY]="0;200;50"     # Darker green
    [ACCENT]="255;255;255"     # White
    [SUCCESS]="0;255;0"        # Pure green
    [WARNING]="0;255;128"      # Light green
    [ERROR]="255;0;0"          # Red
    [BG]="0;10;0"              # Very dark green
    [TEXT]="0;255;65"          # Matrix green
    [MUTED]="0;80;30"          # Dark green
    [BORDER]="0;180;60"        # Medium green
    [GRADIENT1]="0;50;0"
    [GRADIENT2]="0;150;50"
    [GRADIENT3]="0;255;65"
)

declare -A THEME_ARCTIC=(
    [name]="Arctic"
    [description]="Frozen crystalline beauty"
    [PRIMARY]="135;206;250"    # Light sky blue
    [SECONDARY]="176;224;230"  # Powder blue
    [ACCENT]="255;250;250"     # Snow
    [SUCCESS]="144;238;144"    # Light green
    [WARNING]="255;218;185"    # Peach puff
    [ERROR]="255;99;71"        # Tomato
    [BG]="15;25;35"            # Dark blue-gray
    [TEXT]="240;248;255"       # Alice blue
    [MUTED]="119;136;153"      # Light slate gray
    [BORDER]="70;130;180"      # Steel blue
    [GRADIENT1]="70;130;180"
    [GRADIENT2]="135;206;250"
    [GRADIENT3]="255;250;250"
)

declare -A THEME_SYNTHWAVE=(
    [name]="Synthwave"
    [description]="80s retro future"
    [PRIMARY]="255;110;199"    # Pink
    [SECONDARY]="111;45;189"   # Purple
    [ACCENT]="254;228;64"      # Yellow
    [SUCCESS]="102;255;204"    # Turquoise
    [WARNING]="255;154;0"      # Orange
    [ERROR]="255;0;110"        # Hot pink
    [BG]="26;14;42"            # Dark purple
    [TEXT]="255;230;255"       # Light pink
    [MUTED]="147;112;219"      # Medium purple
    [BORDER]="186;85;211"      # Medium orchid
    [GRADIENT1]="111;45;189"
    [GRADIENT2]="255;110;199"
    [GRADIENT3]="254;228;64"
)

declare -A THEME_FOREST=(
    [name]="Forest"
    [description]="Natural woodland serenity"
    [PRIMARY]="34;139;34"      # Forest green
    [SECONDARY]="107;142;35"   # Olive drab
    [ACCENT]="218;165;32"      # Goldenrod
    [SUCCESS]="50;205;50"      # Lime green
    [WARNING]="210;180;140"    # Tan
    [ERROR]="165;42;42"        # Brown
    [BG]="15;20;10"            # Dark forest
    [TEXT]="245;245;220"       # Beige
    [MUTED]="85;107;47"        # Dark olive green
    [BORDER]="46;139;87"       # Sea green
    [GRADIENT1]="0;50;0"
    [GRADIENT2]="46;139;87"
    [GRADIENT3]="107;142;35"
)

declare -A THEME_OCEAN=(
    [name]="Ocean"
    [description]="Deep sea exploration"
    [PRIMARY]="0;105;148"      # Cerulean
    [SECONDARY]="64;224;208"   # Turquoise
    [ACCENT]="255;215;0"       # Gold
    [SUCCESS]="0;255;127"      # Spring green
    [WARNING]="255;165;0"      # Orange
    [ERROR]="220;20;60"        # Crimson
    [BG]="0;15;30"             # Deep sea blue
    [TEXT]="224;255;255"       # Light cyan
    [MUTED]="70;130;180"       # Steel blue
    [BORDER]="32;178;170"      # Light sea green
    [GRADIENT1]="0;0;139"
    [GRADIENT2]="0;139;139"
    [GRADIENT3]="64;224;208"
)

declare -A THEME_MONOCHROME=(
    [name]="Monochrome"
    [description]="Clean grayscale elegance"
    [PRIMARY]="200;200;200"    # Light gray
    [SECONDARY]="150;150;150"  # Medium gray
    [ACCENT]="255;255;255"     # White
    [SUCCESS]="180;180;180"    # Light gray
    [WARNING]="220;220;220"    # Gainsboro
    [ERROR]="100;100;100"      # Dark gray
    [BG]="20;20;20"            # Near black
    [TEXT]="240;240;240"       # Off white
    [MUTED]="80;80;80"         # Gray
    [BORDER]="120;120;120"     # Dark gray
    [GRADIENT1]="40;40;40"
    [GRADIENT2]="120;120;120"
    [GRADIENT3]="200;200;200"
)

# List of all themes
AVAILABLE_THEMES=(
    "cyberpunk"
    "midnight"
    "aurora"
    "volcano"
    "matrix"
    "arctic"
    "synthwave"
    "forest"
    "ocean"
    "monochrome"
)

#───────────────────────────────────────────────────────────────────────────────
# THEME APPLICATION
#───────────────────────────────────────────────────────────────────────────────

# Get theme array by name
get_theme_array() {
    local theme_name="$1"
    local upper_name=$(echo "$theme_name" | tr '[:lower:]' '[:upper:]')
    local array_name="THEME_${upper_name}"

    declare -n theme_ref="$array_name" 2>/dev/null || return 1
    echo "${!theme_ref[@]}"
}

# Apply a theme
apply_theme() {
    local theme_name="${1:-cyberpunk}"
    local upper_name=$(echo "$theme_name" | tr '[:lower:]' '[:upper:]')
    local array_name="THEME_${upper_name}"

    # Check if theme exists
    declare -n theme="$array_name" 2>/dev/null || {
        log_error "Theme '$theme_name' not found"
        return 1
    }

    # Export theme colors as ANSI escape codes
    export THEME_PRIMARY="\033[38;2;${theme[PRIMARY]}m"
    export THEME_SECONDARY="\033[38;2;${theme[SECONDARY]}m"
    export THEME_ACCENT="\033[38;2;${theme[ACCENT]}m"
    export THEME_SUCCESS="\033[38;2;${theme[SUCCESS]}m"
    export THEME_WARNING="\033[38;2;${theme[WARNING]}m"
    export THEME_ERROR="\033[38;2;${theme[ERROR]}m"
    export THEME_TEXT="\033[38;2;${theme[TEXT]}m"
    export THEME_MUTED="\033[38;2;${theme[MUTED]}m"
    export THEME_BORDER="\033[38;2;${theme[BORDER]}m"

    # Background colors
    export THEME_BG="\033[48;2;${theme[BG]}m"
    export THEME_BG_PRIMARY="\033[48;2;${theme[PRIMARY]}m"
    export THEME_BG_SECONDARY="\033[48;2;${theme[SECONDARY]}m"
    export THEME_BG_ACCENT="\033[48;2;${theme[ACCENT]}m"

    # Gradient colors
    export THEME_GRADIENT1="\033[38;2;${theme[GRADIENT1]}m"
    export THEME_GRADIENT2="\033[38;2;${theme[GRADIENT2]}m"
    export THEME_GRADIENT3="\033[38;2;${theme[GRADIENT3]}m"

    # Store current theme
    CURRENT_THEME="$theme_name"
    echo "$theme_name" > "$CURRENT_THEME_FILE"

    log_debug "Theme applied: ${theme[name]}"
    return 0
}

# Load saved theme
load_saved_theme() {
    if [[ -f "$CURRENT_THEME_FILE" ]]; then
        local saved_theme=$(cat "$CURRENT_THEME_FILE")
        apply_theme "$saved_theme"
    else
        apply_theme "cyberpunk"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# GRADIENT TEXT RENDERING
#───────────────────────────────────────────────────────────────────────────────

# Render text with horizontal gradient
gradient_text() {
    local text="$1"
    local r1="${2:-255}" g1="${3:-0}"   b1="${4:-128}"
    local r2="${5:-0}"   g2="${6:-255}" b2="${7:-255}"

    local len=${#text}
    local result=""

    for ((i=0; i<len; i++)); do
        local ratio=$((i * 100 / (len - 1)))
        local r=$((r1 + (r2 - r1) * ratio / 100))
        local g=$((g1 + (g2 - g1) * ratio / 100))
        local b=$((b1 + (b2 - b1) * ratio / 100))

        result+="\033[38;2;${r};${g};${b}m${text:$i:1}"
    done

    printf "%b${RST}" "$result"
}

# Rainbow text
rainbow_text() {
    local text="$1"
    local len=${#text}
    local result=""

    local colors=(
        "255;0;0"      # Red
        "255;127;0"    # Orange
        "255;255;0"    # Yellow
        "0;255;0"      # Green
        "0;0;255"      # Blue
        "75;0;130"     # Indigo
        "148;0;211"    # Violet
    )

    for ((i=0; i<len; i++)); do
        local color_idx=$((i % ${#colors[@]}))
        result+="\033[38;2;${colors[$color_idx]}m${text:$i:1}"
    done

    printf "%b${RST}" "$result"
}

# Themed gradient using current theme
theme_gradient_text() {
    local text="$1"
    local upper_name=$(echo "$CURRENT_THEME" | tr '[:lower:]' '[:upper:]')
    local array_name="THEME_${upper_name}"

    declare -n theme="$array_name" 2>/dev/null || return 1

    IFS=';' read -r r1 g1 b1 <<< "${theme[GRADIENT1]}"
    IFS=';' read -r r2 g2 b2 <<< "${theme[GRADIENT3]}"

    gradient_text "$text" "$r1" "$g1" "$b1" "$r2" "$g2" "$b2"
}

#───────────────────────────────────────────────────────────────────────────────
# THEME PREVIEW
#───────────────────────────────────────────────────────────────────────────────

# Preview a single theme
preview_theme() {
    local theme_name="${1:-$CURRENT_THEME}"
    local upper_name=$(echo "$theme_name" | tr '[:lower:]' '[:upper:]')
    local array_name="THEME_${upper_name}"

    declare -n theme="$array_name" 2>/dev/null || {
        printf "Theme not found: %s\n" "$theme_name"
        return 1
    }

    local p="\033[38;2;${theme[PRIMARY]}m"
    local s="\033[38;2;${theme[SECONDARY]}m"
    local a="\033[38;2;${theme[ACCENT]}m"
    local t="\033[38;2;${theme[TEXT]}m"
    local b="\033[38;2;${theme[BORDER]}m"
    local g1="\033[38;2;${theme[GRADIENT1]}m"
    local g2="\033[38;2;${theme[GRADIENT2]}m"
    local g3="\033[38;2;${theme[GRADIENT3]}m"
    local bg="\033[48;2;${theme[BG]}m"

    printf "${bg}${b}╭──────────────────────────────────────────────────────╮${RST}\n"
    printf "${bg}${b}│${RST}${bg} ${p}█${s}█${a}█${RST}${bg} ${p}${BOLD}%-15s${RST}${bg} ${t}%-30s${b}│${RST}\n" "${theme[name]}" "${theme[description]}"
    printf "${bg}${b}├──────────────────────────────────────────────────────┤${RST}\n"
    printf "${bg}${b}│${RST}${bg} ${p}Primary  ${s}Secondary  ${a}Accent${RST}${bg}                         ${b}│${RST}\n"
    printf "${bg}${b}│${RST}${bg} "
    printf "${p}████████${RST}${bg} ${s}████████${RST}${bg} ${a}████████${RST}${bg}                  ${b}│${RST}\n"
    printf "${bg}${b}│${RST}${bg}                                                      ${b}│${RST}\n"
    printf "${bg}${b}│${RST}${bg} Gradient: ${g1}████${g2}████${g3}████${RST}${bg}                            ${b}│${RST}\n"
    printf "${bg}${b}│${RST}${bg}                                                      ${b}│${RST}\n"
    printf "${bg}${b}│${RST}${bg} ${t}Sample text in theme colors${RST}${bg}                        ${b}│${RST}\n"
    printf "${bg}${b}│${RST}${bg} "
    printf "\033[38;2;${theme[SUCCESS]}m✓ Success${RST}${bg} "
    printf "\033[38;2;${theme[WARNING]}m⚠ Warning${RST}${bg} "
    printf "\033[38;2;${theme[ERROR]}m✗ Error${RST}${bg}          ${b}│${RST}\n"
    printf "${bg}${b}╰──────────────────────────────────────────────────────╯${RST}\n"
}

# Preview all themes
preview_all_themes() {
    clear_screen
    cursor_hide

    printf "${BOLD}"
    theme_gradient_text "═══════════════════════════════════════════════════════════"
    printf "\n"
    theme_gradient_text "                    BLACKROAD THEMES                        "
    printf "\n"
    theme_gradient_text "═══════════════════════════════════════════════════════════"
    printf "${RST}\n\n"

    for theme_name in "${AVAILABLE_THEMES[@]}"; do
        preview_theme "$theme_name"
        printf "\n"
    done

    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# THEME SELECTOR UI
#───────────────────────────────────────────────────────────────────────────────

theme_selector() {
    local selected=0
    local num_themes=${#AVAILABLE_THEMES[@]}

    cursor_hide
    stty -echo 2>/dev/null

    while true; do
        clear_screen

        printf "${BOLD}"
        theme_gradient_text "╔══════════════════════════════════════════════════════════╗"
        printf "\n"
        theme_gradient_text "║            🎨 BLACKROAD THEME SELECTOR                   ║"
        printf "\n"
        theme_gradient_text "╚══════════════════════════════════════════════════════════╝"
        printf "${RST}\n\n"

        printf "  ${TEXT_MUTED}Current theme: ${THEME_PRIMARY}%s${RST}\n\n" "$CURRENT_THEME"

        for i in "${!AVAILABLE_THEMES[@]}"; do
            local theme_name="${AVAILABLE_THEMES[$i]}"
            local upper_name=$(echo "$theme_name" | tr '[:lower:]' '[:upper:]')
            local array_name="THEME_${upper_name}"

            declare -n theme="$array_name" 2>/dev/null || continue

            local p="\033[38;2;${theme[PRIMARY]}m"
            local s="\033[38;2;${theme[SECONDARY]}m"
            local a="\033[38;2;${theme[ACCENT]}m"

            if [[ $i -eq $selected ]]; then
                printf "  ${THEME_ACCENT}▶ ${p}█${s}█${a}█${RST} ${BOLD}${p}%-12s${RST} ${TEXT_SECONDARY}${theme[description]}${RST}\n" "${theme[name]}"
            else
                printf "    ${p}█${s}█${a}█${RST} ${TEXT_MUTED}%-12s${RST} ${TEXT_MUTED}${theme[description]}${RST}\n" "${theme[name]}"
            fi
        done

        printf "\n\n"
        preview_theme "${AVAILABLE_THEMES[$selected]}"

        printf "\n  ${TEXT_MUTED}↑/↓ Navigate  •  Enter Apply  •  Q Quit${RST}\n"

        # Read input
        read -rsn1 key

        case "$key" in
            $'\e')
                read -rsn2 -t 0.01 key2
                case "$key2" in
                    '[A') ((selected = (selected - 1 + num_themes) % num_themes)) ;;  # Up
                    '[B') ((selected = (selected + 1) % num_themes)) ;;               # Down
                esac
                ;;
            '') # Enter
                apply_theme "${AVAILABLE_THEMES[$selected]}"
                printf "\n  ${THEME_SUCCESS}✓ Theme applied: ${AVAILABLE_THEMES[$selected]}${RST}\n"
                sleep 1
                ;;
            q|Q)
                break
                ;;
        esac
    done

    cursor_show
    stty echo 2>/dev/null
}

#───────────────────────────────────────────────────────────────────────────────
# THEMED UI COMPONENTS
#───────────────────────────────────────────────────────────────────────────────

# Draw themed box
theme_box() {
    local title="$1"
    local width="${2:-50}"

    printf "${THEME_BORDER}╭"
    printf "%0.s─" $(seq 1 $((width - 2)))
    printf "╮${RST}\n"

    if [[ -n "$title" ]]; then
        local title_len=${#title}
        local padding=$(( (width - 4 - title_len) / 2 ))
        printf "${THEME_BORDER}│${RST}"
        printf "%${padding}s" ""
        printf "${THEME_PRIMARY}${BOLD} %s ${RST}" "$title"
        printf "%$(( width - 4 - title_len - padding ))s"
        printf "${THEME_BORDER}│${RST}\n"

        printf "${THEME_BORDER}├"
        printf "%0.s─" $(seq 1 $((width - 2)))
        printf "┤${RST}\n"
    fi
}

theme_box_close() {
    local width="${1:-50}"

    printf "${THEME_BORDER}╰"
    printf "%0.s─" $(seq 1 $((width - 2)))
    printf "╯${RST}\n"
}

# Themed progress bar
theme_progress() {
    local current="$1"
    local total="$2"
    local width="${3:-30}"

    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "${THEME_PRIMARY}"
    printf "%0.s█" $(seq 1 "$filled" 2>/dev/null) || true
    printf "${THEME_MUTED}"
    printf "%0.s░" $(seq 1 "$empty" 2>/dev/null) || true
    printf "${RST} ${THEME_TEXT}%3d%%${RST}" "$percentage"
}

# Themed status indicator
theme_status() {
    local status="$1"
    local label="$2"

    case "$status" in
        online|up|ok|success)
            printf "${THEME_SUCCESS}◉ %s${RST}" "$label"
            ;;
        offline|down|error|fail)
            printf "${THEME_ERROR}○ %s${RST}" "$label"
            ;;
        warning|warn|degraded)
            printf "${THEME_WARNING}◐ %s${RST}" "$label"
            ;;
        *)
            printf "${THEME_SECONDARY}◎ %s${RST}" "$label"
            ;;
    esac
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

# Load theme on source
load_saved_theme

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-selector}" in
        selector|select) theme_selector ;;
        preview)         preview_all_themes ;;
        apply)           apply_theme "${2:-cyberpunk}" ;;
        list)
            printf "Available themes:\n"
            for t in "${AVAILABLE_THEMES[@]}"; do
                [[ "$t" == "$CURRENT_THEME" ]] && printf " * %s (current)\n" "$t" || printf "   %s\n" "$t"
            done
            ;;
        *)
            printf "Usage: %s [selector|preview|apply <theme>|list]\n" "$0"
            printf "       %s apply cyberpunk\n" "$0"
            ;;
    esac
fi
