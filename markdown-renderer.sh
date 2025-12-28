#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ███╗   ███╗ █████╗ ██████╗ ██╗  ██╗██████╗  ██████╗ ██╗    ██╗███╗   ██╗
#  ████╗ ████║██╔══██╗██╔══██╗██║ ██╔╝██╔══██╗██╔═══██╗██║    ██║████╗  ██║
#  ██╔████╔██║███████║██████╔╝█████╔╝ ██║  ██║██║   ██║██║ █╗ ██║██╔██╗ ██║
#  ██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗ ██║  ██║██║   ██║██║███╗██║██║╚██╗██║
#  ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██╗██████╔╝╚██████╔╝╚███╔███╔╝██║ ╚████║
#  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD MARKDOWN RENDERER v1.0
#  Terminal Markdown Viewer with Syntax Highlighting
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# COLOR DEFINITIONS
#───────────────────────────────────────────────────────────────────────────────

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_ITALIC="\033[3m"
C_UNDERLINE="\033[4m"
C_STRIKE="\033[9m"

C_H1="\033[1;38;5;214m"
C_H2="\033[1;38;5;39m"
C_H3="\033[1;38;5;46m"
C_H4="\033[1;38;5;201m"
C_H5="\033[1;38;5;226m"
C_H6="\033[1;38;5;244m"

C_CODE="\033[48;5;236m\033[38;5;208m"
C_CODE_BLOCK="\033[48;5;235m"
C_LINK="\033[38;5;39m"
C_LINK_URL="\033[38;5;244m"
C_QUOTE="\033[38;5;244m"
C_LIST="\033[38;5;46m"
C_HR="\033[38;5;240m"
C_TABLE="\033[38;5;240m"
C_IMAGE="\033[38;5;201m"

#───────────────────────────────────────────────────────────────────────────────
# SYNTAX HIGHLIGHTING FOR CODE BLOCKS
#───────────────────────────────────────────────────────────────────────────────

declare -A SYNTAX_KEYWORDS=(
    [bash]="if then else elif fi case esac for while do done function return local export source"
    [python]="def class if elif else for while try except finally with as import from return yield lambda"
    [javascript]="function const let var if else for while switch case break continue return class import export async await"
    [go]="func package import type struct interface if else for switch case return defer go chan"
    [rust]="fn let mut if else for while loop match return struct enum impl trait use mod pub"
)

declare -A SYNTAX_TYPES=(
    [bash]="string int array"
    [python]="str int float list dict tuple set bool None True False"
    [javascript]="string number boolean null undefined Array Object"
    [go]="int string bool byte rune error nil true false"
    [rust]="i32 i64 u32 u64 f32 f64 bool String str Vec Option Result"
)

highlight_code() {
    local code="$1"
    local lang="$2"

    # Keywords
    local keywords="${SYNTAX_KEYWORDS[$lang]}"
    for kw in $keywords; do
        code=$(echo "$code" | sed "s/\b${kw}\b/\\\\033[38;5;201m${kw}\\\\033[38;5;252m/g")
    done

    # Types
    local types="${SYNTAX_TYPES[$lang]}"
    for tp in $types; do
        code=$(echo "$code" | sed "s/\b${tp}\b/\\\\033[38;5;39m${tp}\\\\033[38;5;252m/g")
    done

    # Strings
    code=$(echo "$code" | sed 's/"\([^"]*\)"/\\033[38;5;226m"\1"\\033[38;5;252m/g')
    code=$(echo "$code" | sed "s/'\([^']*\)'/\\033[38;5;226m'\1'\\033[38;5;252m/g")

    # Numbers
    code=$(echo "$code" | sed 's/\b\([0-9]\+\)\b/\\033[38;5;208m\1\\033[38;5;252m/g')

    # Comments
    code=$(echo "$code" | sed 's/#\(.*\)$/\\033[38;5;240m#\1\\033[38;5;252m/g')
    code=$(echo "$code" | sed 's|//\(.*\)$|\\033[38;5;240m//\1\\033[38;5;252m|g')

    echo "$code"
}

#───────────────────────────────────────────────────────────────────────────────
# MARKDOWN PARSING
#───────────────────────────────────────────────────────────────────────────────

