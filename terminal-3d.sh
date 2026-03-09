#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗ █████╗ ██╗          ██████╗ ██████╗
#  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗██║         ╚════██╗██╔══██╗
#     ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║███████║██║          █████╔╝██║  ██║
#     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██╔══██║██║          ╚═══██╗██║  ██║
#     ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██║  ██║███████╗    ██████╔╝██████╔╝
#     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝    ╚═════╝ ╚═════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD TERMINAL 3D VISUALIZATION ENGINE v3.0
#  ASCII 3D Rendering, Rotations, Animations, Data Cubes
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# 3D MATH FUNCTIONS
#───────────────────────────────────────────────────────────────────────────────

# Convert degrees to radians
deg_to_rad() {
    echo "scale=6; $1 * 3.14159265359 / 180" | bc -l 2>/dev/null
}

# Sine approximation
sin_approx() {
    local x=$(deg_to_rad "$1")
    echo "scale=4; $x - ($x^3)/6 + ($x^5)/120" | bc -l 2>/dev/null || echo "0"
}

# Cosine approximation
cos_approx() {
    local x=$(deg_to_rad "$1")
    echo "scale=4; 1 - ($x^2)/2 + ($x^4)/24" | bc -l 2>/dev/null || echo "1"
}

# Rotate point around X axis
rotate_x() {
    local y="$1" z="$2" angle="$3"
    local cos=$(cos_approx "$angle")
    local sin=$(sin_approx "$angle")

    local new_y=$(echo "scale=4; $y * $cos - $z * $sin" | bc -l 2>/dev/null)
    local new_z=$(echo "scale=4; $y * $sin + $z * $cos" | bc -l 2>/dev/null)

    echo "$new_y $new_z"
}

# Rotate point around Y axis
rotate_y() {
    local x="$1" z="$2" angle="$3"
    local cos=$(cos_approx "$angle")
    local sin=$(sin_approx "$angle")

    local new_x=$(echo "scale=4; $x * $cos + $z * $sin" | bc -l 2>/dev/null)
    local new_z=$(echo "scale=4; -$x * $sin + $z * $cos" | bc -l 2>/dev/null)

    echo "$new_x $new_z"
}

# Rotate point around Z axis
rotate_z() {
    local x="$1" y="$2" angle="$3"
    local cos=$(cos_approx "$angle")
    local sin=$(sin_approx "$angle")

    local new_x=$(echo "scale=4; $x * $cos - $y * $sin" | bc -l 2>/dev/null)
    local new_y=$(echo "scale=4; $x * $sin + $y * $cos" | bc -l 2>/dev/null)

    echo "$new_x $new_y"
}

# Project 3D to 2D
project() {
    local x="$1" y="$2" z="$3"
    local fov="${4:-200}"
    local distance="${5:-5}"

    local factor=$(echo "scale=4; $fov / ($z + $distance)" | bc -l 2>/dev/null || echo "40")

    local screen_x=$(echo "scale=0; $x * $factor + 40" | bc 2>/dev/null || echo "40")
    local screen_y=$(echo "scale=0; $y * $factor + 15" | bc 2>/dev/null || echo "15")

    echo "$screen_x $screen_y"
}

#───────────────────────────────────────────────────────────────────────────────
# 3D SHAPES
#───────────────────────────────────────────────────────────────────────────────

# Define cube vertices
declare -a CUBE_VERTICES=(
    "-1 -1 -1"  # 0
    " 1 -1 -1"  # 1
    " 1  1 -1"  # 2
    "-1  1 -1"  # 3
    "-1 -1  1"  # 4
    " 1 -1  1"  # 5
    " 1  1  1"  # 6
    "-1  1  1"  # 7
)

# Define cube edges (vertex pairs)
declare -a CUBE_EDGES=(
    "0 1" "1 2" "2 3" "3 0"  # Back face
    "4 5" "5 6" "6 7" "7 4"  # Front face
    "0 4" "1 5" "2 6" "3 7"  # Connecting edges
)

# Define pyramid vertices
declare -a PYRAMID_VERTICES=(
    " 0  1  0"   # Top
    "-1 -1 -1"   # Base 0
    " 1 -1 -1"   # Base 1
    " 1 -1  1"   # Base 2
    "-1 -1  1"   # Base 3
)

declare -a PYRAMID_EDGES=(
    "0 1" "0 2" "0 3" "0 4"  # Apex to base
    "1 2" "2 3" "3 4" "4 1"  # Base
)

