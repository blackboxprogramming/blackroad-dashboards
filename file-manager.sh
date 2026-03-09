#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ███████╗██╗██╗     ███████╗███████╗
#  ██╔════╝██║██║     ██╔════╝██╔════╝
#  █████╗  ██║██║     █████╗  ███████╗
#  ██╔══╝  ██║██║     ██╔══╝  ╚════██║
#  ██║     ██║███████╗███████╗███████║
#  ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD FILE MANAGER v3.0
#  Terminal File Browser with Preview & Operations
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

CURRENT_DIR="$(pwd)"
SELECTED_IDX=0
SCROLL_OFFSET=0
MAX_DISPLAY=20
SHOW_HIDDEN=false
SORT_BY="name"
CLIPBOARD=""
CLIPBOARD_OP=""
PREVIEW_WIDTH=40

#───────────────────────────────────────────────────────────────────────────────
# FILE LISTING
#───────────────────────────────────────────────────────────────────────────────

get_files() {
    local dir="$1"
    local hidden_flag=""
    [[ "$SHOW_HIDDEN" == "true" ]] && hidden_flag="-A"

    local sort_flag="-v"
    case "$SORT_BY" in
        size) sort_flag="-S" ;;
        time) sort_flag="-t" ;;
        type) sort_flag="-X" ;;
    esac

    ls -1 $hidden_flag $sort_flag "$dir" 2>/dev/null
}

get_file_info() {
    local file="$1"

    if [[ -d "$file" ]]; then
        echo "dir|$(ls -1 "$file" 2>/dev/null | wc -l) items"
    elif [[ -L "$file" ]]; then
        echo "link|$(readlink "$file")"
    elif [[ -x "$file" ]]; then
        echo "exec|$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null)"
    else
        local size=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null || echo "0")
        local ext="${file##*.}"
        echo "file|$size|$ext"
    fi
}

format_size() {
    local bytes="$1"

    if [[ $bytes -ge 1073741824 ]]; then
        printf "%.1fG" "$(echo "$bytes / 1073741824" | bc -l)"
    elif [[ $bytes -ge 1048576 ]]; then
        printf "%.1fM" "$(echo "$bytes / 1048576" | bc -l)"
    elif [[ $bytes -ge 1024 ]]; then
        printf "%.1fK" "$(echo "$bytes / 1024" | bc -l)"
    else
        printf "%dB" "$bytes"
    fi
}

get_file_icon() {
    local file="$1"
    local ext="${file##*.}"

    if [[ -d "$file" ]]; then
        echo "📁"
    elif [[ -L "$file" ]]; then
        echo "🔗"
    elif [[ -x "$file" ]]; then
        echo "⚡"
    else
        case "${ext,,}" in
            sh|bash|zsh)    echo "📜" ;;
            py)             echo "🐍" ;;
            js|ts)          echo "📦" ;;
            json)           echo "📋" ;;
            md|txt)         echo "📄" ;;
            jpg|jpeg|png|gif) echo "🖼️" ;;
            mp3|wav|flac)   echo "🎵" ;;
            mp4|mkv|avi)    echo "🎬" ;;
            zip|tar|gz)     echo "📦" ;;
            pdf)            echo "📕" ;;
            html|css)       echo "🌐" ;;
            *)              echo "📄" ;;
        esac
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# PREVIEW
#───────────────────────────────────────────────────────────────────────────────

