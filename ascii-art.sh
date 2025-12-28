#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#   █████╗ ███████╗ ██████╗██╗██╗     █████╗ ██████╗ ████████╗
#  ██╔══██╗██╔════╝██╔════╝██║██║    ██╔══██╗██╔══██╗╚══██╔══╝
#  ███████║███████╗██║     ██║██║    ███████║██████╔╝   ██║
#  ██╔══██║╚════██║██║     ██║██║    ██╔══██║██╔══██╗   ██║
#  ██║  ██║███████║╚██████╗██║██║    ██║  ██║██║  ██║   ██║
#  ╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝╚═╝    ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD ASCII ART GENERATOR v3.0
#  Text to ASCII, Image to ASCII, Banners & FIGlet Compatible
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# BUILT-IN ASCII FONTS
#───────────────────────────────────────────────────────────────────────────────

# Block font (uppercase only)
declare -A FONT_BLOCK
FONT_BLOCK[A]='
 ███╗
██╔██╗
█████║
██╔██║
██║██║'
FONT_BLOCK[B]='
████╗
██╔██╗
████╔╝
██╔██╗
████╔╝'
FONT_BLOCK[C]='
 ████╗
██╔══╝
██║
██║
╚████╗'
FONT_BLOCK[D]='
████╗
██╔██╗
██║██║
██║██║
████╔╝'
FONT_BLOCK[E]='
█████╗
██╔══╝
████╗
██╔══╝
█████╗'
FONT_BLOCK[F]='
█████╗
██╔══╝
████╗
██╔══╝
██║   '
FONT_BLOCK[G]='
 ████╗
██╔══╝
██║██╗
██║██║
╚████║'
FONT_BLOCK[H]='
██╗██╗
██║██║
█████║
██╔██║
██║██║'
FONT_BLOCK[I]='
████╗
╚██╔╝
 ██║
 ██║
████╗'
FONT_BLOCK[J]='
  ██╗
  ██║
  ██║
██╗██║
╚███╔╝'
FONT_BLOCK[K]='
██╗██╗
██║██╔
███╔╝
██╔██╗
██║██║'
FONT_BLOCK[L]='
██╗
██║
██║
██║
█████╗'
FONT_BLOCK[M]='
██╗ ██╗
███╗██║
██╔███║
██║╚██║
██║ ██║'
FONT_BLOCK[N]='
██╗ ██╗
███╗██║
█╔███║
██║╚██║
██║ ██║'
FONT_BLOCK[O]='
 ███╗
██╔██╗
██║██║
██║██║
╚███╔╝'
FONT_BLOCK[P]='
████╗
██╔██╗
████╔╝
██╔══╝
██║   '
FONT_BLOCK[Q]='
 ███╗
██╔██╗
██║██║
██╔██║
╚██╔██╗'
FONT_BLOCK[R]='
████╗
██╔██╗
████╔╝
██╔██╗
██║██║'
FONT_BLOCK[S]='
█████╗
██╔══╝
╚███╗
 ╚═██║
████╔╝'
FONT_BLOCK[T]='
█████╗
╚═██═╝
  ██║
  ██║
  ██║ '
FONT_BLOCK[U]='
██╗██╗
██║██║
██║██║
██║██║
╚███╔╝'
FONT_BLOCK[V]='
██╗██╗
██║██║
██║██║
╚███╔╝
 ╚═╝  '
FONT_BLOCK[W]='
██╗ ██╗
██║ ██║
██║ ██║
██╔███║
╚═╝╚═╝ '
FONT_BLOCK[X]='
██╗██╗
╚███╔╝
 ███╗
██╔██╗
██╝██║'
FONT_BLOCK[Y]='
██╗██╗
╚███╔╝
 ██║
 ██║
 ██║  '
FONT_BLOCK[Z]='
████╗
╚═██║
 ██╔╝
██╔╝
████╗'
FONT_BLOCK[0]='
 ███╗
██╗██║
██║██║
██║██║
╚███╔╝'
FONT_BLOCK[1]='
 ██╗
███║
╚██║
 ██║
███╗'
FONT_BLOCK[2]='
████╗
╚══██
 ██╔╝
██╔╝
████╗'
FONT_BLOCK[3]='
████╗
╚══██
 ██╔╝
╚═██║
███╔╝'
FONT_BLOCK[4]='
██╗██
██║██
████╗
╚═██║
  ██║'