# Render buffer
declare -A SCREEN_BUFFER
declare -A DEPTH_BUFFER

#───────────────────────────────────────────────────────────────────────────────
# RENDERING ENGINE
#───────────────────────────────────────────────────────────────────────────────

# Clear buffers
clear_buffers() {
    SCREEN_BUFFER=()
    DEPTH_BUFFER=()
}

# Plot point with depth check
plot_point() {
    local x="$1" y="$2" z="$3" char="$4" color="${5:-$BR_CYAN}"

    local key="$x,$y"
    local current_z="${DEPTH_BUFFER[$key]:-999}"

    if (( $(echo "$z < $current_z" | bc -l 2>/dev/null || echo 1) )); then
        SCREEN_BUFFER[$key]="${color}${char}${RST}"
        DEPTH_BUFFER[$key]="$z"
    fi
}

# Draw line between two 3D points (Bresenham)
draw_3d_line() {
    local x0="$1" y0="$2" z0="$3"
    local x1="$4" y1="$5" z1="$6"
    local char="${7:-.}"
    local color="${8:-$BR_CYAN}"

    # Project both points
    read sx0 sy0 <<< "$(project "$x0" "$y0" "$z0")"
    read sx1 sy1 <<< "$(project "$x1" "$y1" "$z1")"

    # Bresenham's line algorithm
    local dx=$((${sx1%.*} - ${sx0%.*}))
    local dy=$((${sy1%.*} - ${sy0%.*}))
    local dx_abs=${dx#-}
    local dy_abs=${dy#-}

    local sx=1 sy=1
    [[ $dx -lt 0 ]] && sx=-1
    [[ $dy -lt 0 ]] && sy=-1

    local err=$((dx_abs - dy_abs))
    local x="${sx0%.*}" y="${sy0%.*}"
    local x_end="${sx1%.*}" y_end="${sy1%.*}"

    local steps=$((dx_abs > dy_abs ? dx_abs : dy_abs))
    [[ $steps -eq 0 ]] && steps=1

    for ((i=0; i<=steps && i<100; i++)); do
        # Interpolate z
        local t=$(echo "scale=4; $i / $steps" | bc -l 2>/dev/null || echo "0.5")
        local z=$(echo "scale=4; $z0 + ($z1 - $z0) * $t" | bc -l 2>/dev/null || echo "0")

        plot_point "$x" "$y" "$z" "$char" "$color"

        [[ $x -eq $x_end && $y -eq $y_end ]] && break

        local e2=$((err * 2))
        if [[ $e2 -gt -$dy_abs ]]; then
            err=$((err - dy_abs))
            x=$((x + sx))
        fi
        if [[ $e2 -lt $dx_abs ]]; then
            err=$((err + dx_abs))
            y=$((y + sy))
        fi
    done
}

# Render buffer to screen
render_buffer() {
    local width="${1:-80}"
    local height="${2:-30}"

    for ((y=0; y<height; y++)); do
        for ((x=0; x<width; x++)); do
            local key="$x,$y"
            if [[ -n "${SCREEN_BUFFER[$key]}" ]]; then
                printf "%s" "${SCREEN_BUFFER[$key]}"
            else
                printf " "
            fi
        done
        printf "\n"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# 3D OBJECT RENDERING
#───────────────────────────────────────────────────────────────────────────────

# Render rotating cube
render_cube() {
    local angle_x="$1" angle_y="$2" angle_z="$3"
    local scale="${4:-1}"
    local color="${5:-$BR_CYAN}"

    clear_buffers

    # Transform and project all vertices
    local -a projected=()

    for vertex in "${CUBE_VERTICES[@]}"; do
        read x y z <<< "$vertex"

        # Scale
        x=$(echo "scale=4; $x * $scale" | bc -l)
        y=$(echo "scale=4; $y * $scale" | bc -l)
        z=$(echo "scale=4; $z * $scale" | bc -l)

        # Rotate
        read y z <<< "$(rotate_x "$y" "$z" "$angle_x")"
        read x z <<< "$(rotate_y "$x" "$z" "$angle_y")"
        read x y <<< "$(rotate_z "$x" "$y" "$angle_z")"

        projected+=("$x $y $z")
    done

    # Draw edges
    for edge in "${CUBE_EDGES[@]}"; do
        read v0 v1 <<< "$edge"
        read x0 y0 z0 <<< "${projected[$v0]}"
        read x1 y1 z1 <<< "${projected[$v1]}"

        draw_3d_line "$x0" "$y0" "$z0" "$x1" "$y1" "$z1" "█" "$color"
    done

    render_buffer 80 30
}

# Render rotating pyramid
render_pyramid() {
    local angle_x="$1" angle_y="$2" angle_z="$3"
    local scale="${4:-1.5}"
    local color="${5:-$BR_ORANGE}"

    clear_buffers

    local -a projected=()

    for vertex in "${PYRAMID_VERTICES[@]}"; do
        read x y z <<< "$vertex"

        x=$(echo "scale=4; $x * $scale" | bc -l)
        y=$(echo "scale=4; $y * $scale" | bc -l)
        z=$(echo "scale=4; $z * $scale" | bc -l)

        read y z <<< "$(rotate_x "$y" "$z" "$angle_x")"
        read x z <<< "$(rotate_y "$x" "$z" "$angle_y")"
        read x y <<< "$(rotate_z "$x" "$y" "$angle_z")"

        projected+=("$x $y $z")
    done

    for edge in "${PYRAMID_EDGES[@]}"; do
        read v0 v1 <<< "$edge"
        read x0 y0 z0 <<< "${projected[$v0]}"
        read x1 y1 z1 <<< "${projected[$v1]}"

        draw_3d_line "$x0" "$y0" "$z0" "$x1" "$y1" "$z1" "▲" "$color"
    done

    render_buffer 80 30
}

#───────────────────────────────────────────────────────────────────────────────
# DATA VISUALIZATION 3D
#───────────────────────────────────────────────────────────────────────────────

# 3D bar chart
render_3d_bars() {
    local -a values=("$@")
    local max_val=1
    local angle_y="${values[-1]}"
    unset 'values[-1]'

    for v in "${values[@]}"; do
        ((v > max_val)) && max_val=$v
    done

    clear_buffers

    local num_bars=${#values[@]}
    local bar_width=1
    local bar_spacing=2
    local start_x=$((-num_bars * bar_spacing / 2))

    for ((i=0; i<num_bars; i++)); do
        local height=$(echo "scale=2; ${values[$i]} * 3 / $max_val" | bc -l 2>/dev/null || echo "1")
        local x=$((start_x + i * bar_spacing))

        # Color based on value
        local pct=$((${values[$i]} * 100 / max_val))
        local color="$BR_GREEN"
        [[ $pct -gt 70 ]] && color="$BR_YELLOW"
        [[ $pct -gt 85 ]] && color="$BR_RED"

        # Draw bar (vertical line with depth)
        for h in $(seq 0 0.2 "$height"); do
            local y=$(echo "scale=2; -1.5 + $h" | bc -l)
            local z=0

            # Rotate
            read rx rz <<< "$(rotate_y "$x" "$z" "$angle_y")"
            read sx sy <<< "$(project "$rx" "$y" "$rz")"

            plot_point "${sx%.*}" "${sy%.*}" "$rz" "█" "$color"
        done
    done

    render_buffer 80 30
}

# 3D scatter plot
render_3d_scatter() {
    local angle_x="$1" angle_y="$2"
    shift 2

    clear_buffers

    local chars=("◉" "◎" "●" "○" "◆" "◇")
    local colors=("$BR_CYAN" "$BR_PINK" "$BR_ORANGE" "$BR_PURPLE" "$BR_GREEN" "$BR_YELLOW")

    local i=0
    while [[ $# -ge 3 ]]; do
        local x="$1" y="$2" z="$3"
        shift 3

        read ry rz <<< "$(rotate_x "$y" "$z" "$angle_x")"
        read rx rz <<< "$(rotate_y "$x" "$rz" "$angle_y")"
        read sx sy <<< "$(project "$rx" "$ry" "$rz")"

        local char="${chars[$((i % ${#chars[@]}))]}"
        local color="${colors[$((i % ${#colors[@]}))]}"

        plot_point "${sx%.*}" "${sy%.*}" "$rz" "$char" "$color"
        ((i++))
    done

    # Draw axes
    draw_3d_line -2 0 0  2 0 0  "─" "$TEXT_MUTED"  # X axis
    draw_3d_line 0 -2 0  0 2 0  "│" "$TEXT_MUTED"  # Y axis
    draw_3d_line 0 0 -2  0 0 2  "·" "$TEXT_MUTED"  # Z axis

    render_buffer 80 30
}

#───────────────────────────────────────────────────────────────────────────────
# ANIMATED 3D DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

render_3d_dashboard() {
    local angle=0

    cursor_hide
    clear_screen

    while true; do
        cursor_to 1 1

        printf "${BR_PURPLE}${BOLD}"
        printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
        printf "║                      🎮 BLACKROAD 3D VISUALIZATION                           ║\n"
        printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
        printf "${RST}\n"

        # Get real metrics for visualization
        local cpu=$(get_cpu_usage 2>/dev/null || echo "30")
        local mem=$(get_memory_usage 2>/dev/null || echo "45")
        local disk=$(get_disk_usage "/" 2>/dev/null || echo "60")

        # Render rotating data cube
        render_cube "$((angle / 2))" "$angle" "$((angle / 3))" 1.5 "$BR_CYAN"

        printf "\n"
        printf "${TEXT_MUTED}──────────────────────────────────────────────────────────────────────────────${RST}\n"
        printf "  ${BR_CYAN}CPU: %3d%%${RST}  │  ${BR_PINK}Memory: %3d%%${RST}  │  ${BR_ORANGE}Disk: %3d%%${RST}  │  ${TEXT_MUTED}Angle: %d°${RST}\n" \
            "$cpu" "$mem" "$disk" "$angle"
        printf "${TEXT_MUTED}──────────────────────────────────────────────────────────────────────────────${RST}\n"
        printf "  ${TEXT_SECONDARY}[←/→] Rotate  [↑/↓] Tilt  [b]ars  [s]catter  [c]ube  [p]yramid  [q]uit${RST}\n"

        # Handle input
        if read -rsn1 -t 0.1 key 2>/dev/null; then
            case "$key" in
                $'\e')
                    read -rsn2 -t 0.01 seq
                    case "$seq" in
                        '[C') angle=$((angle + 10)) ;;  # Right
                        '[D') angle=$((angle - 10)) ;;  # Left
                    esac
                    ;;
                q|Q) break ;;
            esac
        fi

        angle=$((angle + 2))
        [[ $angle -ge 360 ]] && angle=0

        sleep 0.05
    done

    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# MATRIX RAIN 3D
#───────────────────────────────────────────────────────────────────────────────

render_matrix_3d() {
    local width=80
    local height=30
    local depth=10

    declare -a drops=()

    # Initialize drops
    for ((i=0; i<50; i++)); do
        drops+=("$((RANDOM % width)) $((RANDOM % depth)) $((RANDOM % height))")
    done

    cursor_hide
    clear_screen

    local frame=0

    while true; do
        cursor_to 1 1
        clear_buffers

        # Update and render drops
        for i in "${!drops[@]}"; do
            read x z y <<< "${drops[$i]}"

            # Move drop down
            y=$((y + 1))
            if [[ $y -gt $height ]]; then
                y=0
                x=$((RANDOM % width))
                z=$((RANDOM % depth))
            fi

            drops[$i]="$x $z $y"

            # Project and plot
            local intensity=$((255 - z * 20))
            [[ $intensity -lt 50 ]] && intensity=50

            local color="\033[38;2;0;${intensity};$((intensity/2))m"

            # Random character
            local chars="アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789"
            local char="${chars:$((RANDOM % ${#chars})):1}"

            local screen_x=$((x + (z - 5)))
            [[ $screen_x -lt 0 ]] && screen_x=0
            [[ $screen_x -ge $width ]] && screen_x=$((width - 1))

            plot_point "$screen_x" "$y" "$z" "$char" "$color"
        done

        render_buffer "$width" "$height"

        printf "\n${BR_GREEN}BLACKROAD MATRIX 3D${RST} │ ${TEXT_MUTED}Frame: %d │ Press 'q' to exit${RST}" "$frame"

        if read -rsn1 -t 0.05 key 2>/dev/null; then
            [[ "$key" == "q" || "$key" == "Q" ]] && break
        fi

        ((frame++))
    done

    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-dashboard}" in
        dashboard)  render_3d_dashboard ;;
        cube)       render_cube "${2:-0}" "${3:-45}" "${4:-0}" "${5:-1.5}" ;;
        pyramid)    render_pyramid "${2:-0}" "${3:-45}" "${4:-0}" ;;
        bars)       render_3d_bars 30 50 80 40 60 90 45 "${2:-0}" ;;
        matrix)     render_matrix_3d ;;
        *)
            printf "Usage: %s [dashboard|cube|pyramid|bars|matrix]\n" "$0"
            ;;
    esac
fi