preview_file() {
    local file="$1"
    local height="${2:-15}"
    local width="${3:-40}"

    if [[ -d "$file" ]]; then
        printf "\033[1mDirectory Contents:\033[0m\n"
        ls -la "$file" 2>/dev/null | head -n "$height"
    elif [[ -f "$file" ]]; then
        local mime=$(file -b --mime-type "$file" 2>/dev/null)

        case "$mime" in
            text/*|application/json|application/javascript)
                head -n "$height" "$file" 2>/dev/null | cut -c1-"$width"
                ;;
            image/*)
                printf "\033[38;5;240mImage: %s\033[0m\n" "$(file -b "$file")"
                ;;
            *)
                printf "\033[38;5;240mBinary: %s\033[0m\n" "$mime"
                file -b "$file"
                ;;
        esac
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# FILE OPERATIONS
#───────────────────────────────────────────────────────────────────────────────

copy_file() {
    CLIPBOARD="$1"
    CLIPBOARD_OP="copy"
}

cut_file() {
    CLIPBOARD="$1"
    CLIPBOARD_OP="cut"
}

paste_file() {
    local dest="$1"

    [[ -z "$CLIPBOARD" ]] && return

    if [[ "$CLIPBOARD_OP" == "copy" ]]; then
        cp -r "$CLIPBOARD" "$dest/"
    elif [[ "$CLIPBOARD_OP" == "cut" ]]; then
        mv "$CLIPBOARD" "$dest/"
        CLIPBOARD=""
        CLIPBOARD_OP=""
    fi
}

delete_file() {
    local file="$1"
    rm -rf "$file"
}

rename_file() {
    local old="$1"
    local new="$2"
    mv "$old" "$new"
}

create_dir() {
    local name="$1"
    mkdir -p "$name"
}

create_file() {
    local name="$1"
    touch "$name"
}

#───────────────────────────────────────────────────────────────────────────────
# RENDERING
#───────────────────────────────────────────────────────────────────────────────

render_header() {
    printf "\033[1;38;5;214m"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                        📂 BLACKROAD FILE MANAGER                             ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "\033[0m"

    printf "\n  \033[38;5;51m%s\033[0m\n" "$CURRENT_DIR"
    printf "  \033[38;5;240mSort: %s  Hidden: %s\033[0m\n\n" "$SORT_BY" "$SHOW_HIDDEN"
}

render_file_list() {
    local -a files
    mapfile -t files < <(get_files "$CURRENT_DIR")

    local total=${#files[@]}

    # Add parent directory
    [[ "$CURRENT_DIR" != "/" ]] && files=(".." "${files[@]}")

    total=${#files[@]}

    # Adjust selection
    [[ $SELECTED_IDX -lt 0 ]] && SELECTED_IDX=0
    [[ $SELECTED_IDX -ge $total ]] && SELECTED_IDX=$((total - 1))
    [[ $SELECTED_IDX -lt $SCROLL_OFFSET ]] && SCROLL_OFFSET=$SELECTED_IDX
    [[ $SELECTED_IDX -ge $((SCROLL_OFFSET + MAX_DISPLAY)) ]] && SCROLL_OFFSET=$((SELECTED_IDX - MAX_DISPLAY + 1))

    local list_width=$((80 - PREVIEW_WIDTH - 5))

    # Two-column layout
    printf "\033[38;5;240m┌"
    printf "%0.s─" $(seq 1 $list_width)
    printf "┬"
    printf "%0.s─" $(seq 1 $PREVIEW_WIDTH)
    printf "┐\033[0m\n"

    local selected_file=""

    for ((i=0; i<MAX_DISPLAY; i++)); do
        local idx=$((SCROLL_OFFSET + i))
        local file=""
        local file_display=""

        if [[ $idx -lt $total ]]; then
            file="${files[$idx]}"
            local full_path="$CURRENT_DIR/$file"
            [[ "$file" == ".." ]] && full_path="$(dirname "$CURRENT_DIR")"

            local icon=$(get_file_icon "$full_path")
            local info=$(get_file_info "$full_path")
            IFS='|' read -r type size ext <<< "$info"

            local name_display="${file:0:$((list_width - 15))}"
            local size_display=""

            if [[ "$type" == "dir" ]]; then
                size_display="$size"
            elif [[ -n "$size" ]]; then
                size_display=$(format_size "$size")
            fi

            if [[ $idx -eq $SELECTED_IDX ]]; then
                selected_file="$full_path"
                printf "\033[38;5;240m│\033[0m\033[48;5;236m\033[38;5;51m▶\033[0m\033[48;5;236m"
                printf " %s \033[1m%-$((list_width - 12))s\033[0m\033[48;5;236m %8s " "$icon" "$name_display" "$size_display"
                printf "\033[0m"
            else
                printf "\033[38;5;240m│\033[0m  "

                if [[ "$type" == "dir" ]]; then
                    printf "%s \033[38;5;39m%-$((list_width - 12))s\033[0m %8s " "$icon" "$name_display" "$size_display"
                elif [[ "$type" == "exec" ]]; then
                    printf "%s \033[38;5;46m%-$((list_width - 12))s\033[0m %8s " "$icon" "$name_display" "$size_display"
                else
                    printf "%s %-$((list_width - 12))s %8s " "$icon" "$name_display" "$size_display"
                fi
            fi
        else
            printf "\033[38;5;240m│\033[0m%${list_width}s" ""
        fi

        printf "\033[38;5;240m│\033[0m"

        # Preview column
        if [[ $i -eq 0 && -n "$selected_file" ]]; then
            printf "\033[1m Preview:\033[0m"
        elif [[ -n "$selected_file" ]]; then
            local preview_line=$(preview_file "$selected_file" 20 "$PREVIEW_WIDTH" | sed -n "$((i))p")
            printf " %-$((PREVIEW_WIDTH - 2))s" "${preview_line:0:$((PREVIEW_WIDTH - 2))}"
        else
            printf "%${PREVIEW_WIDTH}s" ""
        fi

        printf "\033[38;5;240m│\033[0m\n"
    done

    printf "\033[38;5;240m└"
    printf "%0.s─" $(seq 1 $list_width)
    printf "┴"
    printf "%0.s─" $(seq 1 $PREVIEW_WIDTH)
    printf "┘\033[0m\n"

    # Status bar
    printf "\n  \033[38;5;240m%d/%d items\033[0m" "$((SELECTED_IDX + 1))" "$total"
    [[ -n "$CLIPBOARD" ]] && printf "  \033[38;5;226m[Clipboard: %s]\033[0m" "$(basename "$CLIPBOARD")"
    printf "\n"
}

render_controls() {
    printf "\n\033[38;5;240m───────────────────────────────────────────────────────────────────────────────\033[0m\n"
    printf "  \033[38;5;39m↑↓\033[0m Navigate  "
    printf "\033[38;5;46mEnter\033[0m Open  "
    printf "\033[38;5;226mc\033[0m Copy  "
    printf "\033[38;5;208mv\033[0m Paste  "
    printf "\033[38;5;196md\033[0m Delete  "
    printf "\033[38;5;201mr\033[0m Rename  "
    printf "\033[38;5;240mq\033[0m Quit\n"
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN LOOP
#───────────────────────────────────────────────────────────────────────────────

file_manager_loop() {
    clear
    tput civis

    trap 'tput cnorm; clear; exit 0' INT TERM

    while true; do
        tput cup 0 0

        render_header
        render_file_list
        render_controls

        # Get selected file
        local -a files
        mapfile -t files < <(get_files "$CURRENT_DIR")
        [[ "$CURRENT_DIR" != "/" ]] && files=(".." "${files[@]}")

        local selected="${files[$SELECTED_IDX]}"
        local full_path="$CURRENT_DIR/$selected"
        [[ "$selected" == ".." ]] && full_path="$(dirname "$CURRENT_DIR")"

        # Handle input
        read -rsn1 key

        case "$key" in
            $'\x1b')
                read -rsn2 key2
                case "$key2" in
                    '[A') ((SELECTED_IDX--)) ;;  # Up
                    '[B') ((SELECTED_IDX++)) ;;  # Down
                    '[5') ((SELECTED_IDX -= MAX_DISPLAY)) ;;  # PgUp
                    '[6') ((SELECTED_IDX += MAX_DISPLAY)) ;;  # PgDn
                    '[H') SELECTED_IDX=0 ;;  # Home
                    '[F') SELECTED_IDX=$((${#files[@]} - 1)) ;;  # End
                esac
                ;;
            '')  # Enter
                if [[ -d "$full_path" ]]; then
                    CURRENT_DIR="$full_path"
                    SELECTED_IDX=0
                    SCROLL_OFFSET=0
                    clear
                elif [[ -f "$full_path" ]]; then
                    # Open file
                    tput cnorm
                    if command -v less &>/dev/null; then
                        less "$full_path"
                    else
                        cat "$full_path" | head -50
                        read -rsn1
                    fi
                    tput civis
                    clear
                fi
                ;;
            h|H)
                [[ "$SHOW_HIDDEN" == "true" ]] && SHOW_HIDDEN=false || SHOW_HIDDEN=true
                SELECTED_IDX=0
                SCROLL_OFFSET=0
                ;;
            s|S)
                case "$SORT_BY" in
                    name) SORT_BY="size" ;;
                    size) SORT_BY="time" ;;
                    time) SORT_BY="type" ;;
                    *) SORT_BY="name" ;;
                esac
                SELECTED_IDX=0
                ;;
            c|C)
                copy_file "$full_path"
                ;;
            x|X)
                cut_file "$full_path"
                ;;
            v|V)
                paste_file "$CURRENT_DIR"
                ;;
            d|D)
                tput cnorm
                printf "\n  Delete '%s'? (y/n): " "$selected"
                read -rsn1 confirm
                [[ "$confirm" == "y" ]] && delete_file "$full_path"
                tput civis
                clear
                ;;
            r|R)
                tput cnorm
                printf "\n  New name: "
                read -r new_name
                [[ -n "$new_name" ]] && rename_file "$full_path" "$CURRENT_DIR/$new_name"
                tput civis
                clear
                ;;
            n|N)
                tput cnorm
                printf "\n  Create (f)ile or (d)irectory? "
                read -rsn1 type
                printf "\n  Name: "
                read -r name
                if [[ "$type" == "d" ]]; then
                    create_dir "$CURRENT_DIR/$name"
                else
                    create_file "$CURRENT_DIR/$name"
                fi
                tput civis
                clear
                ;;
            /)
                tput cnorm
                printf "\n  Search: "
                read -r pattern
                # Jump to match
                for ((i=0; i<${#files[@]}; i++)); do
                    if [[ "${files[$i]}" == *"$pattern"* ]]; then
                        SELECTED_IDX=$i
                        break
                    fi
                done
                tput civis
                ;;
            q|Q)
                tput cnorm
                clear
                exit 0
                ;;
        esac
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    CURRENT_DIR="${1:-$(pwd)}"
    file_manager_loop
fi
