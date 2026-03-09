#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ███╗   ███╗ █████╗ ████████╗██████╗ ██╗██╗  ██╗
#  ████╗ ████║██╔══██╗╚══██╔══╝██╔══██╗██║╚██╗██╔╝
#  ██╔████╔██║███████║   ██║   ██████╔╝██║ ╚███╔╝
#  ██║╚██╔╝██║██╔══██║   ██║   ██╔══██╗██║ ██╔██╗
#  ██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║██║██╔╝ ██╗
#  ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD MATRIX RAIN EFFECT v3.0
#  Digital Rain Animation with Multiple Modes
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

# Character sets
CHARS_MATRIX="ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789"
CHARS_BINARY="01"
CHARS_HEX="0123456789ABCDEF"
CHARS_CODE="{}[]()<>/*+-=:;.,!?@#$%^&|~"
CHARS_ALPHA="ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# Current config
CHAR_SET="$CHARS_MATRIX"
COLOR_MODE="green"
DENSITY=0.6
SPEED=0.03
TRAIL_LENGTH=15

# Color schemes
declare -A COLOR_SCHEMES=(
    [green]="0;255;65"
    [cyan]="0;255;255"
    [blue]="0;128;255"
    [red]="255;0;65"
    [purple]="180;0;255"
    [orange]="255;128;0"
    [rainbow]="rainbow"
    [blackroad]="247;147;26"
)

#───────────────────────────────────────────────────────────────────────────────
# RAIN DROP SYSTEM
#───────────────────────────────────────────────────────────────────────────────

declare -a DROPS_X=()
declare -a DROPS_Y=()
declare -a DROPS_SPEED=()
declare -a DROPS_LENGTH=()
declare -a DROPS_CHARS=()

# Initialize drops
init_drops() {
    local width=$1
    local count=$2

    DROPS_X=()
    DROPS_Y=()
    DROPS_SPEED=()
    DROPS_LENGTH=()
    DROPS_CHARS=()

    for ((i=0; i<count; i++)); do
        DROPS_X+=($((RANDOM % width)))
        DROPS_Y+=($((RANDOM % 30 - 30)))  # Start above screen
        DROPS_SPEED+=($((1 + RANDOM % 3)))
        DROPS_LENGTH+=($((5 + RANDOM % TRAIL_LENGTH)))

        # Generate random character trail
        local trail=""
        for ((j=0; j<20; j++)); do
            trail+="${CHAR_SET:$((RANDOM % ${#CHAR_SET})):1}"
        done
        DROPS_CHARS+=("$trail")
    done
}

# Update drop positions
update_drops() {
    local height=$1
    local width=$2

    for ((i=0; i<${#DROPS_Y[@]}; i++)); do
        DROPS_Y[$i]=$((DROPS_Y[i] + DROPS_SPEED[i]))

        # Reset if off screen
        if [[ ${DROPS_Y[$i]} -gt $((height + DROPS_LENGTH[i])) ]]; then
            DROPS_X[$i]=$((RANDOM % width))
            DROPS_Y[$i]=$((-(RANDOM % 20)))
            DROPS_SPEED[$i]=$((1 + RANDOM % 3))
            DROPS_LENGTH[$i]=$((5 + RANDOM % TRAIL_LENGTH))

            # Regenerate characters
            local trail=""
            for ((j=0; j<20; j++)); do
                trail+="${CHAR_SET:$((RANDOM % ${#CHAR_SET})):1}"
            done
            DROPS_CHARS[$i]="$trail"
        fi
    done
}

#───────────────────────────────────────────────────────────────────────────────
# RENDERING
#───────────────────────────────────────────────────────────────────────────────

# Get color for position in trail
get_trail_color() {
    local pos=$1
    local length=$2
    local mode=$3

    local brightness=$((255 - (pos * 200 / length)))
    [[ $brightness -lt 30 ]] && brightness=30

    case "$mode" in
        rainbow)
            local hue=$((pos * 360 / length))
            # Simple rainbow approximation
            case $((hue / 60)) in
                0) echo "255;$((hue * 255 / 60));0" ;;
                1) echo "$((255 - (hue - 60) * 255 / 60));255;0" ;;
                2) echo "0;255;$((((hue - 120) * 255 / 60)))" ;;
                3) echo "0;$((255 - (hue - 180) * 255 / 60));255" ;;
                4) echo "$(((hue - 240) * 255 / 60));0;255" ;;
                5) echo "255;0;$((255 - (hue - 300) * 255 / 60))" ;;
            esac
            ;;
        *)
            local base="${COLOR_SCHEMES[$mode]:-0;255;65}"
            IFS=';' read -r r g b <<< "$base"
            echo "$((r * brightness / 255));$((g * brightness / 255));$((b * brightness / 255))"
            ;;
    esac
}

