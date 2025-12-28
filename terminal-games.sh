#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#   ██████╗  █████╗ ███╗   ███╗███████╗███████╗
#  ██╔════╝ ██╔══██╗████╗ ████║██╔════╝██╔════╝
#  ██║  ███╗███████║██╔████╔██║█████╗  ███████╗
#  ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ╚════██║
#  ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗███████║
#   ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD TERMINAL GAMES v3.0
#  Snake, Tetris, Pong, and More - Pure Bash Gaming!
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

HIGHSCORE_FILE="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}/highscores.json"
mkdir -p "$(dirname "$HIGHSCORE_FILE")" 2>/dev/null

#───────────────────────────────────────────────────────────────────────────────
# TERMINAL UTILITIES
#───────────────────────────────────────────────────────────────────────────────

get_term_size() {
    local cols=$(tput cols)
    local rows=$(tput lines)
    echo "$cols $rows"
}

cursor_to() {
    printf "\033[%d;%dH" "$1" "$2"
}

clear_screen() {
    printf "\033[2J\033[H"
}

cursor_hide() {
    printf "\033[?25l"
}

cursor_show() {
    printf "\033[?25h"
}

# Non-blocking key read
read_key() {
    local key
    read -rsn1 -t 0.1 key 2>/dev/null
    if [[ "$key" == $'\x1b' ]]; then
        read -rsn2 -t 0.01 key2
        key+="$key2"
    fi
    echo "$key"
}

#───────────────────────────────────────────────────────────────────────────────
# HIGH SCORES
#───────────────────────────────────────────────────────────────────────────────

save_highscore() {
    local game="$1"
    local score="$2"
    local name="${3:-Anonymous}"

    if command -v jq &>/dev/null; then
        local data="{}"
        [[ -f "$HIGHSCORE_FILE" ]] && data=$(cat "$HIGHSCORE_FILE")

        local entry="{\"name\":\"$name\",\"score\":$score,\"date\":\"$(date -Iseconds)\"}"
        local updated=$(echo "$data" | jq ".$game = (.$game // []) + [$entry] | .$game |= sort_by(-.score)[:10]")
        echo "$updated" > "$HIGHSCORE_FILE"
    fi
}

get_highscore() {
    local game="$1"

    if [[ -f "$HIGHSCORE_FILE" ]] && command -v jq &>/dev/null; then
        jq -r ".$game[0].score // 0" "$HIGHSCORE_FILE" 2>/dev/null
    else
        echo "0"
    fi
}

