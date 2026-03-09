#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#   ██████╗ ██████╗ ██████╗ ███████╗    ███████╗████████╗ █████╗ ████████╗███████╗
#  ██╔════╝██╔═══██╗██╔══██╗██╔════╝    ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██╔════╝
#  ██║     ██║   ██║██║  ██║█████╗      ███████╗   ██║   ███████║   ██║   ███████╗
#  ██║     ██║   ██║██║  ██║██╔══╝      ╚════██║   ██║   ██╔══██║   ██║   ╚════██║
#  ╚██████╗╚██████╔╝██████╔╝███████╗    ███████║   ██║   ██║  ██║   ██║   ███████║
#   ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚══════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD CODE STATISTICS ANALYZER v1.0
#  Project Analytics & Code Metrics Dashboard
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

declare -A LANG_EXTENSIONS=(
    [bash]="sh bash zsh"
    [python]="py pyw"
    [javascript]="js mjs jsx"
    [typescript]="ts tsx"
    [go]="go"
    [rust]="rs"
    [c]="c h"
    [cpp]="cpp cc cxx hpp hxx"
    [java]="java"
    [ruby]="rb"
    [php]="php"
    [html]="html htm"
    [css]="css scss sass less"
    [json]="json"
    [yaml]="yml yaml"
    [markdown]="md markdown"
    [sql]="sql"
    [swift]="swift"
    [kotlin]="kt kts"
)

declare -A LANG_COLORS=(
    [bash]="208"
    [python]="226"
    [javascript]="226"
    [typescript]="39"
    [go]="51"
    [rust]="208"
    [c]="39"
    [cpp]="39"
    [java]="196"
    [ruby]="196"
    [php]="141"
    [html]="208"
    [css]="39"
    [json]="226"
    [yaml]="196"
    [markdown]="252"
    [sql]="208"
    [swift]="208"
    [kotlin]="141"
)

declare -A LANG_ICONS=(
    [bash]="📜"
    [python]="🐍"
    [javascript]="📦"
    [typescript]="📘"
    [go]="🐹"
    [rust]="🦀"
    [c]="⚙️"
    [cpp]="⚙️"
    [java]="☕"
    [ruby]="💎"
    [php]="🐘"
    [html]="🌐"
    [css]="🎨"
    [json]="📋"
    [yaml]="📄"
    [markdown]="📝"
    [sql]="🗃️"
    [swift]="🕊️"
    [kotlin]="🅺"
)

#───────────────────────────────────────────────────────────────────────────────
# ANALYSIS FUNCTIONS
#───────────────────────────────────────────────────────────────────────────────

detect_language() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"

    for lang in "${!LANG_EXTENSIONS[@]}"; do
        for e in ${LANG_EXTENSIONS[$lang]}; do
            [[ "$ext" == "$e" ]] && echo "$lang" && return
        done
    done
    echo "other"
}