# Render frame
render_frame() {
    local width=$1
    local height=$2

    # Create screen buffer
    declare -A screen

    # Draw drops
    for ((i=0; i<${#DROPS_X[@]}; i++)); do
        local x=${DROPS_X[$i]}
        local y=${DROPS_Y[$i]}
        local length=${DROPS_LENGTH[$i]}
        local chars="${DROPS_CHARS[$i]}"

        for ((j=0; j<length && j<${#chars}; j++)); do
            local draw_y=$((y - j))

            if [[ $draw_y -ge 0 && $draw_y -lt $height && $x -ge 0 && $x -lt $width ]]; then
                local char="${chars:$j:1}"
                local color=$(get_trail_color "$j" "$length" "$COLOR_MODE")

                # Head of trail is brightest
                if [[ $j -eq 0 ]]; then
                    screen["$draw_y,$x"]="\033[38;2;255;255;255m$char"
                else
                    screen["$draw_y,$x"]="\033[38;2;${color}m$char"
                fi
            fi
        done
    done

    # Render to terminal
    printf "\033[H"  # Home cursor

    for ((row=0; row<height; row++)); do
        for ((col=0; col<width; col++)); do
            local key="$row,$col"
            if [[ -n "${screen[$key]}" ]]; then
                printf "%s" "${screen[$key]}"
            else
                printf " "
            fi
        done
        printf "\033[0m\n"
    done
}

# Optimized render using direct cursor positioning
render_frame_fast() {
    local width=$1
    local height=$2

    for ((i=0; i<${#DROPS_X[@]}; i++)); do
        local x=${DROPS_X[$i]}
        local y=${DROPS_Y[$i]}
        local length=${DROPS_LENGTH[$i]}
        local chars="${DROPS_CHARS[$i]}"

        for ((j=0; j<length && j<${#chars}; j++)); do
            local draw_y=$((y - j))

            if [[ $draw_y -ge 1 && $draw_y -le $height && $x -ge 0 && $x -lt $width ]]; then
                local char="${chars:$j:1}"
                local color=$(get_trail_color "$j" "$length" "$COLOR_MODE")

                printf "\033[%d;%dH" "$draw_y" "$((x + 1))"

                if [[ $j -eq 0 ]]; then
                    printf "\033[38;2;255;255;255m%s" "$char"
                else
                    printf "\033[38;2;${color}m%s" "$char"
                fi
            fi
        done

        # Clear trail behind
        local clear_y=$((y - length))
        if [[ $clear_y -ge 1 && $clear_y -le $height && $x -ge 0 && $x -lt $width ]]; then
            printf "\033[%d;%dH " "$clear_y" "$((x + 1))"
        fi
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN EFFECTS
#───────────────────────────────────────────────────────────────────────────────

# Classic matrix rain
matrix_classic() {
    local width=$(tput cols)
    local height=$(tput lines)
    local drop_count=$((width * DENSITY / 2))

    printf "\033[?25l"  # Hide cursor
    printf "\033[2J"    # Clear screen
    printf "\033[40m"   # Black background

    init_drops "$width" "$drop_count"

    trap "printf '\033[?25h\033[0m'; clear; exit" INT TERM

    while true; do
        render_frame_fast "$width" "$height"
        update_drops "$height" "$width"

        if read -rsn1 -t "$SPEED" key 2>/dev/null; then
            case "$key" in
                q|Q) break ;;
                +) SPEED=$(echo "$SPEED - 0.01" | bc -l 2>/dev/null || echo "$SPEED") ;;
                -) SPEED=$(echo "$SPEED + 0.01" | bc -l 2>/dev/null || echo "$SPEED") ;;
                c|C)
                    # Cycle colors
                    local colors=(green cyan blue red purple orange rainbow blackroad)
                    local current_idx=0
                    for ((idx=0; idx<${#colors[@]}; idx++)); do
                        [[ "${colors[$idx]}" == "$COLOR_MODE" ]] && current_idx=$idx && break
                    done
                    COLOR_MODE="${colors[$(( (current_idx + 1) % ${#colors[@]} ))]}"
                    ;;
                m|M)
                    # Cycle character sets
                    if [[ "$CHAR_SET" == "$CHARS_MATRIX" ]]; then
                        CHAR_SET="$CHARS_BINARY"
                    elif [[ "$CHAR_SET" == "$CHARS_BINARY" ]]; then
                        CHAR_SET="$CHARS_HEX"
                    elif [[ "$CHAR_SET" == "$CHARS_HEX" ]]; then
                        CHAR_SET="$CHARS_CODE"
                    else
                        CHAR_SET="$CHARS_MATRIX"
                    fi
                    ;;
            esac
        fi
    done

    printf "\033[?25h"  # Show cursor
    printf "\033[0m"    # Reset colors
    clear
}

# Matrix with text reveal
matrix_text_reveal() {
    local text="${1:-BLACKROAD}"
    local width=$(tput cols)
    local height=$(tput lines)

    printf "\033[?25l"
    printf "\033[2J"
    printf "\033[40m"

    local text_x=$(( (width - ${#text}) / 2 ))
    local text_y=$((height / 2))

    local drop_count=$((width * DENSITY / 2))
    init_drops "$width" "$drop_count"

    local frame=0
    local reveal_start=100

    trap "printf '\033[?25h\033[0m'; clear; exit" INT TERM

    while true; do
        render_frame_fast "$width" "$height"
        update_drops "$height" "$width"

        # Reveal text gradually
        if [[ $frame -gt $reveal_start ]]; then
            local chars_to_show=$(( (frame - reveal_start) / 5 ))
            [[ $chars_to_show -gt ${#text} ]] && chars_to_show=${#text}

            printf "\033[%d;%dH" "$text_y" "$text_x"
            printf "\033[38;2;255;255;255m\033[1m"

            for ((i=0; i<chars_to_show; i++)); do
                printf "%s" "${text:$i:1}"
            done

            # Glitch effect on remaining
            for ((i=chars_to_show; i<${#text}; i++)); do
                if [[ $((RANDOM % 3)) -eq 0 ]]; then
                    printf "\033[38;2;0;255;65m%s" "${CHAR_SET:$((RANDOM % ${#CHAR_SET})):1}"
                else
                    printf " "
                fi
            done
        fi

        ((frame++))

        if read -rsn1 -t "$SPEED" key 2>/dev/null; then
            [[ "$key" == "q" || "$key" == "Q" ]] && break
        fi
    done

    printf "\033[?25h"
    printf "\033[0m"
    clear
}

# Matrix screensaver with stats
matrix_screensaver() {
    local width=$(tput cols)
    local height=$(tput lines)
    local drop_count=$((width * DENSITY / 2))

    printf "\033[?25l"
    printf "\033[2J"

    init_drops "$width" "$drop_count"

    local start_time=$(date +%s)
    local frame=0

    trap "printf '\033[?25h\033[0m'; clear; exit" INT TERM

    while true; do
        render_frame_fast "$width" "$height"
        update_drops "$height" "$width"

        # Show stats in corner
        local runtime=$(($(date +%s) - start_time))
        printf "\033[1;1H\033[38;2;50;50;50m"
        printf "Frame: %d | Time: %ds | FPS: ~%d" "$frame" "$runtime" "$((frame / (runtime + 1)))"

        ((frame++))

        if read -rsn1 -t "$SPEED" key 2>/dev/null; then
            [[ "$key" == "q" || "$key" == "Q" ]] && break
        fi
    done

    printf "\033[?25h"
    printf "\033[0m"
    clear
}

# Interactive matrix with mouse-like trails
matrix_interactive() {
    local width=$(tput cols)
    local height=$(tput lines)

    printf "\033[?25l"
    printf "\033[2J"
    printf "\033[40m"

    local drop_count=20
    init_drops "$width" "$drop_count"

    trap "printf '\033[?25h\033[0m'; clear; exit" INT TERM

    while true; do
        render_frame_fast "$width" "$height"
        update_drops "$height" "$width"

        if read -rsn1 -t 0.02 key 2>/dev/null; then
            case "$key" in
                q|Q) break ;;
                # Add drops on keypress
                *)
                    local new_x=$((RANDOM % width))
                    DROPS_X+=("$new_x")
                    DROPS_Y+=("0")
                    DROPS_SPEED+=($((2 + RANDOM % 3)))
                    DROPS_LENGTH+=($((10 + RANDOM % 10)))

                    local trail=""
                    for ((j=0; j<20; j++)); do
                        trail+="${CHAR_SET:$((RANDOM % ${#CHAR_SET})):1}"
                    done
                    DROPS_CHARS+=("$trail")
                    ;;
            esac
        fi
    done

    printf "\033[?25h"
    printf "\033[0m"
    clear
}

#───────────────────────────────────────────────────────────────────────────────
# HELP
#───────────────────────────────────────────────────────────────────────────────

show_help() {
    cat << 'HELP'
BLACKROAD MATRIX RAIN

Usage: matrix-rain.sh [mode] [options]

Modes:
  classic       Classic matrix rain effect (default)
  reveal        Text reveal effect with matrix background
  screensaver   Screensaver mode with stats
  interactive   Interactive mode - press keys to add drops

Controls:
  q         Quit
  c         Cycle colors (green, cyan, blue, red, purple, orange, rainbow)
  m         Cycle character sets (matrix, binary, hex, code)
  +/-       Speed up/slow down

Options:
  --color <name>    Set color (green, cyan, blue, red, purple, orange, rainbow, blackroad)
  --speed <float>   Set speed (default: 0.03)
  --density <float> Set drop density (default: 0.6)
  --chars <set>     Set characters (matrix, binary, hex, code, alpha)

Examples:
  matrix-rain.sh classic --color cyan
  matrix-rain.sh reveal "WELCOME"
  matrix-rain.sh screensaver --color rainbow

HELP
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Parse arguments
    mode="classic"
    reveal_text="BLACKROAD"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            classic|reveal|screensaver|interactive)
                mode="$1"
                shift
                [[ "$mode" == "reveal" && -n "$1" && "${1:0:1}" != "-" ]] && {
                    reveal_text="$1"
                    shift
                }
                ;;
            --color)
                COLOR_MODE="$2"
                shift 2
                ;;
            --speed)
                SPEED="$2"
                shift 2
                ;;
            --density)
                DENSITY="$2"
                shift 2
                ;;
            --chars)
                case "$2" in
                    matrix) CHAR_SET="$CHARS_MATRIX" ;;
                    binary) CHAR_SET="$CHARS_BINARY" ;;
                    hex)    CHAR_SET="$CHARS_HEX" ;;
                    code)   CHAR_SET="$CHARS_CODE" ;;
                    alpha)  CHAR_SET="$CHARS_ALPHA" ;;
                esac
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done

    case "$mode" in
        classic)      matrix_classic ;;
        reveal)       matrix_text_reveal "$reveal_text" ;;
        screensaver)  matrix_screensaver ;;
        interactive)  matrix_interactive ;;
    esac
fi