show_highscores() {
    local game="$1"

    printf "${BOLD}High Scores - %s${RST}\n\n" "${game^}"

    if [[ -f "$HIGHSCORE_FILE" ]] && command -v jq &>/dev/null; then
        printf "%-4s %-20s %-10s\n" "#" "NAME" "SCORE"
        printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────"

        local idx=1
        while IFS='|' read -r name score; do
            printf "${BR_CYAN}%-4d${RST} %-20s ${BR_YELLOW}%-10s${RST}\n" "$idx" "$name" "$score"
            ((idx++))
        done < <(jq -r ".$game[]? | \"\(.name)|\(.score)\"" "$HIGHSCORE_FILE" 2>/dev/null | head -10)
    else
        printf "${TEXT_MUTED}No scores yet!${RST}\n"
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
#  SNAKE GAME
#═══════════════════════════════════════════════════════════════════════════════

play_snake() {
    local width=40
    local height=20
    local speed=0.1

    # Snake data
    local -a snake_x=(10 9 8)
    local -a snake_y=(10 10 10)
    local direction="right"
    local next_direction="right"

    # Food
    local food_x=$((RANDOM % (width - 2) + 1))
    local food_y=$((RANDOM % (height - 2) + 1))

    # Game state
    local score=0
    local game_over=false
    local highscore=$(get_highscore "snake")

    clear_screen
    cursor_hide

    # Game loop
    while [[ "$game_over" == "false" ]]; do
        # Draw border
        cursor_to 1 1
        printf "${BR_GREEN}"
        printf "╔"
        printf "%0.s═" $(seq 1 $width)
        printf "╗\n"

        for ((y=1; y<height; y++)); do
            printf "║"
            printf "%${width}s" ""
            printf "║\n"
        done

        printf "╚"
        printf "%0.s═" $(seq 1 $width)
        printf "╝${RST}\n"

        # Draw snake
        for ((i=0; i<${#snake_x[@]}; i++)); do
            cursor_to $((snake_y[i] + 1)) $((snake_x[i] + 1))
            if [[ $i -eq 0 ]]; then
                printf "${BR_GREEN}●${RST}"  # Head
            else
                printf "${BR_GREEN}○${RST}"  # Body
            fi
        done

        # Draw food
        cursor_to $((food_y + 1)) $((food_x + 1))
        printf "${BR_RED}★${RST}"

        # Score display
        cursor_to $((height + 2)) 1
        printf "${BOLD}Score: ${BR_YELLOW}%d${RST}  ${TEXT_MUTED}High Score: %d${RST}  " "$score" "$highscore"
        printf "${TEXT_SECONDARY}[WASD/Arrows to move, Q to quit]${RST}"

        # Read input
        local key=$(read_key)
        case "$key" in
            w|W|$'\x1b[A') [[ "$direction" != "down" ]] && next_direction="up" ;;
            s|S|$'\x1b[B') [[ "$direction" != "up" ]] && next_direction="down" ;;
            a|A|$'\x1b[D') [[ "$direction" != "right" ]] && next_direction="left" ;;
            d|D|$'\x1b[C') [[ "$direction" != "left" ]] && next_direction="right" ;;
            q|Q) game_over=true; continue ;;
        esac

        direction="$next_direction"

        # Calculate new head position
        local new_x=${snake_x[0]}
        local new_y=${snake_y[0]}

        case "$direction" in
            up)    ((new_y--)) ;;
            down)  ((new_y++)) ;;
            left)  ((new_x--)) ;;
            right) ((new_x++)) ;;
        esac

        # Check wall collision
        if [[ $new_x -le 0 || $new_x -ge $width || $new_y -le 0 || $new_y -ge $height ]]; then
            game_over=true
            continue
        fi

        # Check self collision
        for ((i=0; i<${#snake_x[@]}; i++)); do
            if [[ ${snake_x[i]} -eq $new_x && ${snake_y[i]} -eq $new_y ]]; then
                game_over=true
                break
            fi
        done

        # Move snake
        # Clear tail
        cursor_to $((snake_y[-1] + 1)) $((snake_x[-1] + 1))
        printf " "

        # Shift body
        for ((i=${#snake_x[@]}-1; i>0; i--)); do
            snake_x[i]=${snake_x[i-1]}
            snake_y[i]=${snake_y[i-1]}
        done

        # New head
        snake_x[0]=$new_x
        snake_y[0]=$new_y

        # Check food collision
        if [[ $new_x -eq $food_x && $new_y -eq $food_y ]]; then
            ((score += 10))

            # Grow snake
            snake_x+=(${snake_x[-1]})
            snake_y+=(${snake_y[-1]})

            # New food
            food_x=$((RANDOM % (width - 2) + 1))
            food_y=$((RANDOM % (height - 2) + 1))

            # Speed up
            speed=$(echo "$speed - 0.002" | bc -l 2>/dev/null || echo "$speed")
            [[ $(echo "$speed < 0.03" | bc -l 2>/dev/null || echo 0) -eq 1 ]] && speed=0.03
        fi

        sleep "$speed"
    done

    # Game over
    cursor_to $((height / 2)) $((width / 2 - 5))
    printf "${BR_RED}${BOLD} GAME OVER ${RST}"

    cursor_to $((height / 2 + 1)) $((width / 2 - 7))
    printf "${BR_YELLOW}Final Score: %d${RST}" "$score"

    if [[ $score -gt $highscore ]]; then
        cursor_to $((height / 2 + 2)) $((width / 2 - 8))
        printf "${BR_GREEN}NEW HIGH SCORE!${RST}"
        save_highscore "snake" "$score" "Player"
    fi

    sleep 2
    cursor_show
}

#═══════════════════════════════════════════════════════════════════════════════
#  TETRIS GAME
#═══════════════════════════════════════════════════════════════════════════════

play_tetris() {
    local width=12
    local height=22
    local speed=0.5

    # Tetromino shapes (I, O, T, S, Z, J, L)
    declare -A SHAPES
    SHAPES[I]="0,0 1,0 2,0 3,0"
    SHAPES[O]="0,0 1,0 0,1 1,1"
    SHAPES[T]="0,0 1,0 2,0 1,1"
    SHAPES[S]="1,0 2,0 0,1 1,1"
    SHAPES[Z]="0,0 1,0 1,1 2,1"
    SHAPES[J]="0,0 0,1 1,1 2,1"
    SHAPES[L]="2,0 0,1 1,1 2,1"

    local SHAPE_CHARS=("I" "O" "T" "S" "Z" "J" "L")
    local SHAPE_COLORS=("$BR_CYAN" "$BR_YELLOW" "$BR_PURPLE" "$BR_GREEN" "$BR_RED" "$BR_BLUE" "$BR_ORANGE")

    # Game board
    declare -a board
    for ((i=0; i<height*width; i++)); do
        board[i]=0
    done

    # Current piece
    local current_shape=""
    local current_color=""
    local piece_x=0
    local piece_y=0
    local piece_blocks=""

    # Game state
    local score=0
    local lines=0
    local level=1
    local game_over=false
    local highscore=$(get_highscore "tetris")

    # Spawn new piece
    spawn_piece() {
        local idx=$((RANDOM % ${#SHAPE_CHARS[@]}))
        current_shape="${SHAPE_CHARS[idx]}"
        current_color="${SHAPE_COLORS[idx]}"
        piece_blocks="${SHAPES[$current_shape]}"
        piece_x=$((width / 2 - 1))
        piece_y=0
    }

    # Check collision
    check_collision() {
        local px="$1"
        local py="$2"
        local blocks="$3"

        for block in $blocks; do
            local bx=$((px + ${block%,*}))
            local by=$((py + ${block#*,}))

            if [[ $bx -lt 0 || $bx -ge $width || $by -ge $height ]]; then
                return 1
            fi

            if [[ $by -ge 0 && ${board[by*width+bx]} -ne 0 ]]; then
                return 1
            fi
        done
        return 0
    }

    # Lock piece
    lock_piece() {
        for block in $piece_blocks; do
            local bx=$((piece_x + ${block%,*}))
            local by=$((piece_y + ${block#*,}))

            if [[ $by -ge 0 ]]; then
                board[by*width+bx]=1
            fi
        done
    }

    # Clear lines
    clear_lines() {
        local cleared=0

        for ((y=height-1; y>=0; y--)); do
            local full=true
            for ((x=0; x<width; x++)); do
                if [[ ${board[y*width+x]} -eq 0 ]]; then
                    full=false
                    break
                fi
            done

            if [[ "$full" == "true" ]]; then
                ((cleared++))

                # Shift down
                for ((yy=y; yy>0; yy--)); do
                    for ((x=0; x<width; x++)); do
                        board[yy*width+x]=${board[(yy-1)*width+x]}
                    done
                done

                # Clear top row
                for ((x=0; x<width; x++)); do
                    board[x]=0
                done

                ((y++))  # Recheck this row
            fi
        done

        if [[ $cleared -gt 0 ]]; then
            ((lines += cleared))
            case $cleared in
                1) ((score += 100 * level)) ;;
                2) ((score += 300 * level)) ;;
                3) ((score += 500 * level)) ;;
                4) ((score += 800 * level)) ;;  # Tetris!
            esac
            level=$((lines / 10 + 1))
            speed=$(echo "0.5 - $level * 0.04" | bc -l 2>/dev/null || echo "0.5")
            [[ $(echo "$speed < 0.1" | bc -l 2>/dev/null || echo 0) -eq 1 ]] && speed=0.1
        fi
    }

    # Rotate piece
    rotate_piece() {
        local new_blocks=""
        for block in $piece_blocks; do
            local bx=${block%,*}
            local by=${block#*,}
            # Rotate 90 degrees clockwise
            local nx=$((1 - by))
            local ny=$bx
            new_blocks+="$nx,$ny "
        done

        if check_collision "$piece_x" "$piece_y" "$new_blocks"; then
            piece_blocks="$new_blocks"
        fi
    }

    # Draw game
    draw_game() {
        cursor_to 1 1

        # Border
        printf "${BR_CYAN}╔"
        for ((x=0; x<width; x++)); do printf "══"; done
        printf "╗${RST}\n"

        for ((y=0; y<height; y++)); do
            printf "${BR_CYAN}║${RST}"

            for ((x=0; x<width; x++)); do
                local is_piece=false

                # Check if current piece occupies this cell
                for block in $piece_blocks; do
                    local bx=$((piece_x + ${block%,*}))
                    local by=$((piece_y + ${block#*,}))
                    if [[ $bx -eq $x && $by -eq $y ]]; then
                        printf "${current_color}██${RST}"
                        is_piece=true
                        break
                    fi
                done

                if [[ "$is_piece" == "false" ]]; then
                    if [[ ${board[y*width+x]} -eq 1 ]]; then
                        printf "${TEXT_MUTED}▓▓${RST}"
                    else
                        printf "  "
                    fi
                fi
            done

            printf "${BR_CYAN}║${RST}"

            # Side panel
            case $y in
                1) printf "  ${BOLD}TETRIS${RST}" ;;
                3) printf "  Score: ${BR_YELLOW}%d${RST}" "$score" ;;
                4) printf "  Lines: ${BR_CYAN}%d${RST}" "$lines" ;;
                5) printf "  Level: ${BR_GREEN}%d${RST}" "$level" ;;
                7) printf "  High: ${TEXT_MUTED}%d${RST}" "$highscore" ;;
                10) printf "  ${TEXT_SECONDARY}Controls:${RST}" ;;
                11) printf "  ${TEXT_MUTED}← → Move${RST}" ;;
                12) printf "  ${TEXT_MUTED}↑ Rotate${RST}" ;;
                13) printf "  ${TEXT_MUTED}↓ Drop${RST}" ;;
                14) printf "  ${TEXT_MUTED}Space Hard${RST}" ;;
                15) printf "  ${TEXT_MUTED}Q Quit${RST}" ;;
            esac
            printf "\n"
        done

        printf "${BR_CYAN}╚"
        for ((x=0; x<width; x++)); do printf "══"; done
        printf "╝${RST}\n"
    }

    clear_screen
    cursor_hide
    spawn_piece

    local last_drop=$(date +%s.%N 2>/dev/null || date +%s)

    while [[ "$game_over" == "false" ]]; do
        draw_game

        # Read input
        local key=$(read_key)
        case "$key" in
            a|A|$'\x1b[D')
                check_collision $((piece_x - 1)) "$piece_y" "$piece_blocks" && ((piece_x--))
                ;;
            d|D|$'\x1b[C')
                check_collision $((piece_x + 1)) "$piece_y" "$piece_blocks" && ((piece_x++))
                ;;
            w|W|$'\x1b[A')
                rotate_piece
                ;;
            s|S|$'\x1b[B')
                if check_collision "$piece_x" $((piece_y + 1)) "$piece_blocks"; then
                    ((piece_y++))
                fi
                ;;
            " ")
                # Hard drop
                while check_collision "$piece_x" $((piece_y + 1)) "$piece_blocks"; do
                    ((piece_y++))
                    ((score += 2))
                done
                ;;
            q|Q)
                game_over=true
                continue
                ;;
        esac

        # Auto drop
        local now=$(date +%s.%N 2>/dev/null || date +%s)
        local elapsed=$(echo "$now - $last_drop" | bc -l 2>/dev/null || echo 1)

        if (( $(echo "$elapsed >= $speed" | bc -l 2>/dev/null || echo 1) )); then
            if check_collision "$piece_x" $((piece_y + 1)) "$piece_blocks"; then
                ((piece_y++))
            else
                lock_piece
                clear_lines

                spawn_piece
                if ! check_collision "$piece_x" "$piece_y" "$piece_blocks"; then
                    game_over=true
                fi
            fi
            last_drop="$now"
        fi

        sleep 0.05
    done

    # Game over
    cursor_to $((height / 2)) 5
    printf "${BR_RED}${BOLD}  GAME OVER  ${RST}"

    if [[ $score -gt $highscore ]]; then
        cursor_to $((height / 2 + 1)) 3
        printf "${BR_GREEN}NEW HIGH SCORE!${RST}"
        save_highscore "tetris" "$score" "Player"
    fi

    sleep 2
    cursor_show
}