FONT_BLOCK[5]='
████╗
██══╝
███╗
╚═██║
███╔╝'
FONT_BLOCK[6]='
 ███╗
██══╝
███╗
██╔██
╚██╔╝'
FONT_BLOCK[7]='
████╗
╚═██║
  ██║
  ██║
  ██║'
FONT_BLOCK[8]='
 ███╗
██╔██
╚██╔╝
██╔██
╚██╔╝'
FONT_BLOCK[9]='
 ███╗
██╔██
╚███║
╚═██║
███╔╝'
FONT_BLOCK[' ']='




     '
FONT_BLOCK['!']='
██╗
██║
██║
╚═╝
██╗'

#───────────────────────────────────────────────────────────────────────────────
# SIMPLE BANNER FONT
#───────────────────────────────────────────────────────────────────────────────

declare -A FONT_SIMPLE
FONT_SIMPLE[A]='
  A
 A A
AAAAA
A   A
A   A'
FONT_SIMPLE[B]='
BBBB
B   B
BBBB
B   B
BBBB '
FONT_SIMPLE[C]='
 CCC
C
C
C
 CCC '
FONT_SIMPLE[D]='
DDD
D  D
D   D
D  D
DDD  '
FONT_SIMPLE[E]='
EEEEE
E
EEE
E
EEEEE'
FONT_SIMPLE[F]='
FFFFF
F
FFF
F
F    '
FONT_SIMPLE[G]='
 GGG
G
G  GG
G   G
 GGG '
FONT_SIMPLE[H]='
H   H
H   H
HHHHH
H   H
H   H'
FONT_SIMPLE[I]='
IIIII
  I
  I
  I
IIIII'
FONT_SIMPLE[J]='
JJJJJ
    J
    J
J   J
 JJJ '
FONT_SIMPLE[K]='
K   K
K  K
KKK
K  K
K   K'
FONT_SIMPLE[L]='
L
L
L
L
LLLLL'
FONT_SIMPLE[M]='
M   M
MM MM
M M M
M   M
M   M'
FONT_SIMPLE[N]='
N   N
NN  N
N N N
N  NN
N   N'
FONT_SIMPLE[O]='
 OOO
O   O
O   O
O   O
 OOO '
FONT_SIMPLE[P]='
PPPP
P   P
PPPP
P
P    '
FONT_SIMPLE[Q]='
 QQQ
Q   Q
Q   Q
Q  Q
 QQ Q'
FONT_SIMPLE[R]='
RRRR
R   R
RRRR
R  R
R   R'
FONT_SIMPLE[S]='
 SSS
S
 SSS
    S
SSSS '
FONT_SIMPLE[T]='
TTTTT
  T
  T
  T
  T  '
FONT_SIMPLE[U]='
U   U
U   U
U   U
U   U
 UUU '
FONT_SIMPLE[V]='
V   V
V   V
V   V
 V V
  V  '
FONT_SIMPLE[W]='
W   W
W   W
W W W
WW WW
W   W'
FONT_SIMPLE[X]='
X   X
 X X
  X
 X X
X   X'
FONT_SIMPLE[Y]='
Y   Y
 Y Y
  Y
  Y
  Y  '
FONT_SIMPLE[Z]='
ZZZZZ
   Z
  Z
 Z
ZZZZZ'
FONT_SIMPLE[' ']='




     '

#───────────────────────────────────────────────────────────────────────────────
# SHADOW FONT
#───────────────────────────────────────────────────────────────────────────────

declare -A FONT_SHADOW
FONT_SHADOW[A]='
    _
   / \
  / _ \
 / ___ \
/_/   \_\'
FONT_SHADOW[B]='
 ____
| __ )
|  _ \
| |_) |
|____/ '
FONT_SHADOW[C]='
  ____
 / ___|
| |
| |___
 \____|'
FONT_SHADOW[D]='
 ____
|  _ \
| | | |
| |_| |
|____/ '
FONT_SHADOW[E]='
 _____
| ____|
|  _|
| |___
|_____|'
FONT_SHADOW[F]='
 _____
|  ___|
| |_
|  _|
|_|    '
FONT_SHADOW[G]='
  ____
 / ___|
| |  _
| |_| |
 \____|'
FONT_SHADOW[H]='
 _   _
| | | |
| |_| |
|  _  |
|_| |_|'
FONT_SHADOW[I]='
 ___
