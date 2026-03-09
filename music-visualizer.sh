#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ███╗   ███╗██╗   ██╗███████╗██╗ ██████╗    ██╗   ██╗██╗███████╗
#  ████╗ ████║██║   ██║██╔════╝██║██╔════╝    ██║   ██║██║╚══███╔╝
#  ██╔████╔██║██║   ██║███████╗██║██║         ██║   ██║██║  ███╔╝
#  ██║╚██╔╝██║██║   ██║╚════██║██║██║         ╚██╗ ██╔╝██║ ███╔╝
#  ██║ ╚═╝ ██║╚██████╔╝███████║██║╚██████╗     ╚████╔╝ ██║███████╗
#  ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝ ╚═════╝      ╚═══╝  ╚═╝╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD MUSIC VISUALIZER v3.0
#  ASCII Audio Visualization, Spectrum Analyzer & Beat Detection
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

VISUALIZER_WIDTH=80
VISUALIZER_HEIGHT=20
NUM_BARS=40
SMOOTHING=0.3

# Visualization modes
MODE_BARS="bars"
MODE_WAVE="wave"
MODE_CIRCLE="circle"
MODE_SPECTRUM="spectrum"
MODE_PARTICLES="particles"

CURRENT_MODE="$MODE_BARS"

# Color schemes
declare -A COLOR_SCHEMES
COLOR_SCHEMES[rainbow]="196 202 208 214 220 226 190 154 118 82 46 47 48 49 50 51"
COLOR_SCHEMES[fire]="196 202 208 214 220 226 227 228 229 230 231"
COLOR_SCHEMES[ocean]="17 18 19 20 21 27 33 39 45 51 87 123 159"
COLOR_SCHEMES[matrix]="22 28 34 40 46 82 118 154 190 226"
COLOR_SCHEMES[purple]="53 54 55 56 57 93 129 165 201 207"
COLOR_SCHEMES[mono]="232 234 236 238 240 242 244 246 248 250 252 254 255"

CURRENT_SCHEME="rainbow"

#───────────────────────────────────────────────────────────────────────────────
# AUDIO DATA SIMULATION (No audio input required)
#───────────────────────────────────────────────────────────────────────────────

# Previous values for smoothing
declare -a PREV_VALUES

init_values() {
    for ((i=0; i<NUM_BARS; i++)); do
        PREV_VALUES[i]=0
    done
}

# Generate simulated audio spectrum data
generate_spectrum() {
    local beat_intensity=$((RANDOM % 30 + 70))
    local -a values=()

    # Create bass-heavy spectrum with peaks
    for ((i=0; i<NUM_BARS; i++)); do
        local base_value=0

        # Bass frequencies (first quarter)
        if [[ $i -lt $((NUM_BARS / 4)) ]]; then
            base_value=$((RANDOM % 40 + 40 + beat_intensity / 3))
        # Mid frequencies
        elif [[ $i -lt $((NUM_BARS / 2)) ]]; then
            base_value=$((RANDOM % 30 + 30))
        # High frequencies
        else
            base_value=$((RANDOM % 20 + 10))
        fi

        # Add random variation
        local variation=$((RANDOM % 20 - 10))
        local value=$((base_value + variation))

        # Smoothing with previous value
        if [[ -n "${PREV_VALUES[$i]}" ]]; then
            value=$(echo "scale=0; ${PREV_VALUES[$i]} * $SMOOTHING + $value * (1 - $SMOOTHING)" | bc 2>/dev/null || echo "$value")
        fi

        # Clamp values
        [[ $value -lt 0 ]] && value=0
        [[ $value -gt 100 ]] && value=100

        values+=("$value")
        PREV_VALUES[$i]=$value
    done

    echo "${values[*]}"
}