#═══════════════════════════════════════════════════════════════════════════════
#  PONG GAME
#═══════════════════════════════════════════════════════════════════════════════

play_pong() {
    local width=60
    local height=20
    local paddle_size=4

    # Paddles
    local p1_y=$((height / 2 - paddle_size / 2))
    local p2_y=$((height / 2 - paddle_size / 2))

    # Ball
    local ball_x=$((width / 2))
    local ball_y=$((height / 2))
    local ball_dx=1
    local ball_dy=1

    # Scores
    local p1_score=0
    local p2_score=0
    local winning_score=5

    clear_screen
    cursor_hide

    while [[ $p1_score -lt $winning_score && $p2_score -lt $winning_score ]]; do
        # Draw
        cursor_to 1 1

        # Top border
        printf "${BR_CYAN}╔"
        printf "%0.s═" $(seq 1 $width)
        printf "╗${RST}\n"

        for ((y=0; y<height; y++)); do
            printf "${BR_CYAN}║${RST}"

            for ((x=0; x<width; x++)); do
                local char=" "

                # Left paddle
                if [[ $x -eq 1 ]]; then
                    if [[ $y -ge $p1_y && $y -lt $((p1_y + paddle_size)) ]]; then
                        char="${BR_GREEN}█${RST}"
                    fi
                fi

                # Right paddle
                if [[ $x -eq $((width - 2)) ]]; then
                    if [[ $y -ge $p2_y && $y -lt $((p2_y + paddle_size)) ]]; then
                        char="${BR_BLUE}█${RST}"
                    fi
                fi

                # Ball
                if [[ $x -eq $ball_x && $y -eq $ball_y ]]; then
                    char="${BR_YELLOW}●${RST}"
                fi

                # Center line
                if [[ $x -eq $((width / 2)) && $((y % 2)) -eq 0 ]]; then
                    char="${TEXT_MUTED}│${RST}"
                fi

                printf "%s" "$char"
            done

            printf "${BR_CYAN}║${RST}\n"
        done

        # Bottom border
        printf "${BR_CYAN}╚"
        printf "%0.s═" $(seq 1 $width)
        printf "╝${RST}\n"

        # Score
        printf "\n  ${BR_GREEN}Player 1: %d${RST}    ${BR_BLUE}Player 2 (AI): %d${RST}\n" "$p1_score" "$p2_score"
        printf "  ${TEXT_MUTED}[W/S to move, Q to quit]${RST}"

        # Input
        local key=$(read_key)
        case "$key" in
            w|W) [[ $p1_y -gt 0 ]] && ((p1_y--)) ;;
            s|S) [[ $p1_y -lt $((height - paddle_size)) ]] && ((p1_y++)) ;;
            q|Q) cursor_show; return ;;
        esac

        # AI movement
        local p2_center=$((p2_y + paddle_size / 2))
        if [[ $ball_y -lt $p2_center && $p2_y -gt 0 ]]; then
            ((p2_y--))
        elif [[ $ball_y -gt $p2_center && $p2_y -lt $((height - paddle_size)) ]]; then
            ((p2_y++))
        fi

        # Ball movement
        ((ball_x += ball_dx))
        ((ball_y += ball_dy))

        # Wall bounce
        if [[ $ball_y -le 0 || $ball_y -ge $((height - 1)) ]]; then
            ((ball_dy *= -1))
        fi

        # Paddle bounce
        if [[ $ball_x -eq 2 ]]; then
            if [[ $ball_y -ge $p1_y && $ball_y -lt $((p1_y + paddle_size)) ]]; then
                ((ball_dx *= -1))
            fi
        fi

        if [[ $ball_x -eq $((width - 3)) ]]; then
            if [[ $ball_y -ge $p2_y && $ball_y -lt $((p2_y + paddle_size)) ]]; then
                ((ball_dx *= -1))
            fi
        fi

        # Score
        if [[ $ball_x -le 0 ]]; then
            ((p2_score++))
            ball_x=$((width / 2))
            ball_y=$((height / 2))
            ball_dx=1
        fi

        if [[ $ball_x -ge $((width - 1)) ]]; then
            ((p1_score++))
            ball_x=$((width / 2))
            ball_y=$((height / 2))
            ball_dx=-1
        fi

        sleep 0.08
    done

    # Winner
    cursor_to $((height / 2)) $((width / 2 - 5))
    if [[ $p1_score -ge $winning_score ]]; then
        printf "${BR_GREEN}${BOLD}YOU WIN!${RST}"
    else
        printf "${BR_RED}${BOLD}AI WINS!${RST}"
    fi

    sleep 2
    cursor_show
}