|_ _|
 | |
 | |
|___|'
FONT_SHADOW[J]='
     _
    | |
 _  | |
| |_| |
 \___/ '
FONT_SHADOW[K]='
 _  __
| |/ /
| | /
| |\ \
|_| \_\'
FONT_SHADOW[L]='
 _
| |
| |
| |___
|_____|'
FONT_SHADOW[M]='
 __  __
|  \/  |
| |\/| |
| |  | |
|_|  |_|'
FONT_SHADOW[N]='
 _   _
| \ | |
|  \| |
| |\  |
|_| \_|'
FONT_SHADOW[O]='
  ___
 / _ \
| | | |
| |_| |
 \___/ '
FONT_SHADOW[P]='
 ____
|  _ \
| |_) |
|  __/
|_|    '
FONT_SHADOW[Q]='
  ___
 / _ \
| | | |
| |_| |
 \__\_\'
FONT_SHADOW[R]='
 ____
|  _ \
| |_) |
|  _ <
|_| \_\'
FONT_SHADOW[S]='
 ____
/ ___|
\___ \
 ___) |
|____/ '
FONT_SHADOW[T]='
 _____
|_   _|
  | |
  | |
  |_|  '
FONT_SHADOW[U]='
 _   _
| | | |
| | | |
| |_| |
 \___/ '
FONT_SHADOW[V]='
__     __
\ \   / /
 \ \ / /
  \ V /
   \_/   '
FONT_SHADOW[W]='
__        __
\ \      / /
 \ \ /\ / /
  \ V  V /
   \_/\_/   '
FONT_SHADOW[X]='
__  __
\ \/ /
 \  /
 /  \
/_/\_\'
FONT_SHADOW[Y]='
__   __
\ \ / /
 \ V /
  | |
  |_|  '
FONT_SHADOW[Z]='
 _____
|__  /
  / /
 / /_
/____|'
FONT_SHADOW[' ']='




     '

#───────────────────────────────────────────────────────────────────────────────
# TEXT TO ASCII
#───────────────────────────────────────────────────────────────────────────────

# Get number of lines in a font character
get_font_height() {
    local font_name="${1:-SIMPLE}"
    local -n font_ref="FONT_${font_name^^}"

    local sample="${font_ref[A]}"
    local height=0

    while IFS= read -r line; do
        ((height++))
    done <<< "$sample"

    echo "$height"
}

# Render text in ASCII art
render_ascii_text() {
    local text="$1"
    local font_name="${2:-SIMPLE}"
    local color="${3:-}"

    local -n font_ref="FONT_${font_name^^}"
    local height=$(get_font_height "$font_name")

    text="${text^^}"  # Convert to uppercase

    # Build output line by line
    for ((line=1; line<=height; line++)); do
        for ((i=0; i<${#text}; i++)); do
            local char="${text:$i:1}"
            local char_art="${font_ref[$char]:-${font_ref[' ']}}"

            # Get the specific line
            local char_line=$(echo "$char_art" | sed -n "${line}p")
            [[ -n "$color" ]] && printf "%s" "$color"
            printf "%s" "$char_line"
            [[ -n "$color" ]] && printf "${RST}"
        done
        printf "\n"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# ASCII ART BOXES
#───────────────────────────────────────────────────────────────────────────────

render_box() {
    local text="$1"
    local style="${2:-single}"
    local padding="${3:-1}"
    local color="${4:-}"

    local text_len=${#text}
    local inner_width=$((text_len + padding * 2))

    # Box characters
    local tl tr bl br h v
    case "$style" in
        single)
            tl="┌" tr="┐" bl="└" br="┘" h="─" v="│"
            ;;
        double)
            tl="╔" tr="╗" bl="╚" br="╝" h="═" v="║"
            ;;
        bold)
            tl="┏" tr="┓" bl="┗" br="┛" h="━" v="┃"
            ;;
        round)
            tl="╭" tr="╮" bl="╰" br="╯" h="─" v="│"
            ;;
        ascii)
            tl="+" tr="+" bl="+" br="+" h="-" v="|"
            ;;
        *)
            tl="┌" tr="┐" bl="└" br="┘" h="─" v="│"
            ;;
    esac

    [[ -n "$color" ]] && printf "%s" "$color"

    # Top border
    printf "%s" "$tl"
    printf "%0.s$h" $(seq 1 $inner_width)
    printf "%s\n" "$tr"

    # Content
    printf "%s" "$v"
    printf "%*s%s%*s" "$padding" "" "$text" "$padding" ""
    printf "%s\n" "$v"

    # Bottom border
    printf "%s" "$bl"
    printf "%0.s$h" $(seq 1 $inner_width)
    printf "%s\n" "$br"

    [[ -n "$color" ]] && printf "${RST}"
}