# Generate waveform data
generate_waveform() {
    local phase="${1:-0}"
    local -a values=()

    for ((i=0; i<VISUALIZER_WIDTH; i++)); do
        # Combine multiple sine waves for complex waveform
        local angle=$(echo "scale=4; ($i + $phase) * 0.15" | bc -l 2>/dev/null || echo "0")
        local wave1=$(echo "scale=4; s($angle) * 30 + 50" | bc -l 2>/dev/null || echo "50")
        local wave2=$(echo "scale=4; s($angle * 2.5) * 15" | bc -l 2>/dev/null || echo "0")
        local wave3=$(echo "scale=4; s($angle * 0.5) * 10" | bc -l 2>/dev/null || echo "0")

        local combined=$(echo "scale=0; $wave1 + $wave2 + $wave3 + ($RANDOM % 10)" | bc 2>/dev/null || echo "50")

        [[ $combined -lt 0 ]] && combined=0
        [[ $combined -gt 100 ]] && combined=100

        values+=("$combined")
    done

    echo "${values[*]}"
}

#───────────────────────────────────────────────────────────────────────────────
# VISUALIZATION RENDERING
#───────────────────────────────────────────────────────────────────────────────

get_color() {
    local value="$1"
    local max="${2:-100}"
    local scheme="${3:-$CURRENT_SCHEME}"

    local colors=(${COLOR_SCHEMES[$scheme]})
    local num_colors=${#colors[@]}

    local idx=$(( value * (num_colors - 1) / max ))
    [[ $idx -ge $num_colors ]] && idx=$((num_colors - 1))
    [[ $idx -lt 0 ]] && idx=0

    echo "\033[38;5;${colors[$idx]}m"
}

# Bar visualization
render_bars() {
    local spectrum="$1"
    local -a values=($spectrum)

    local bar_width=$((VISUALIZER_WIDTH / NUM_BARS))
    [[ $bar_width -lt 1 ]] && bar_width=1

    # Draw from bottom to top
    for ((row=VISUALIZER_HEIGHT; row>=1; row--)); do
        local threshold=$((row * 100 / VISUALIZER_HEIGHT))

        for ((i=0; i<NUM_BARS; i++)); do
            local value="${values[$i]:-0}"

            if [[ $value -ge $threshold ]]; then
                local color=$(get_color "$value")
                printf "%b" "$color"

                for ((w=0; w<bar_width; w++)); do
                    if [[ $row -eq $((value * VISUALIZER_HEIGHT / 100)) ]]; then
                        printf "█"
                    else
                        printf "▓"
                    fi
                done
            else
                printf "%*s" "$bar_width" ""
            fi
        done
        printf "\033[0m\n"
    done
}

# Wave visualization
render_wave() {
    local waveform="$1"
    local -a values=($waveform)

    # Create empty grid
    local -a grid
    for ((row=0; row<VISUALIZER_HEIGHT; row++)); do
        grid[$row]=""
        for ((col=0; col<VISUALIZER_WIDTH; col++)); do
            grid[$row]+=" "
        done
    done

    # Plot waveform
    for ((i=0; i<${#values[@]}; i++)); do
        local value="${values[$i]}"
        local y=$((VISUALIZER_HEIGHT - (value * VISUALIZER_HEIGHT / 100) - 1))

        [[ $y -lt 0 ]] && y=0
        [[ $y -ge $VISUALIZER_HEIGHT ]] && y=$((VISUALIZER_HEIGHT - 1))

        local color=$(get_color "$value")
        local row="${grid[$y]}"
        grid[$y]="${row:0:$i}${color}●\033[0m${row:$((i+1))}"
    done

    # Render
    for ((row=0; row<VISUALIZER_HEIGHT; row++)); do
        printf "%b\n" "${grid[$row]}"
    done
}

# Spectrum analyzer with mirror effect
render_spectrum() {
    local spectrum="$1"
    local -a values=($spectrum)

    local half_height=$((VISUALIZER_HEIGHT / 2))
    local bar_width=$((VISUALIZER_WIDTH / NUM_BARS))
    [[ $bar_width -lt 1 ]] && bar_width=1

    # Upper half (mirrored)
    for ((row=half_height; row>=1; row--)); do
        local threshold=$((row * 100 / half_height))

        for ((i=0; i<NUM_BARS; i++)); do
            local value="${values[$i]:-0}"

            if [[ $value -ge $threshold ]]; then
                local color=$(get_color "$value")
                printf "%b" "$color"
                for ((w=0; w<bar_width; w++)); do
                    printf "▀"
                done
            else
                printf "%*s" "$bar_width" ""
            fi
        done
        printf "\033[0m\n"
    done

    # Center line
    printf "\033[38;5;240m"
    printf "%0.s─" $(seq 1 $VISUALIZER_WIDTH)
    printf "\033[0m\n"

    # Lower half
    for ((row=1; row<=half_height; row++)); do
        local threshold=$((row * 100 / half_height))

        for ((i=0; i<NUM_BARS; i++)); do
            local value="${values[$i]:-0}"

            if [[ $value -ge $threshold ]]; then
                local color=$(get_color "$value")
                printf "%b" "$color"
                for ((w=0; w<bar_width; w++)); do
                    printf "▄"
                done
            else
                printf "%*s" "$bar_width" ""
            fi
        done
        printf "\033[0m\n"
    done
}

# Circular visualization
render_circle() {
    local spectrum="$1"
    local -a values=($spectrum)

    local center_x=$((VISUALIZER_WIDTH / 2))
    local center_y=$((VISUALIZER_HEIGHT / 2))
    local base_radius=5

    # Create empty grid
    local -a grid
    for ((row=0; row<VISUALIZER_HEIGHT; row++)); do
        for ((col=0; col<VISUALIZER_WIDTH; col++)); do
            grid[$((row * VISUALIZER_WIDTH + col))]=" "
        done
    done

    # Draw circle with varying radius based on spectrum
    local num_points=60
    for ((p=0; p<num_points; p++)); do
        local angle=$(echo "scale=4; $p * 6.28318 / $num_points" | bc -l 2>/dev/null || echo "0")

        local spectrum_idx=$((p * NUM_BARS / num_points))
        local value="${values[$spectrum_idx]:-50}"
        local radius=$(echo "scale=0; $base_radius + $value / 10" | bc 2>/dev/null || echo "$base_radius")

        local x=$(echo "scale=0; $center_x + c($angle) * $radius * 2" | bc -l 2>/dev/null || echo "$center_x")
        local y=$(echo "scale=0; $center_y + s($angle) * $radius" | bc -l 2>/dev/null || echo "$center_y")

        x=${x%.*}
        y=${y%.*}

        if [[ $x -ge 0 && $x -lt $VISUALIZER_WIDTH && $y -ge 0 && $y -lt $VISUALIZER_HEIGHT ]]; then
            local color=$(get_color "$value")
            grid[$((y * VISUALIZER_WIDTH + x))]="${color}●\033[0m"
        fi
    done

    # Render
    for ((row=0; row<VISUALIZER_HEIGHT; row++)); do
        for ((col=0; col<VISUALIZER_WIDTH; col++)); do
            printf "%b" "${grid[$((row * VISUALIZER_WIDTH + col))]}"
        done
        printf "\n"
    done
}

# Particle visualization
declare -a PARTICLES_X
declare -a PARTICLES_Y
declare -a PARTICLES_VX
declare -a PARTICLES_VY
declare -a PARTICLES_LIFE
NUM_PARTICLES=50

init_particles() {
    for ((i=0; i<NUM_PARTICLES; i++)); do
        PARTICLES_X[$i]=$((VISUALIZER_WIDTH / 2))
        PARTICLES_Y[$i]=$((VISUALIZER_HEIGHT / 2))
        PARTICLES_VX[$i]=0
        PARTICLES_VY[$i]=0
        PARTICLES_LIFE[$i]=0
    done
}

render_particles() {
    local spectrum="$1"
    local -a values=($spectrum)

    # Calculate beat intensity
    local beat=0
    for val in "${values[@]:0:10}"; do
        beat=$((beat + val))
    done
    beat=$((beat / 10))

    # Spawn new particles on beat
    if [[ $beat -gt 60 ]]; then
        for ((i=0; i<NUM_PARTICLES; i++)); do
            if [[ ${PARTICLES_LIFE[$i]} -le 0 ]]; then
                PARTICLES_X[$i]=$((VISUALIZER_WIDTH / 2))
                PARTICLES_Y[$i]=$((VISUALIZER_HEIGHT / 2))
                PARTICLES_VX[$i]=$((RANDOM % 7 - 3))
                PARTICLES_VY[$i]=$((RANDOM % 5 - 2))
                PARTICLES_LIFE[$i]=$((20 + RANDOM % 20))
                break
            fi
        done
    fi

    # Create grid
    local -a grid
    for ((row=0; row<VISUALIZER_HEIGHT; row++)); do
        for ((col=0; col<VISUALIZER_WIDTH; col++)); do
            grid[$((row * VISUALIZER_WIDTH + col))]=" "
        done
    done

    # Update and draw particles
    for ((i=0; i<NUM_PARTICLES; i++)); do
        if [[ ${PARTICLES_LIFE[$i]} -gt 0 ]]; then
            # Update position
            PARTICLES_X[$i]=$((PARTICLES_X[$i] + PARTICLES_VX[$i]))
            PARTICLES_Y[$i]=$((PARTICLES_Y[$i] + PARTICLES_VY[$i]))
            PARTICLES_LIFE[$i]=$((PARTICLES_LIFE[$i] - 1))

            local x=${PARTICLES_X[$i]}
            local y=${PARTICLES_Y[$i]}

            if [[ $x -ge 0 && $x -lt $VISUALIZER_WIDTH && $y -ge 0 && $y -lt $VISUALIZER_HEIGHT ]]; then
                local intensity=$((PARTICLES_LIFE[$i] * 100 / 40))
                local color=$(get_color "$intensity")
                local char="·"
                [[ ${PARTICLES_LIFE[$i]} -gt 15 ]] && char="•"
                [[ ${PARTICLES_LIFE[$i]} -gt 25 ]] && char="●"
                grid[$((y * VISUALIZER_WIDTH + x))]="${color}${char}\033[0m"
            fi
        fi
    done

    # Render
    for ((row=0; row<VISUALIZER_HEIGHT; row++)); do
        for ((col=0; col<VISUALIZER_WIDTH; col++)); do
            printf "%b" "${grid[$((row * VISUALIZER_WIDTH + col))]}"
        done
        printf "\n"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# VU METER
#───────────────────────────────────────────────────────────────────────────────

render_vu_meter() {
    local left="${1:-50}"
    local right="${2:-50}"
    local width=30

    local left_bars=$((left * width / 100))
    local right_bars=$((right * width / 100))

    printf "  L "
    for ((i=0; i<width; i++)); do
        if [[ $i -lt $left_bars ]]; then
            if [[ $i -gt $((width * 8 / 10)) ]]; then
                printf "\033[38;5;196m█\033[0m"
            elif [[ $i -gt $((width * 6 / 10)) ]]; then
                printf "\033[38;5;226m█\033[0m"
            else
                printf "\033[38;5;46m█\033[0m"
            fi
        else
            printf "\033[38;5;240m░\033[0m"
        fi
    done
    printf " %3d%%\n" "$left"

    printf "  R "
    for ((i=0; i<width; i++)); do
        if [[ $i -lt $right_bars ]]; then
            if [[ $i -gt $((width * 8 / 10)) ]]; then
                printf "\033[38;5;196m█\033[0m"
            elif [[ $i -gt $((width * 6 / 10)) ]]; then
                printf "\033[38;5;226m█\033[0m"
            else
                printf "\033[38;5;46m█\033[0m"
            fi
        else
            printf "\033[38;5;240m░\033[0m"
        fi
    done
    printf " %3d%%\n" "$right"
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN VISUALIZER
#───────────────────────────────────────────────────────────────────────────────

visualizer_loop() {
    clear
    tput civis  # Hide cursor

    init_values
    init_particles

    local phase=0

    trap 'tput cnorm; clear; exit 0' INT TERM

    while true; do
        tput cup 0 0

        # Header
        printf "\033[38;5;201m"
        printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
        printf "║                       🎵 BLACKROAD MUSIC VISUALIZER                          ║\n"
        printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
        printf "\033[0m\n"

        # Mode indicator
        printf "  Mode: \033[38;5;51m%s\033[0m  " "$CURRENT_MODE"
        printf "Scheme: \033[38;5;201m%s\033[0m\n\n" "$CURRENT_SCHEME"

        # Generate and render visualization
        case "$CURRENT_MODE" in
            "$MODE_BARS")
                local spectrum=$(generate_spectrum)
                render_bars "$spectrum"
                ;;
            "$MODE_WAVE")
                local waveform=$(generate_waveform "$phase")
                render_wave "$waveform"
                ((phase += 5))
                ;;
            "$MODE_SPECTRUM")
                local spectrum=$(generate_spectrum)
                render_spectrum "$spectrum"
                ;;
            "$MODE_CIRCLE")
                local spectrum=$(generate_spectrum)
                render_circle "$spectrum"
                ;;
            "$MODE_PARTICLES")
                local spectrum=$(generate_spectrum)
                render_particles "$spectrum"
                ;;
        esac

        # VU Meters
        printf "\n"
        local left=$((RANDOM % 40 + 40))
        local right=$((RANDOM % 40 + 40))
        render_vu_meter "$left" "$right"

        # Controls
        printf "\n\033[38;5;240m───────────────────────────────────────────────────────────────────────────────\033[0m\n"
        printf "  [1-5] Mode  [C] Color  [Q] Quit                                             \n"

        # Handle input
        if read -rsn1 -t 0.08 key 2>/dev/null; then
            case "$key" in
                1) CURRENT_MODE="$MODE_BARS" ;;
                2) CURRENT_MODE="$MODE_WAVE" ;;
                3) CURRENT_MODE="$MODE_SPECTRUM" ;;
                4) CURRENT_MODE="$MODE_CIRCLE" ;;
                5) CURRENT_MODE="$MODE_PARTICLES"; init_particles ;;
                c|C)
                    local schemes=(rainbow fire ocean matrix purple mono)
                    local current_idx=0
                    for ((i=0; i<${#schemes[@]}; i++)); do
                        [[ "${schemes[$i]}" == "$CURRENT_SCHEME" ]] && current_idx=$i
                    done
                    CURRENT_SCHEME="${schemes[$(( (current_idx + 1) % ${#schemes[@]} ))]}"
                    ;;
                q|Q)
                    tput cnorm
                    clear
                    exit 0
                    ;;
            esac
        fi
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-run}" in
        run)    visualizer_loop ;;
        bars)   CURRENT_MODE="$MODE_BARS"; visualizer_loop ;;
        wave)   CURRENT_MODE="$MODE_WAVE"; visualizer_loop ;;
        spectrum) CURRENT_MODE="$MODE_SPECTRUM"; visualizer_loop ;;
        circle) CURRENT_MODE="$MODE_CIRCLE"; visualizer_loop ;;
        particles) CURRENT_MODE="$MODE_PARTICLES"; visualizer_loop ;;
        *)
            printf "Usage: %s [run|bars|wave|spectrum|circle|particles]\n" "$0"
            ;;
    esac
fi