#═══════════════════════════════════════════════════════════════════════════════
#  BREAKOUT GAME
#═══════════════════════════════════════════════════════════════════════════════

play_breakout() {
    local width=50
    local height=20
    local paddle_width=8

    # Paddle
    local paddle_x=$((width / 2 - paddle_width / 2))

    # Ball
    local ball_x=$((width / 2))
    local ball_y=$((height - 3))
    local ball_dx=1
    local ball_dy=-1

    # Bricks
    local brick_rows=4
    local brick_cols=10
    local brick_width=$((width / brick_cols))
    declare -a bricks
    for ((i=0; i<brick_rows*brick_cols; i++)); do
        bricks[i]=1
    done

    local score=0
    local lives=3
    local game_over=false

    clear_screen
    cursor_hide

    while [[ "$game_over" == "false" ]]; do
        cursor_to 1 1

        # Top border
        printf "${BR_CYAN}╔"
        printf "%0.s═" $(seq 1 $width)
        printf "╗${RST}\n"

        # Game area
        for ((y=0; y<height; y++)); do
            printf "${BR_CYAN}║${RST}"

            for ((x=0; x<width; x++)); do
                local char=" "

                # Bricks
                if [[ $y -lt $brick_rows ]]; then
                    local brick_col=$((x / brick_width))
                    local brick_idx=$((y * brick_cols + brick_col))

                    if [[ ${bricks[brick_idx]} -eq 1 ]]; then
                        local colors=("$BR_RED" "$BR_ORANGE" "$BR_YELLOW" "$BR_GREEN")
                        char="${colors[y]}█${RST}"
                    fi
                fi

                # Paddle
                if [[ $y -eq $((height - 1)) ]]; then
                    if [[ $x -ge $paddle_x && $x -lt $((paddle_x + paddle_width)) ]]; then
                        char="${BR_BLUE}█${RST}"
                    fi
                fi

                # Ball
                if [[ $x -eq $ball_x && $y -eq $ball_y ]]; then
                    char="${BR_WHITE}●${RST}"
                fi

                printf "%s" "$char"
            done

            printf "${BR_CYAN}║${RST}\n"
        done

        printf "${BR_CYAN}╚"
        printf "%0.s═" $(seq 1 $width)
        printf "╝${RST}\n"

        printf "  ${BOLD}Score: ${BR_YELLOW}%d${RST}  Lives: ${BR_RED}%s${RST}\n" "$score" "$(printf '♥%.0s' $(seq 1 $lives))"

        # Input
        local key=$(read_key)
        case "$key" in
            a|A|$'\x1b[D')
                [[ $paddle_x -gt 0 ]] && ((paddle_x -= 2))
                ;;
            d|D|$'\x1b[C')
                [[ $paddle_x -lt $((width - paddle_width)) ]] && ((paddle_x += 2))
                ;;
            q|Q)
                game_over=true
                continue
                ;;
        esac

        # Ball movement
        ((ball_x += ball_dx))
        ((ball_y += ball_dy))

        # Wall bounce
        if [[ $ball_x -le 0 || $ball_x -ge $((width - 1)) ]]; then
            ((ball_dx *= -1))
        fi

        if [[ $ball_y -le 0 ]]; then
            ((ball_dy *= -1))
        fi

        # Paddle bounce
        if [[ $ball_y -eq $((height - 2)) ]]; then
            if [[ $ball_x -ge $paddle_x && $ball_x -lt $((paddle_x + paddle_width)) ]]; then
                ((ball_dy *= -1))
            fi
        fi

        # Miss
        if [[ $ball_y -ge $height ]]; then
            ((lives--))
            if [[ $lives -le 0 ]]; then
                game_over=true
            else
                ball_x=$((width / 2))
                ball_y=$((height - 3))
                ball_dy=-1
            fi
        fi

        # Brick collision
        if [[ $ball_y -lt $brick_rows ]]; then
            local brick_col=$((ball_x / brick_width))
            local brick_idx=$((ball_y * brick_cols + brick_col))

            if [[ ${bricks[brick_idx]} -eq 1 ]]; then
                bricks[brick_idx]=0
                ((ball_dy *= -1))
                ((score += 10))
            fi
        fi

        # Check win
        local remaining=0
        for b in "${bricks[@]}"; do
            ((remaining += b))
        done

        if [[ $remaining -eq 0 ]]; then
            cursor_to $((height / 2)) $((width / 2 - 4))
            printf "${BR_GREEN}${BOLD}YOU WIN!${RST}"
            save_highscore "breakout" "$score" "Player"
            sleep 2
            game_over=true
        fi

        sleep 0.06
    done

    if [[ $lives -le 0 ]]; then
        cursor_to $((height / 2)) $((width / 2 - 5))
        printf "${BR_RED}${BOLD}GAME OVER${RST}"
        sleep 2
    fi

    cursor_show
}