render_line() {
    local line="$1"
    local width="${2:-80}"
    local in_code="$3"
    local code_lang="$4"

    # Inside code block
    if [[ "$in_code" == "true" ]]; then
        local highlighted=$(highlight_code "$line" "$code_lang")
        printf "${C_CODE_BLOCK}  \033[38;5;252m%-$((width-4))s  ${C_RESET}\n" "$line"
        return
    fi

    # Headers
    if [[ "$line" =~ ^######[[:space:]](.+)$ ]]; then
        printf "\n${C_H6}      ${BASH_REMATCH[1]}${C_RESET}\n"
        return
    elif [[ "$line" =~ ^#####[[:space:]](.+)$ ]]; then
        printf "\n${C_H5}     ${BASH_REMATCH[1]}${C_RESET}\n"
        return
    elif [[ "$line" =~ ^####[[:space:]](.+)$ ]]; then
        printf "\n${C_H4}    ${BASH_REMATCH[1]}${C_RESET}\n"
        return
    elif [[ "$line" =~ ^###[[:space:]](.+)$ ]]; then
        printf "\n${C_H3}   ${BASH_REMATCH[1]}${C_RESET}\n"
        return
    elif [[ "$line" =~ ^##[[:space:]](.+)$ ]]; then
        printf "\n${C_H2}  ══ ${BASH_REMATCH[1]} ══${C_RESET}\n"
        return
    elif [[ "$line" =~ ^#[[:space:]](.+)$ ]]; then
        local header="${BASH_REMATCH[1]}"
        printf "\n${C_H1}╔"
        printf '═%.0s' $(seq 1 $((width-2)))
        printf "╗${C_RESET}\n"
        printf "${C_H1}║ %-$((width-4))s ║${C_RESET}\n" "$header"
        printf "${C_H1}╚"
        printf '═%.0s' $(seq 1 $((width-2)))
        printf "╝${C_RESET}\n"
        return
    fi

    # Horizontal rule
    if [[ "$line" =~ ^[-*_]{3,}$ ]]; then
        printf "${C_HR}"
        printf '─%.0s' $(seq 1 $width)
        printf "${C_RESET}\n"
        return
    fi

    # Blockquote
    if [[ "$line" =~ ^\>[[:space:]]?(.*)$ ]]; then
        local quote="${BASH_REMATCH[1]}"
        printf "${C_QUOTE}  ┃ ${C_ITALIC}%s${C_RESET}\n" "$quote"
        return
    fi

    # Unordered list
    if [[ "$line" =~ ^[[:space:]]*[-*+][[:space:]](.+)$ ]]; then
        local indent=$(echo "$line" | sed 's/[-*+].*//' | wc -c)
        local item="${BASH_REMATCH[1]}"
        item=$(render_inline "$item")
        printf "%*s${C_LIST}●${C_RESET} %b\n" "$indent" "" "$item"
        return
    fi

    # Ordered list
    if [[ "$line" =~ ^[[:space:]]*([0-9]+)\.[[:space:]](.+)$ ]]; then
        local num="${BASH_REMATCH[1]}"
        local item="${BASH_REMATCH[2]}"
        item=$(render_inline "$item")
        printf "  ${C_LIST}%s.${C_RESET} %b\n" "$num" "$item"
        return
    fi

    # Checkbox
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[([xX\ ])\][[:space:]](.+)$ ]]; then
        local checked="${BASH_REMATCH[1]}"
        local item="${BASH_REMATCH[2]}"
        if [[ "$checked" =~ [xX] ]]; then
            printf "  ${C_LIST}☑${C_RESET} ${C_DIM}${C_STRIKE}%s${C_RESET}\n" "$item"
        else
            printf "  ${C_LIST}☐${C_RESET} %s\n" "$item"
        fi
        return
    fi

    # Empty line
    if [[ -z "$line" ]]; then
        printf "\n"
        return
    fi

    # Regular paragraph
    local rendered=$(render_inline "$line")
    printf "  %b\n" "$rendered"
}

render_inline() {
    local text="$1"

    # Images ![alt](url)
    text=$(echo "$text" | sed -E "s/!\[([^]]*)\]\(([^)]+)\)/${C_IMAGE}[IMAGE: \1]${C_RESET}/g")

    # Links [text](url)
    text=$(echo "$text" | sed -E "s/\[([^]]+)\]\(([^)]+)\)/${C_LINK}\1${C_RESET} ${C_LINK_URL}(\2)${C_RESET}/g")

    # Bold **text** or __text__
    text=$(echo "$text" | sed -E "s/\*\*([^*]+)\*\*/${C_BOLD}\1${C_RESET}/g")
    text=$(echo "$text" | sed -E "s/__([^_]+)__/${C_BOLD}\1${C_RESET}/g")

    # Italic *text* or _text_
    text=$(echo "$text" | sed -E "s/\*([^*]+)\*/${C_ITALIC}\1${C_RESET}/g")
    text=$(echo "$text" | sed -E "s/(?<![a-zA-Z])_([^_]+)_(?![a-zA-Z])/${C_ITALIC}\1${C_RESET}/g")

    # Strikethrough ~~text~~
    text=$(echo "$text" | sed -E "s/~~([^~]+)~~/${C_STRIKE}\1${C_RESET}/g")

    # Inline code `code`
    text=$(echo "$text" | sed -E "s/\`([^\`]+)\`/${C_CODE} \1 ${C_RESET}/g")

    echo -e "$text"
}

#───────────────────────────────────────────────────────────────────────────────
# TABLE RENDERING
#───────────────────────────────────────────────────────────────────────────────

render_table() {
    local -a rows=("$@")
    local -a widths=()
    local num_cols=0

    # Calculate column widths
    for row in "${rows[@]}"; do
        IFS='|' read -ra cells <<< "$row"
        local col=0
        for cell in "${cells[@]}"; do
            cell=$(echo "$cell" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [[ -z "$cell" ]] && continue
            local len=${#cell}
            [[ ${widths[$col]:-0} -lt $len ]] && widths[$col]=$len
            ((col++))
        done
        [[ $col -gt $num_cols ]] && num_cols=$col
    done

    # Render table
    local is_header=true
    local is_separator=false

    for row in "${rows[@]}"; do
        # Check if separator row
        if [[ "$row" =~ ^[[:space:]]*\|?[-:|[:space:]]+\|?[[:space:]]*$ ]]; then
            printf "${C_TABLE}├"
            for ((i=0; i<num_cols; i++)); do
                printf '─%.0s' $(seq 1 $((${widths[$i]:-10}+2)))
                [[ $i -lt $((num_cols-1)) ]] && printf "┼"
            done
            printf "┤${C_RESET}\n"
            is_header=false
            continue
        fi

        IFS='|' read -ra cells <<< "$row"
        printf "${C_TABLE}│${C_RESET}"

        local col=0
        for cell in "${cells[@]}"; do
            cell=$(echo "$cell" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [[ -z "$cell" ]] && continue

            local w=${widths[$col]:-10}
            if $is_header; then
                printf " ${C_BOLD}%-${w}s${C_RESET} ${C_TABLE}│${C_RESET}" "$cell"
            else
                printf " %-${w}s ${C_TABLE}│${C_RESET}" "$cell"
            fi
            ((col++))
        done
        printf "\n"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# FILE PROCESSING
#───────────────────────────────────────────────────────────────────────────────

render_markdown() {
    local file="$1"
    local width="${2:-80}"

    local in_code=false
    local code_lang=""
    local -a table_rows=()
    local in_table=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Code block start/end
        if [[ "$line" =~ ^\`\`\`(.*)$ ]]; then
            if [[ "$in_code" == "false" ]]; then
                in_code=true
                code_lang="${BASH_REMATCH[1]}"
                printf "\n${C_CODE_BLOCK}  ┌"
                printf '─%.0s' $(seq 1 $((width-6)))
                printf "┐  ${C_RESET}\n"
                [[ -n "$code_lang" ]] && printf "${C_CODE_BLOCK}  │ ${C_DIM}%s${C_RESET}${C_CODE_BLOCK}%*s│  ${C_RESET}\n" "$code_lang" "$((width-8-${#code_lang}))" ""
            else
                printf "${C_CODE_BLOCK}  └"
                printf '─%.0s' $(seq 1 $((width-6)))
                printf "┘  ${C_RESET}\n\n"
                in_code=false
                code_lang=""
            fi
            continue
        fi

        # Table detection
        if [[ "$line" =~ ^\|.*\|$ ]]; then
            if [[ "$in_table" == "false" ]]; then
                in_table=true
                table_rows=()
                printf "\n"
            fi
            table_rows+=("$line")
            continue
        elif [[ "$in_table" == "true" ]]; then
            render_table "${table_rows[@]}"
            in_table=false
            table_rows=()
            printf "\n"
        fi

        render_line "$line" "$width" "$in_code" "$code_lang"
    done < "$file"

    # Close table if still open
    if [[ "$in_table" == "true" ]]; then
        render_table "${table_rows[@]}"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# INTERACTIVE VIEWER
#───────────────────────────────────────────────────────────────────────────────

interactive_viewer() {
    local file="$1"
    local scroll=0
    local lines=()
    local term_height=$(tput lines)
    local term_width=$(tput cols)

    # Pre-render markdown
    while IFS= read -r line; do
        lines+=("$line")
    done < <(render_markdown "$file" "$((term_width - 4))")

    local total=${#lines[@]}

    tput civis
    trap 'tput cnorm; clear; exit 0' INT TERM

    while true; do
        clear

        # Header
        printf "\033[1;38;5;214m"
        printf "╔"
        printf '═%.0s' $(seq 1 $((term_width-2)))
        printf "╗\n"
        printf "║  📖 MARKDOWN VIEWER: %-$((term_width-28))s ║\n" "$(basename "$file")"
        printf "╚"
        printf '═%.0s' $(seq 1 $((term_width-2)))
        printf "╝\033[0m\n\n"

        # Content
        local display_lines=$((term_height - 8))
        for ((i=scroll; i<scroll+display_lines && i<total; i++)); do
            echo -e "${lines[$i]}"
        done

        # Footer
        tput cup $((term_height - 2)) 0
        printf "\033[38;5;240m"
        printf '─%.0s' $(seq 1 $term_width)
        printf "\033[0m\n"
        printf "  \033[38;5;39m↑↓\033[0m Scroll  \033[38;5;46mPgUp/PgDn\033[0m Page  \033[38;5;226mHome/End\033[0m Jump  \033[38;5;240mq\033[0m Quit"
        printf "  \033[38;5;240m[%d/%d]\033[0m" "$((scroll + 1))" "$total"

        # Input
        read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 key2
                case "$key2" in
                    '[A') ((scroll > 0)) && ((scroll--)) ;;
                    '[B') ((scroll < total - display_lines)) && ((scroll++)) ;;
                    '[5') scroll=$((scroll - display_lines)); ((scroll < 0)) && scroll=0 ;;
                    '[6') scroll=$((scroll + display_lines)); ((scroll > total - display_lines)) && scroll=$((total - display_lines)) ;;
                    '[H') scroll=0 ;;
                    '[F') scroll=$((total - display_lines)) ;;
                esac
                ;;
            q|Q)
                tput cnorm
                clear
                exit 0
                ;;
        esac

        # Bounds check
        ((scroll < 0)) && scroll=0
        ((scroll > total - display_lines)) && scroll=$((total - display_lines))
        ((scroll < 0)) && scroll=0
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

show_help() {
    cat << 'EOF'

  BLACKROAD MARKDOWN RENDERER
  ═══════════════════════════

  Usage: markdown-renderer.sh [options] <file.md>

  Options:
    -i, --interactive    Open in interactive viewer
    -w, --width <n>      Set output width (default: 80)
    -h, --help           Show this help

  Features:
    • Headers (h1-h6) with styling
    • Bold, italic, strikethrough
    • Inline code and code blocks
    • Syntax highlighting for code
    • Links and images
    • Ordered and unordered lists
    • Checkboxes
    • Blockquotes
    • Tables
    • Horizontal rules

  Examples:
    markdown-renderer.sh README.md
    markdown-renderer.sh -i README.md
    markdown-renderer.sh -w 120 docs/guide.md

EOF
}

main() {
    local file=""
    local interactive=false
    local width=80

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--interactive) interactive=true; shift ;;
            -w|--width) width="$2"; shift 2 ;;
            -h|--help) show_help; exit 0 ;;
            *) file="$1"; shift ;;
        esac
    done

    if [[ -z "$file" ]]; then
        show_help
        exit 1
    fi

    if [[ ! -f "$file" ]]; then
        printf "\033[31mError: File not found: %s\033[0m\n" "$file"
        exit 1
    fi

    if $interactive; then
        interactive_viewer "$file"
    else
        render_markdown "$file" "$width"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