render_multiline_box() {
    local style="${1:-single}"
    local color="${2:-}"
    shift 2
    local -a lines=("$@")

    # Find max line length
    local max_len=0
    for line in "${lines[@]}"; do
        [[ ${#line} -gt $max_len ]] && max_len=${#line}
    done

    local inner_width=$((max_len + 2))

    # Box characters
    local tl tr bl br h v
    case "$style" in
        single) tl="┌" tr="┐" bl="└" br="┘" h="─" v="│" ;;
        double) tl="╔" tr="╗" bl="╚" br="╝" h="═" v="║" ;;
        bold)   tl="┏" tr="┓" bl="┗" br="┛" h="━" v="┃" ;;
        round)  tl="╭" tr="╮" bl="╰" br="╯" h="─" v="│" ;;
        *)      tl="┌" tr="┐" bl="└" br="┘" h="─" v="│" ;;
    esac

    [[ -n "$color" ]] && printf "%s" "$color"

    # Top border
    printf "%s" "$tl"
    printf "%0.s$h" $(seq 1 $inner_width)
    printf "%s\n" "$tr"

    # Content lines
    for line in "${lines[@]}"; do
        printf "%s %-*s %s\n" "$v" "$max_len" "$line" "$v"
    done

    # Bottom border
    printf "%s" "$bl"
    printf "%0.s$h" $(seq 1 $inner_width)
    printf "%s\n" "$br"

    [[ -n "$color" ]] && printf "${RST}"
}

#───────────────────────────────────────────────────────────────────────────────
# ASCII SHAPES
#───────────────────────────────────────────────────────────────────────────────

render_triangle() {
    local height="${1:-5}"
    local char="${2:-*}"
    local color="${3:-}"

    [[ -n "$color" ]] && printf "%s" "$color"

    for ((i=1; i<=height; i++)); do
        local spaces=$((height - i))
        local chars=$((2 * i - 1))

        printf "%*s" "$spaces" ""
        printf "%0.s$char" $(seq 1 $chars)
        printf "\n"
    done

    [[ -n "$color" ]] && printf "${RST}"
}

render_diamond() {
    local size="${1:-5}"
    local char="${2:-*}"
    local color="${3:-}"

    [[ -n "$color" ]] && printf "%s" "$color"

    # Top half
    for ((i=1; i<=size; i++)); do
        printf "%*s" "$((size - i))" ""
        printf "%0.s$char" $(seq 1 $((2 * i - 1)))
        printf "\n"
    done

    # Bottom half
    for ((i=size-1; i>=1; i--)); do
        printf "%*s" "$((size - i))" ""
        printf "%0.s$char" $(seq 1 $((2 * i - 1)))
        printf "\n"
    done

    [[ -n "$color" ]] && printf "${RST}"
}

render_heart() {
    local color="${1:-$BR_RED}"

    printf "%s" "$color"
    cat << 'EOF'
   ****     ****
 ********  ********
*********************
 *******************
   ***************
     ***********
       *******
         ***
          *
EOF
    printf "${RST}"
}

render_star() {
    local color="${1:-$BR_YELLOW}"

    printf "%s" "$color"
    cat << 'EOF'
         *
        ***
       *****
  *************
   ***********
    *********
   ***     ***
  **         **
 *             *
EOF
    printf "${RST}"
}