count_lines() {
    local file="$1"
    local total=0
    local code=0
    local comments=0
    local blank=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((total++))

        # Trim whitespace
        local trimmed="${line#"${line%%[![:space:]]*}"}"

        if [[ -z "$trimmed" ]]; then
            ((blank++))
        elif [[ "$trimmed" =~ ^[#//\*\;] ]] || [[ "$trimmed" =~ ^\<\!-- ]] || [[ "$trimmed" =~ ^/\* ]]; then
            ((comments++))
        else
            ((code++))
        fi
    done < "$file"

    echo "$total $code $comments $blank"
}

get_file_complexity() {
    local file="$1"
    local complexity=0

    # Count control structures
    local ifs=$(grep -cE '\b(if|else|elif|switch|case)\b' "$file" 2>/dev/null || echo 0)
    local loops=$(grep -cE '\b(for|while|do|foreach|loop)\b' "$file" 2>/dev/null || echo 0)
    local funcs=$(grep -cE '\b(function|def|func|fn|sub)\b' "$file" 2>/dev/null || echo 0)
    local exceptions=$(grep -cE '\b(try|catch|except|finally|throw|raise)\b' "$file" 2>/dev/null || echo 0)

    complexity=$((ifs + loops + funcs * 2 + exceptions))
    echo "$complexity"
}

analyze_directory() {
    local dir="$1"
    local -A lang_files=()
    local -A lang_lines=()
    local -A lang_code=()
    local -A lang_comments=()
    local -A lang_blank=()
    local total_files=0
    local total_lines=0
    local total_code=0
    local total_comments=0
    local total_blank=0

    printf "\n  \033[38;5;240mScanning: %s\033[0m\n" "$dir"

    while IFS= read -r file; do
        [[ ! -f "$file" ]] && continue
        [[ "$file" =~ (node_modules|vendor|\.git|\.venv|__pycache__|dist|build)/ ]] && continue

        local lang=$(detect_language "$file")
        [[ "$lang" == "other" ]] && continue

        local counts=$(count_lines "$file")
        read -r lines code comments blank <<< "$counts"

        ((lang_files[$lang]++))
        ((lang_lines[$lang]+=lines))
        ((lang_code[$lang]+=code))
        ((lang_comments[$lang]+=comments))
        ((lang_blank[$lang]+=blank))
        ((total_files++))
        ((total_lines+=lines))
        ((total_code+=code))
        ((total_comments+=comments))
        ((total_blank+=blank))

    done < <(find "$dir" -type f 2>/dev/null)

    # Store results in globals
    declare -gA RESULT_FILES=()
    declare -gA RESULT_LINES=()
    declare -gA RESULT_CODE=()
    declare -gA RESULT_COMMENTS=()
    declare -gA RESULT_BLANK=()

    for lang in "${!lang_files[@]}"; do
        RESULT_FILES[$lang]=${lang_files[$lang]}
        RESULT_LINES[$lang]=${lang_lines[$lang]}
        RESULT_CODE[$lang]=${lang_code[$lang]}
        RESULT_COMMENTS[$lang]=${lang_comments[$lang]}
        RESULT_BLANK[$lang]=${lang_blank[$lang]}
    done

    TOTAL_FILES=$total_files
    TOTAL_LINES=$total_lines
    TOTAL_CODE=$total_code
    TOTAL_COMMENTS=$total_comments
    TOTAL_BLANK=$total_blank
}

#───────────────────────────────────────────────────────────────────────────────
# VISUALIZATION
#───────────────────────────────────────────────────────────────────────────────

format_number() {
    local num="$1"
    if [[ $num -ge 1000000 ]]; then
        printf "%.1fM" "$(echo "$num / 1000000" | bc -l)"
    elif [[ $num -ge 1000 ]]; then
        printf "%.1fK" "$(echo "$num / 1000" | bc -l)"
    else
        echo "$num"
    fi
}

draw_bar() {
    local value="$1"
    local max="$2"
    local width="$3"
    local color="$4"

    local filled=$((value * width / max))
    [[ $filled -eq 0 && $value -gt 0 ]] && filled=1

    printf "\033[38;5;${color}m"
    for ((i=0; i<filled; i++)); do printf "█"; done
    printf "\033[38;5;240m"
    for ((i=filled; i<width; i++)); do printf "░"; done
    printf "\033[0m"
}

render_header() {
    printf "\033[1;38;5;214m"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                         📊 CODE STATISTICS ANALYZER                          ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    printf "\033[0m"
}

render_summary() {
    local dir="$1"

    printf "\n  \033[1;38;5;39m📁 Project: \033[0m%s\n" "$dir"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    # Summary boxes
    printf "  ┌────────────┬────────────┬────────────┬────────────┐\n"
    printf "  │ \033[1;38;5;39m📄 Files  \033[0m │ \033[1;38;5;46m📝 Lines  \033[0m │ \033[1;38;5;226m💻 Code   \033[0m │ \033[1;38;5;208m💬 Comment\033[0m │\n"
    printf "  ├────────────┼────────────┼────────────┼────────────┤\n"
    printf "  │   %6s   │   %6s   │   %6s   │   %6s   │\n" \
        "$(format_number $TOTAL_FILES)" \
        "$(format_number $TOTAL_LINES)" \
        "$(format_number $TOTAL_CODE)" \
        "$(format_number $TOTAL_COMMENTS)"
    printf "  └────────────┴────────────┴────────────┴────────────┘\n"
}

render_language_breakdown() {
    printf "\n  \033[1;38;5;201m📈 Language Breakdown\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    # Sort languages by lines
    local sorted_langs=()
    for lang in "${!RESULT_LINES[@]}"; do
        sorted_langs+=("${RESULT_LINES[$lang]}:$lang")
    done
    IFS=$'\n' sorted_langs=($(sort -t: -k1 -rn <<< "${sorted_langs[*]}")); unset IFS

    # Find max for bar scaling
    local max_lines=1
    for entry in "${sorted_langs[@]}"; do
        local lines="${entry%%:*}"
        [[ $lines -gt $max_lines ]] && max_lines=$lines
    done

    for entry in "${sorted_langs[@]}"; do
        local lines="${entry%%:*}"
        local lang="${entry#*:}"
        local files=${RESULT_FILES[$lang]:-0}
        local code=${RESULT_CODE[$lang]:-0}
        local color=${LANG_COLORS[$lang]:-252}
        local icon=${LANG_ICONS[$lang]:-"📄"}
        local pct=$((lines * 100 / TOTAL_LINES))

        printf "  %s %-12s " "$icon" "$lang"
        draw_bar "$lines" "$max_lines" 30 "$color"
        printf "  \033[38;5;252m%6s lines\033[0m  \033[38;5;240m(%2d%%) %d files\033[0m\n" \
            "$(format_number $lines)" "$pct" "$files"
    done
}

render_code_composition() {
    printf "\n  \033[1;38;5;46m📊 Code Composition\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    local code_pct=$((TOTAL_CODE * 100 / TOTAL_LINES))
    local comment_pct=$((TOTAL_COMMENTS * 100 / TOTAL_LINES))
    local blank_pct=$((TOTAL_BLANK * 100 / TOTAL_LINES))

    # Visual pie representation
    local bar_width=50

    printf "  \033[38;5;46mCode     \033[0m "
    draw_bar "$TOTAL_CODE" "$TOTAL_LINES" "$bar_width" "46"
    printf " %3d%%\n" "$code_pct"

    printf "  \033[38;5;208mComments \033[0m "
    draw_bar "$TOTAL_COMMENTS" "$TOTAL_LINES" "$bar_width" "208"
    printf " %3d%%\n" "$comment_pct"

    printf "  \033[38;5;240mBlank    \033[0m "
    draw_bar "$TOTAL_BLANK" "$TOTAL_LINES" "$bar_width" "240"
    printf " %3d%%\n" "$blank_pct"
}

render_file_types() {
    printf "\n  \033[1;38;5;226m📁 File Type Distribution\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    # Grid display of file counts
    local col=0
    for lang in "${!RESULT_FILES[@]}"; do
        local files=${RESULT_FILES[$lang]}
        local icon=${LANG_ICONS[$lang]:-"📄"}
        local color=${LANG_COLORS[$lang]:-252}

        printf "  %s \033[38;5;${color}m%-10s\033[0m \033[38;5;240m%4d\033[0m" "$icon" "$lang" "$files"

        ((col++))
        if [[ $col -ge 3 ]]; then
            printf "\n"
            col=0
        else
            printf "   "
        fi
    done
    [[ $col -ne 0 ]] && printf "\n"
}

render_largest_files() {
    local dir="$1"
    printf "\n  \033[1;38;5;196m📏 Largest Files\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    local count=0
    while IFS= read -r line; do
        local lines="${line%% *}"
        local file="${line#* }"
        file="${file#$dir/}"

        local lang=$(detect_language "$file")
        local color=${LANG_COLORS[$lang]:-252}
        local icon=${LANG_ICONS[$lang]:-"📄"}

        printf "  %s \033[38;5;${color}m%6s lines\033[0m  %-50s\n" "$icon" "$(format_number $lines)" "${file:0:50}"

        ((count++))
        [[ $count -ge 10 ]] && break
    done < <(find "$dir" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \) \
        ! -path "*node_modules*" ! -path "*.git*" ! -path "*vendor*" \
        -exec wc -l {} \; 2>/dev/null | sort -rn)
}

render_complexity_analysis() {
    local dir="$1"
    printf "\n  \033[1;38;5;141m🧩 Complexity Analysis\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    local high_complexity=()
    local medium_complexity=()
    local low_complexity=()

    while IFS= read -r file; do
        [[ ! -f "$file" ]] && continue
        [[ "$file" =~ (node_modules|vendor|\.git)/ ]] && continue

        local complexity=$(get_file_complexity "$file")
        local fname="${file#$dir/}"

        if [[ $complexity -ge 50 ]]; then
            high_complexity+=("$complexity:$fname")
        elif [[ $complexity -ge 20 ]]; then
            medium_complexity+=("$complexity:$fname")
        else
            low_complexity+=("$complexity:$fname")
        fi
    done < <(find "$dir" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" \) 2>/dev/null | head -100)

    printf "  \033[38;5;196m● High Complexity:\033[0m    %d files\n" "${#high_complexity[@]}"
    printf "  \033[38;5;226m● Medium Complexity:\033[0m  %d files\n" "${#medium_complexity[@]}"
    printf "  \033[38;5;46m● Low Complexity:\033[0m     %d files\n" "${#low_complexity[@]}"

    if [[ ${#high_complexity[@]} -gt 0 ]]; then
        printf "\n  \033[38;5;240mHighest complexity files:\033[0m\n"
        IFS=$'\n' sorted=($(sort -t: -k1 -rn <<< "${high_complexity[*]}")); unset IFS
        for ((i=0; i<3 && i<${#sorted[@]}; i++)); do
            local c="${sorted[$i]%%:*}"
            local f="${sorted[$i]#*:}"
            printf "    \033[38;5;196m%3d\033[0m  %s\n" "$c" "${f:0:50}"
        done
    fi
}

render_git_stats() {
    local dir="$1"

    if [[ ! -d "$dir/.git" ]]; then
        return
    fi

    printf "\n  \033[1;38;5;208m📜 Git Statistics\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    cd "$dir" || return

    local total_commits=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    local contributors=$(git shortlog -sn 2>/dev/null | wc -l)
    local first_commit=$(git log --reverse --format="%as" 2>/dev/null | head -1)
    local last_commit=$(git log -1 --format="%as" 2>/dev/null)
    local branches=$(git branch -a 2>/dev/null | wc -l)

    printf "  📊 Total Commits:    %s\n" "$total_commits"
    printf "  👥 Contributors:     %s\n" "$contributors"
    printf "  🌿 Branches:         %s\n" "$branches"
    printf "  📅 First Commit:     %s\n" "$first_commit"
    printf "  📅 Last Commit:      %s\n" "$last_commit"

    printf "\n  \033[38;5;240mTop Contributors:\033[0m\n"
    git shortlog -sn 2>/dev/null | head -5 | while read -r count name; do
        printf "    \033[38;5;39m%4d\033[0m  %s\n" "$count" "$name"
    done

    cd - > /dev/null
}

#───────────────────────────────────────────────────────────────────────────────
# EXPORT FUNCTIONS
#───────────────────────────────────────────────────────────────────────────────

export_json() {
    local dir="$1"
    local output="$2"

    {
        printf '{\n'
        printf '  "project": "%s",\n' "$dir"
        printf '  "analyzed_at": "%s",\n' "$(date -Iseconds)"
        printf '  "summary": {\n'
        printf '    "total_files": %d,\n' "$TOTAL_FILES"
        printf '    "total_lines": %d,\n' "$TOTAL_LINES"
        printf '    "code_lines": %d,\n' "$TOTAL_CODE"
        printf '    "comment_lines": %d,\n' "$TOTAL_COMMENTS"
        printf '    "blank_lines": %d\n' "$TOTAL_BLANK"
        printf '  },\n'
        printf '  "languages": {\n'

        local first=true
        for lang in "${!RESULT_FILES[@]}"; do
            $first || printf ',\n'
            printf '    "%s": {\n' "$lang"
            printf '      "files": %d,\n' "${RESULT_FILES[$lang]}"
            printf '      "lines": %d,\n' "${RESULT_LINES[$lang]}"
            printf '      "code": %d,\n' "${RESULT_CODE[$lang]}"
            printf '      "comments": %d\n' "${RESULT_COMMENTS[$lang]}"
            printf '    }'
            first=false
        done

        printf '\n  }\n'
        printf '}\n'
    } > "$output"

    printf "\n  \033[38;5;46m✓ Exported to: %s\033[0m\n" "$output"
}

export_markdown() {
    local dir="$1"
    local output="$2"

    {
        printf "# Code Statistics Report\n\n"
        printf "**Project:** %s\n" "$dir"
        printf "**Analyzed:** %s\n\n" "$(date)"

        printf "## Summary\n\n"
        printf "| Metric | Value |\n"
        printf "|--------|-------|\n"
        printf "| Files | %d |\n" "$TOTAL_FILES"
        printf "| Lines | %d |\n" "$TOTAL_LINES"
        printf "| Code | %d |\n" "$TOTAL_CODE"
        printf "| Comments | %d |\n" "$TOTAL_COMMENTS"
        printf "| Blank | %d |\n\n" "$TOTAL_BLANK"

        printf "## Languages\n\n"
        printf "| Language | Files | Lines | Code | Comments |\n"
        printf "|----------|-------|-------|------|----------|\n"

        for lang in "${!RESULT_FILES[@]}"; do
            printf "| %s | %d | %d | %d | %d |\n" \
                "$lang" "${RESULT_FILES[$lang]}" "${RESULT_LINES[$lang]}" \
                "${RESULT_CODE[$lang]}" "${RESULT_COMMENTS[$lang]}"
        done

    } > "$output"

    printf "\n  \033[38;5;46m✓ Exported to: %s\033[0m\n" "$output"
}

#───────────────────────────────────────────────────────────────────────────────
# INTERACTIVE MODE
#───────────────────────────────────────────────────────────────────────────────

interactive_mode() {
    local dir="$1"

    while true; do
        clear
        render_header
        analyze_directory "$dir"
        render_summary "$dir"
        render_language_breakdown
        render_code_composition
        render_file_types
        render_largest_files "$dir"
        render_complexity_analysis "$dir"
        render_git_stats "$dir"

        printf "\n  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"
        printf "  \033[38;5;39mr\033[0m Refresh  \033[38;5;46mj\033[0m Export JSON  \033[38;5;226mm\033[0m Export Markdown  \033[38;5;240mq\033[0m Quit\n"

        read -rsn1 key
        case "$key" in
            r|R) continue ;;
            j|J) export_json "$dir" "code-stats.json" ;;
            m|M) export_markdown "$dir" "code-stats.md" ;;
            q|Q) clear; exit 0 ;;
        esac
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

show_help() {
    cat << 'EOF'

  BLACKROAD CODE STATISTICS ANALYZER
  ═══════════════════════════════════

  Usage: code-stats.sh [options] [directory]

  Options:
    -i, --interactive    Interactive mode with refresh
    -j, --json <file>    Export results to JSON
    -m, --markdown <file> Export results to Markdown
    -h, --help           Show this help

  Features:
    • Line count analysis (code, comments, blank)
    • Language detection and breakdown
    • Complexity analysis
    • Largest files identification
    • Git statistics integration
    • Export to JSON/Markdown

  Examples:
    code-stats.sh                    # Analyze current directory
    code-stats.sh ./my-project       # Analyze specific directory
    code-stats.sh -i                 # Interactive mode
    code-stats.sh -j stats.json      # Export to JSON

EOF
}

main() {
    local dir="$(pwd)"
    local interactive=false
    local json_out=""
    local md_out=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--interactive) interactive=true; shift ;;
            -j|--json) json_out="$2"; shift 2 ;;
            -m|--markdown) md_out="$2"; shift 2 ;;
            -h|--help) show_help; exit 0 ;;
            *) dir="$1"; shift ;;
        esac
    done

    if [[ ! -d "$dir" ]]; then
        printf "\033[31mError: Directory not found: %s\033[0m\n" "$dir"
        exit 1
    fi

    dir="$(cd "$dir" && pwd)"

    if $interactive; then
        interactive_mode "$dir"
    else
        render_header
        analyze_directory "$dir"
        render_summary "$dir"
        render_language_breakdown
        render_code_composition
        render_file_types
        render_largest_files "$dir"
        render_complexity_analysis "$dir"
        render_git_stats "$dir"

        [[ -n "$json_out" ]] && export_json "$dir" "$json_out"
        [[ -n "$md_out" ]] && export_markdown "$dir" "$md_out"
    fi

    printf "\n"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