#═══════════════════════════════════════════════════════════════════════════════
#  GAME MENU
#═══════════════════════════════════════════════════════════════════════════════

game_menu() {
    clear_screen
    cursor_hide

    while true; do
        cursor_to 1 1

        printf "${BR_PURPLE}${BOLD}"
        printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
        printf "║                       🎮 BLACKROAD TERMINAL GAMES                            ║\n"
        printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
        printf "${RST}\n\n"

        printf "  ${BR_GREEN}1.${RST} ${BOLD}Snake${RST}         - Classic snake game\n"
        printf "  ${BR_CYAN}2.${RST} ${BOLD}Tetris${RST}        - Block stacking puzzle\n"
        printf "  ${BR_YELLOW}3.${RST} ${BOLD}Pong${RST}          - Classic paddle game vs AI\n"
        printf "  ${BR_RED}4.${RST} ${BOLD}Breakout${RST}      - Brick breaking action\n"
        printf "\n"
        printf "  ${BR_PURPLE}H.${RST} ${TEXT_SECONDARY}High Scores${RST}\n"
        printf "  ${TEXT_MUTED}Q.${RST} ${TEXT_MUTED}Quit${RST}\n"
        printf "\n"
        printf "  ${TEXT_SECONDARY}Select a game (1-4):${RST} "

        read -rsn1 choice

        case "$choice" in
            1) play_snake ;;
            2) play_tetris ;;
            3) play_pong ;;
            4) play_breakout ;;
            h|H)
                clear_screen
                printf "\n"
                show_highscores "snake"
                printf "\n"
                show_highscores "tetris"
                printf "\n"
                show_highscores "breakout"
                printf "\n${TEXT_MUTED}Press any key...${RST}"
                read -rsn1
                ;;
            q|Q) break ;;
        esac

        clear_screen
    done

    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-menu}" in
        menu)     game_menu ;;
        snake)    play_snake ;;
        tetris)   play_tetris ;;
        pong)     play_pong ;;
        breakout) play_breakout ;;
        scores)   show_highscores "${2:-snake}" ;;
        *)
            printf "Usage: %s [menu|snake|tetris|pong|breakout|scores]\n" "$0"
            ;;
    esac
fi