render_skull() {
    local color="${1:-}"

    [[ -n "$color" ]] && printf "%s" "$color"
    cat << 'EOF'
     ______
   .-.      .-.
  (  |      |  )
   \ \      / /
    ) )    ( (
   / /  ()  \ \
  ( /   ||   \ )
   \\  /__\  //
    \\______//
     |______|
    / ||  || \
   /  ||  ||  \
  /___||__||___\
EOF
    [[ -n "$color" ]] && printf "${RST}"
}

#───────────────────────────────────────────────────────────────────────────────
# IMAGE TO ASCII
#───────────────────────────────────────────────────────────────────────────────

image_to_ascii() {
    local image_path="$1"
    local width="${2:-80}"
    local chars="${3:- .:-=+*#%@}"

    if [[ ! -f "$image_path" ]]; then
        printf "${BR_RED}Image not found: %s${RST}\n" "$image_path"
        return 1
    fi

    # Check for required tools
    if ! command -v convert &>/dev/null; then
        printf "${TEXT_MUTED}ImageMagick required for image conversion${RST}\n"

        # Try jp2a if available
        if command -v jp2a &>/dev/null; then
            jp2a --width="$width" "$image_path"
            return
        fi

        return 1
    fi

    # Convert image to grayscale and resize
    local temp_file="/tmp/ascii_temp_$$.txt"

    convert "$image_path" \
        -resize "${width}x" \
        -colorspace Gray \
        -depth 8 \
        txt:- 2>/dev/null | \
    tail -n +2 | \
    while IFS=: read -r coord color; do
        # Extract grayscale value
        local gray=$(echo "$color" | grep -oP 'gray\(\K[0-9]+')
        [[ -z "$gray" ]] && gray=0

        # Map to character
        local char_count=${#chars}
        local idx=$((gray * (char_count - 1) / 255))
        printf "%s" "${chars:$idx:1}"

        # Newline at end of row
        local x=$(echo "$coord" | grep -oP '^\d+')
        local next_x=$((x + 1))
        if [[ "$coord" == *",0:" ]]; then
            [[ "$x" != "0" ]] && printf "\n"
        fi
    done

    printf "\n"
}

#───────────────────────────────────────────────────────────────────────────────
# GRADIENT TEXT
#───────────────────────────────────────────────────────────────────────────────

render_gradient_text() {
    local text="$1"
    local start_r="${2:-255}"
    local start_g="${3:-0}"
    local start_b="${4:-0}"
    local end_r="${5:-0}"
    local end_g="${6:-0}"
    local end_b="${7:-255}"

    local len=${#text}

    for ((i=0; i<len; i++)); do
        local ratio=$(echo "$i / ($len - 1)" | bc -l 2>/dev/null || echo 0)

        local r=$(printf "%.0f" "$(echo "$start_r + ($end_r - $start_r) * $ratio" | bc -l 2>/dev/null || echo $start_r)")
        local g=$(printf "%.0f" "$(echo "$start_g + ($end_g - $start_g) * $ratio" | bc -l 2>/dev/null || echo $start_g)")
        local b=$(printf "%.0f" "$(echo "$start_b + ($end_b - $start_b) * $ratio" | bc -l 2>/dev/null || echo $start_b)")

        printf "\033[38;2;%d;%d;%dm%s" "$r" "$g" "$b" "${text:$i:1}"
    done
    printf "${RST}\n"
}

render_rainbow_text() {
    local text="$1"
    local len=${#text}

    local -a colors=(
        "255;0;0"     # Red
        "255;127;0"   # Orange
        "255;255;0"   # Yellow
        "0;255;0"     # Green
        "0;255;255"   # Cyan
        "0;0;255"     # Blue
        "127;0;255"   # Purple
    )

    for ((i=0; i<len; i++)); do
        local color_idx=$((i % ${#colors[@]}))
        printf "\033[38;2;%sm%s" "${colors[$color_idx]}" "${text:$i:1}"
    done
    printf "${RST}\n"
}

#───────────────────────────────────────────────────────────────────────────────
# BANNER GENERATOR
#───────────────────────────────────────────────────────────────────────────────

generate_banner() {
    local text="$1"
    local style="${2:-double}"
    local font="${3:-SIMPLE}"
    local color="${4:-$BR_CYAN}"

    # Capture ASCII text
    local ascii_output=$(render_ascii_text "$text" "$font")
    local -a lines=()

    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$ascii_output"

    # Render in box
    render_multiline_box "$style" "$color" "${lines[@]}"
}

#───────────────────────────────────────────────────────────────────────────────
# INTERACTIVE GENERATOR
#───────────────────────────────────────────────────────────────────────────────

ascii_interactive() {
    clear_screen

    printf "${BR_PURPLE}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                      🎨 ASCII ART GENERATOR                                  ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    while true; do
        printf "\n${BOLD}Options:${RST}\n"
        printf "  ${BR_CYAN}1.${RST} Text to ASCII (Simple font)\n"
        printf "  ${BR_CYAN}2.${RST} Text to ASCII (Block font)\n"
        printf "  ${BR_CYAN}3.${RST} Text to ASCII (Shadow font)\n"
        printf "  ${BR_CYAN}4.${RST} Generate Banner\n"
        printf "  ${BR_CYAN}5.${RST} Rainbow Text\n"
        printf "  ${BR_CYAN}6.${RST} Gradient Text\n"
        printf "  ${BR_CYAN}7.${RST} Shapes Gallery\n"
        printf "  ${TEXT_MUTED}Q.${RST} Quit\n"
        printf "\n${BR_CYAN}Choice: ${RST}"

        read -rsn1 choice

        case "$choice" in
            1)
                printf "\n${BR_CYAN}Enter text: ${RST}"
                read -r text
                printf "\n"
                render_ascii_text "$text" "SIMPLE" "$BR_GREEN"
                ;;
            2)
                printf "\n${BR_CYAN}Enter text: ${RST}"
                read -r text
                printf "\n"
                render_ascii_text "$text" "BLOCK" "$BR_CYAN"
                ;;
            3)
                printf "\n${BR_CYAN}Enter text: ${RST}"
                read -r text
                printf "\n"
                render_ascii_text "$text" "SHADOW" "$BR_PURPLE"
                ;;
            4)
                printf "\n${BR_CYAN}Enter text: ${RST}"
                read -r text
                printf "\n"
                generate_banner "$text" "double" "SIMPLE" "$BR_YELLOW"
                ;;
            5)
                printf "\n${BR_CYAN}Enter text: ${RST}"
                read -r text
                printf "\n"
                render_rainbow_text "$text"
                ;;
            6)
                printf "\n${BR_CYAN}Enter text: ${RST}"
                read -r text
                printf "\n"
                render_gradient_text "$text" 255 0 0 0 0 255
                ;;
            7)
                printf "\n${BOLD}Shapes Gallery:${RST}\n\n"
                printf "${BR_YELLOW}Triangle:${RST}\n"
                render_triangle 5 "▲" "$BR_GREEN"
                printf "\n${BR_YELLOW}Diamond:${RST}\n"
                render_diamond 4 "◆" "$BR_CYAN"
                printf "\n${BR_YELLOW}Heart:${RST}\n"
                render_heart
                printf "\n${BR_YELLOW}Star:${RST}\n"
                render_star
                ;;
            q|Q)
                break
                ;;
        esac

        printf "\n${TEXT_MUTED}Press any key to continue...${RST}"
        read -rsn1
        clear_screen
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-interactive}" in
        interactive) ascii_interactive ;;
        text)        render_ascii_text "$2" "${3:-SIMPLE}" "${4:-}" ;;
        banner)      generate_banner "$2" "${3:-double}" "${4:-SIMPLE}" "${5:-}" ;;
        box)         render_box "$2" "${3:-single}" "${4:-1}" "${5:-}" ;;
        rainbow)     render_rainbow_text "$2" ;;
        gradient)    render_gradient_text "$2" "${3:-255}" "${4:-0}" "${5:-0}" "${6:-0}" "${7:-0}" "${8:-255}" ;;
        heart)       render_heart "${2:-}" ;;
        star)        render_star "${2:-}" ;;
        skull)       render_skull "${2:-}" ;;
        triangle)    render_triangle "${2:-5}" "${3:-*}" "${4:-}" ;;
        diamond)     render_diamond "${2:-5}" "${3:-*}" "${4:-}" ;;
        image)       image_to_ascii "$2" "${3:-80}" "${4:-}" ;;
        *)
            printf "BlackRoad ASCII Art Generator v3.0\n\n"
            printf "Usage: %s [command] [options]\n\n" "$0"
            printf "Commands:\n"
            printf "  interactive           Interactive mode\n"
            printf "  text <text> [font]    Convert text to ASCII (fonts: SIMPLE, BLOCK, SHADOW)\n"
            printf "  banner <text>         Generate boxed banner\n"
            printf "  box <text> [style]    Draw text in box (single, double, bold, round)\n"
            printf "  rainbow <text>        Rainbow colored text\n"
            printf "  gradient <text>       Gradient colored text\n"
            printf "  heart/star/skull      Render shape\n"
            printf "  triangle/diamond      Render shape with size\n"
            printf "  image <path> [width]  Convert image to ASCII\n"
            ;;
    esac
fi
