#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██████╗  █████╗ ███████╗███████╗██╗    ██╗ ██████╗ ██████╗ ██████╗
#  ██╔══██╗██╔══██╗██╔════╝██╔════╝██║    ██║██╔═══██╗██╔══██╗██╔══██╗
#  ██████╔╝███████║███████╗███████╗██║ █╗ ██║██║   ██║██████╔╝██║  ██║
#  ██╔═══╝ ██╔══██║╚════██║╚════██║██║███╗██║██║   ██║██╔══██╗██║  ██║
#  ██║     ██║  ██║███████║███████║╚███╔███╔╝╚██████╔╝██║  ██║██████╔╝
#  ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD PASSWORD GENERATOR v1.0
#  Secure Password Generation & Strength Analysis
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CHARACTER SETS
#───────────────────────────────────────────────────────────────────────────────

LOWERCASE="abcdefghijklmnopqrstuvwxyz"
UPPERCASE="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
DIGITS="0123456789"
SYMBOLS="!@#\$%^&*()_+-=[]{}|;:,.<>?"
EXTENDED_SYMBOLS="\`~'\"\\/?"
SIMILAR="il1Lo0O"
AMBIGUOUS="{}[]()/\\'\"\`~,;:.<>"

# Wordlists for passphrases
WORDS=(
    "apple" "banana" "cherry" "dragon" "eagle" "falcon" "galaxy" "harbor"
    "island" "jungle" "knight" "legend" "mountain" "nebula" "ocean" "phoenix"
    "quartz" "rainbow" "shadow" "thunder" "universe" "volcano" "whisper" "xylophone"
    "yellow" "zenith" "arctic" "blizzard" "crystal" "diamond" "eclipse" "fortress"
    "glacier" "horizon" "infinity" "journey" "kingdom" "lighthouse" "midnight" "northstar"
    "olympus" "paradise" "quantum" "riddle" "sapphire" "twilight" "ultimate" "velocity"
    "warrior" "xenon" "yearning" "zephyr" "adventure" "beacon" "cascade" "destiny"
)

#───────────────────────────────────────────────────────────────────────────────
# PASSWORD GENERATION
#───────────────────────────────────────────────────────────────────────────────

generate_password() {
    local length="${1:-16}"
    local include_lower="${2:-true}"
    local include_upper="${3:-true}"
    local include_digits="${4:-true}"
    local include_symbols="${5:-true}"
    local exclude_similar="${6:-false}"
    local exclude_ambiguous="${7:-false}"

    local charset=""

    [[ "$include_lower" == "true" ]] && charset+="$LOWERCASE"
    [[ "$include_upper" == "true" ]] && charset+="$UPPERCASE"
    [[ "$include_digits" == "true" ]] && charset+="$DIGITS"
    [[ "$include_symbols" == "true" ]] && charset+="$SYMBOLS"

    # Remove similar characters
    if [[ "$exclude_similar" == "true" ]]; then
        for c in $(echo "$SIMILAR" | fold -w1); do
            charset="${charset//$c/}"
        done
    fi

    # Remove ambiguous characters
    if [[ "$exclude_ambiguous" == "true" ]]; then
        for c in $(echo "$AMBIGUOUS" | fold -w1); do
            charset="${charset//$c/}"
        done
    fi

    local charset_len=${#charset}
    local password=""

    for ((i=0; i<length; i++)); do
        local rand=$((RANDOM % charset_len))
        password+="${charset:$rand:1}"
    done

    # Ensure at least one of each required type
    local has_lower=false has_upper=false has_digit=false has_symbol=false

    for ((i=0; i<${#password}; i++)); do
        local c="${password:$i:1}"
        [[ "$LOWERCASE" == *"$c"* ]] && has_lower=true
        [[ "$UPPERCASE" == *"$c"* ]] && has_upper=true
        [[ "$DIGITS" == *"$c"* ]] && has_digit=true
        [[ "$SYMBOLS" == *"$c"* ]] && has_symbol=true
    done

    # Regenerate if missing required types
    if [[ "$include_lower" == "true" && "$has_lower" == "false" ]] ||
       [[ "$include_upper" == "true" && "$has_upper" == "false" ]] ||
       [[ "$include_digits" == "true" && "$has_digit" == "false" ]] ||
       [[ "$include_symbols" == "true" && "$has_symbol" == "false" ]]; then
        generate_password "$length" "$include_lower" "$include_upper" "$include_digits" "$include_symbols" "$exclude_similar" "$exclude_ambiguous"
        return
    fi

    echo "$password"
}

generate_pin() {
    local length="${1:-4}"
    local pin=""

    for ((i=0; i<length; i++)); do
        pin+=$((RANDOM % 10))
    done

    echo "$pin"
}

generate_passphrase() {
    local word_count="${1:-4}"
    local separator="${2:--}"
    local capitalize="${3:-true}"

    local passphrase=""
    local word_pool_size=${#WORDS[@]}

    for ((i=0; i<word_count; i++)); do
        local idx=$((RANDOM % word_pool_size))
        local word="${WORDS[$idx]}"

        if [[ "$capitalize" == "true" ]]; then
            word="${word^}"
        fi

        [[ $i -gt 0 ]] && passphrase+="$separator"
        passphrase+="$word"
    done

    echo "$passphrase"
}

generate_pronounceable() {
    local syllables="${1:-4}"
    local consonants="bcdfghjklmnpqrstvwxyz"
    local vowels="aeiou"
    local password=""

    for ((s=0; s<syllables; s++)); do
        local c_idx=$((RANDOM % ${#consonants}))
        local v_idx=$((RANDOM % ${#vowels}))
        password+="${consonants:$c_idx:1}"
        password+="${vowels:$v_idx:1}"

        # Sometimes add another consonant
        if [[ $((RANDOM % 2)) -eq 0 ]]; then
            c_idx=$((RANDOM % ${#consonants}))
            password+="${consonants:$c_idx:1}"
        fi
    done

    echo "$password"
}

generate_pattern() {
    local pattern="$1"
    local result=""

    for ((i=0; i<${#pattern}; i++)); do
        local c="${pattern:$i:1}"
        case "$c" in
            l) result+="${LOWERCASE:$((RANDOM % 26)):1}" ;;
            L) result+="${UPPERCASE:$((RANDOM % 26)):1}" ;;
            d) result+="${DIGITS:$((RANDOM % 10)):1}" ;;
            s) result+="${SYMBOLS:$((RANDOM % ${#SYMBOLS})):1}" ;;
            a) result+="$LOWERCASE$UPPERCASE"; result="${result:$((RANDOM % 52)):1}" ;;
            *) result+="$c" ;;
        esac
    done

    echo "$result"
}

#───────────────────────────────────────────────────────────────────────────────
# PASSWORD STRENGTH ANALYSIS
#───────────────────────────────────────────────────────────────────────────────

analyze_strength() {
    local password="$1"
    local length=${#password}

    local has_lower=false has_upper=false has_digit=false has_symbol=false
    local unique_chars=""
    local consecutive=0
    local max_consecutive=0

    local prev_char=""

    for ((i=0; i<length; i++)); do
        local c="${password:$i:1}"

        [[ "$LOWERCASE" == *"$c"* ]] && has_lower=true
        [[ "$UPPERCASE" == *"$c"* ]] && has_upper=true
        [[ "$DIGITS" == *"$c"* ]] && has_digit=true
        [[ "$SYMBOLS$EXTENDED_SYMBOLS" == *"$c"* ]] && has_symbol=true

        [[ "$unique_chars" != *"$c"* ]] && unique_chars+="$c"

        if [[ "$c" == "$prev_char" ]]; then
            ((consecutive++))
            [[ $consecutive -gt $max_consecutive ]] && max_consecutive=$consecutive
        else
            consecutive=0
        fi
        prev_char="$c"
    done

    # Calculate entropy
    local charset_size=0
    $has_lower && ((charset_size += 26))
    $has_upper && ((charset_size += 26))
    $has_digit && ((charset_size += 10))
    $has_symbol && ((charset_size += 32))

    local entropy=0
    if [[ $charset_size -gt 0 ]]; then
        entropy=$(echo "l($charset_size)/l(2) * $length" | bc -l 2>/dev/null || echo "0")
        entropy=$(printf "%.0f" "$entropy")
    fi

    # Calculate score (0-100)
    local score=0

    # Length score (up to 30 points)
    if [[ $length -ge 16 ]]; then score=$((score + 30))
    elif [[ $length -ge 12 ]]; then score=$((score + 25))
    elif [[ $length -ge 8 ]]; then score=$((score + 15))
    else score=$((score + length))
    fi

    # Character variety (up to 40 points)
    $has_lower && ((score += 10))
    $has_upper && ((score += 10))
    $has_digit && ((score += 10))
    $has_symbol && ((score += 10))

    # Uniqueness (up to 20 points)
    local unique_ratio=$((${#unique_chars} * 20 / length))
    score=$((score + unique_ratio))

    # Entropy bonus (up to 10 points)
    [[ $entropy -ge 60 ]] && score=$((score + 10))
    [[ $entropy -ge 40 && $entropy -lt 60 ]] && score=$((score + 5))

    # Penalties
    [[ $max_consecutive -ge 3 ]] && score=$((score - 10))
    [[ $length -lt 8 ]] && score=$((score - 20))

    [[ $score -lt 0 ]] && score=0
    [[ $score -gt 100 ]] && score=100

    # Determine strength level
    local level=""
    local color=""
    if [[ $score -ge 80 ]]; then
        level="EXCELLENT"
        color="46"
    elif [[ $score -ge 60 ]]; then
        level="STRONG"
        color="39"
    elif [[ $score -ge 40 ]]; then
        level="MODERATE"
        color="226"
    elif [[ $score -ge 20 ]]; then
        level="WEAK"
        color="208"
    else
        level="VERY WEAK"
        color="196"
    fi

    # Output analysis
    echo "score:$score"
    echo "level:$level"
    echo "color:$color"
    echo "length:$length"
    echo "entropy:$entropy"
    echo "unique:${#unique_chars}"
    echo "has_lower:$has_lower"
    echo "has_upper:$has_upper"
    echo "has_digit:$has_digit"
    echo "has_symbol:$has_symbol"
}

render_strength() {
    local password="$1"

    declare -A analysis
    while IFS=: read -r key value; do
        analysis[$key]="$value"
    done < <(analyze_strength "$password")

    printf "\n  \033[1;38;5;201m🔐 Password Strength Analysis\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    # Strength bar
    local score=${analysis[score]}
    local color=${analysis[color]}
    local bar_width=40
    local filled=$((score * bar_width / 100))

    printf "  Strength: \033[38;5;${color}m"
    for ((i=0; i<filled; i++)); do printf "█"; done
    printf "\033[38;5;240m"
    for ((i=filled; i<bar_width; i++)); do printf "░"; done
    printf "\033[0m \033[38;5;${color}m%d%%\033[0m  \033[1;38;5;${color}m%s\033[0m\n" "$score" "${analysis[level]}"

    printf "\n"

    # Details
    printf "  📏 Length:     %d characters\n" "${analysis[length]}"
    printf "  🎲 Entropy:    %d bits\n" "${analysis[entropy]}"
    printf "  🔤 Unique:     %d characters\n" "${analysis[unique]}"

    printf "\n  Character Types:\n"
    [[ "${analysis[has_lower]}" == "true" ]] && printf "    \033[38;5;46m✓\033[0m Lowercase\n" || printf "    \033[38;5;196m✗\033[0m Lowercase\n"
    [[ "${analysis[has_upper]}" == "true" ]] && printf "    \033[38;5;46m✓\033[0m Uppercase\n" || printf "    \033[38;5;196m✗\033[0m Uppercase\n"
    [[ "${analysis[has_digit]}" == "true" ]] && printf "    \033[38;5;46m✓\033[0m Numbers\n" || printf "    \033[38;5;196m✗\033[0m Numbers\n"
    [[ "${analysis[has_symbol]}" == "true" ]] && printf "    \033[38;5;46m✓\033[0m Symbols\n" || printf "    \033[38;5;196m✗\033[0m Symbols\n"

    # Crack time estimation
    local entropy=${analysis[entropy]}
    local crack_seconds=$(echo "2^$entropy / 1000000000" | bc 2>/dev/null || echo "0")

    printf "\n  ⏱️  Time to crack: "
    if [[ $crack_seconds -ge 31536000000 ]]; then
        printf "\033[38;5;46mCenturies\033[0m\n"
    elif [[ $crack_seconds -ge 31536000 ]]; then
        local years=$((crack_seconds / 31536000))
        printf "\033[38;5;46m%d years\033[0m\n" "$years"
    elif [[ $crack_seconds -ge 86400 ]]; then
        local days=$((crack_seconds / 86400))
        printf "\033[38;5;226m%d days\033[0m\n" "$days"
    elif [[ $crack_seconds -ge 3600 ]]; then
        local hours=$((crack_seconds / 3600))
        printf "\033[38;5;208m%d hours\033[0m\n" "$hours"
    else
        printf "\033[38;5;196mInstantly\033[0m\n"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# INTERACTIVE MODE
#───────────────────────────────────────────────────────────────────────────────

render_header() {
    printf "\033[1;38;5;214m"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                         🔐 PASSWORD GENERATOR SUITE                          ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    printf "\033[0m"
}

render_menu() {
    printf "\n  \033[1;38;5;39mGeneration Options:\033[0m\n\n"

    printf "  \033[38;5;46m1\033[0m  🔑 Random Password (customizable)\n"
    printf "  \033[38;5;46m2\033[0m  📝 Passphrase (memorable words)\n"
    printf "  \033[38;5;46m3\033[0m  🔢 PIN Code\n"
    printf "  \033[38;5;46m4\033[0m  🗣️  Pronounceable Password\n"
    printf "  \033[38;5;46m5\033[0m  🎯 Pattern-based Password\n"
    printf "  \033[38;5;46m6\033[0m  📊 Analyze Password Strength\n"
    printf "  \033[38;5;46m7\033[0m  📋 Batch Generate\n"
    printf "  \n"
    printf "  \033[38;5;240mq\033[0m  Quit\n"
}

interactive_random_password() {
    printf "\n  \033[1;38;5;201m🔑 Random Password Generator\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    printf "  Length (default 16): "
    read -r length
    length="${length:-16}"

    printf "  Include lowercase? (Y/n): "
    read -r lower
    local inc_lower="true"
    [[ "$lower" =~ ^[nN]$ ]] && inc_lower="false"

    printf "  Include uppercase? (Y/n): "
    read -r upper
    local inc_upper="true"
    [[ "$upper" =~ ^[nN]$ ]] && inc_upper="false"

    printf "  Include numbers? (Y/n): "
    read -r digits
    local inc_digits="true"
    [[ "$digits" =~ ^[nN]$ ]] && inc_digits="false"

    printf "  Include symbols? (Y/n): "
    read -r symbols
    local inc_symbols="true"
    [[ "$symbols" =~ ^[nN]$ ]] && inc_symbols="false"

    printf "  Exclude similar (il1Lo0O)? (y/N): "
    read -r similar
    local exc_similar="false"
    [[ "$similar" =~ ^[yY]$ ]] && exc_similar="true"

    printf "\n  \033[1;38;5;46mGenerated Password:\033[0m\n\n"

    local password=$(generate_password "$length" "$inc_lower" "$inc_upper" "$inc_digits" "$inc_symbols" "$exc_similar" "false")

    printf "  \033[48;5;236m  \033[1;38;5;226m%s\033[0m\033[48;5;236m  \033[0m\n" "$password"

    render_strength "$password"

    # Copy to clipboard if available
    if command -v xclip &>/dev/null; then
        echo -n "$password" | xclip -selection clipboard
        printf "\n  \033[38;5;46m✓ Copied to clipboard\033[0m\n"
    elif command -v pbcopy &>/dev/null; then
        echo -n "$password" | pbcopy
        printf "\n  \033[38;5;46m✓ Copied to clipboard\033[0m\n"
    fi
}

interactive_passphrase() {
    printf "\n  \033[1;38;5;201m📝 Passphrase Generator\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    printf "  Number of words (default 4): "
    read -r count
    count="${count:-4}"

    printf "  Separator (default -): "
    read -r sep
    sep="${sep:--}"

    printf "  Capitalize words? (Y/n): "
    read -r cap
    local capitalize="true"
    [[ "$cap" =~ ^[nN]$ ]] && capitalize="false"

    local passphrase=$(generate_passphrase "$count" "$sep" "$capitalize")

    printf "\n  \033[1;38;5;46mGenerated Passphrase:\033[0m\n\n"
    printf "  \033[48;5;236m  \033[1;38;5;226m%s\033[0m\033[48;5;236m  \033[0m\n" "$passphrase"

    render_strength "$passphrase"
}

interactive_pin() {
    printf "\n  \033[1;38;5;201m🔢 PIN Generator\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    printf "  PIN length (default 4): "
    read -r length
    length="${length:-4}"

    local pin=$(generate_pin "$length")

    printf "\n  \033[1;38;5;46mGenerated PIN:\033[0m\n\n"
    printf "  \033[48;5;236m  \033[1;38;5;226m%s\033[0m\033[48;5;236m  \033[0m\n" "$pin"

    printf "\n  \033[38;5;240m⚠️  PINs are weak - use only when required\033[0m\n"
}

interactive_pronounceable() {
    printf "\n  \033[1;38;5;201m🗣️ Pronounceable Password Generator\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    printf "  Number of syllables (default 4): "
    read -r syllables
    syllables="${syllables:-4}"

    local password=$(generate_pronounceable "$syllables")

    printf "\n  \033[1;38;5;46mGenerated Password:\033[0m\n\n"
    printf "  \033[48;5;236m  \033[1;38;5;226m%s\033[0m\033[48;5;236m  \033[0m\n" "$password"

    render_strength "$password"
}

interactive_pattern() {
    printf "\n  \033[1;38;5;201m🎯 Pattern-based Generator\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    printf "  Pattern legend:\n"
    printf "    \033[38;5;39ml\033[0m = lowercase    \033[38;5;39mL\033[0m = uppercase\n"
    printf "    \033[38;5;39md\033[0m = digit        \033[38;5;39ms\033[0m = symbol\n"
    printf "    \033[38;5;39ma\033[0m = any letter   \033[38;5;240mother\033[0m = literal\n"
    printf "\n  Example: LLLLdddd-ssss\n"
    printf "\n  Enter pattern: "
    read -r pattern

    local password=$(generate_pattern "$pattern")

    printf "\n  \033[1;38;5;46mGenerated Password:\033[0m\n\n"
    printf "  \033[48;5;236m  \033[1;38;5;226m%s\033[0m\033[48;5;236m  \033[0m\n" "$password"

    render_strength "$password"
}

interactive_analyze() {
    printf "\n  \033[1;38;5;201m📊 Password Strength Analyzer\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    printf "  Enter password to analyze: "
    read -rs password
    printf "\n"

    render_strength "$password"
}

interactive_batch() {
    printf "\n  \033[1;38;5;201m📋 Batch Password Generator\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    printf "  Number of passwords (default 10): "
    read -r count
    count="${count:-10}"

    printf "  Length (default 16): "
    read -r length
    length="${length:-16}"

    printf "\n  \033[1;38;5;46mGenerated Passwords:\033[0m\n\n"

    for ((i=1; i<=count; i++)); do
        local pwd=$(generate_password "$length" "true" "true" "true" "true" "false" "false")
        declare -A analysis
        while IFS=: read -r key value; do
            analysis[$key]="$value"
        done < <(analyze_strength "$pwd")

        local color=${analysis[color]}
        printf "  %2d. \033[38;5;252m%s\033[0m  \033[38;5;${color}m[%s]\033[0m\n" "$i" "$pwd" "${analysis[level]}"
    done
}

interactive_mode() {
    while true; do
        clear
        render_header
        render_menu

        printf "\n  Select option: "
        read -rsn1 key

        case "$key" in
            1) interactive_random_password ;;
            2) interactive_passphrase ;;
            3) interactive_pin ;;
            4) interactive_pronounceable ;;
            5) interactive_pattern ;;
            6) interactive_analyze ;;
            7) interactive_batch ;;
            q|Q) clear; exit 0 ;;
            *) continue ;;
        esac

        printf "\n  \033[38;5;240mPress any key to continue...\033[0m"
        read -rsn1
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

show_help() {
    cat << 'EOF'

  BLACKROAD PASSWORD GENERATOR SUITE
  ═══════════════════════════════════

  Usage: password-generator.sh [options]

  Options:
    -l, --length <n>      Password length (default: 16)
    -c, --count <n>       Generate multiple passwords
    -p, --passphrase <n>  Generate passphrase with n words
    --pin <n>             Generate PIN with n digits
    --pattern <p>         Generate from pattern (l=lower, L=upper, d=digit, s=symbol)
    --analyze <pwd>       Analyze password strength
    -i, --interactive     Interactive mode
    -h, --help            Show this help

  Examples:
    password-generator.sh                    # Interactive mode
    password-generator.sh -l 24              # 24-char password
    password-generator.sh -c 5               # Generate 5 passwords
    password-generator.sh -p 5               # 5-word passphrase
    password-generator.sh --pin 6            # 6-digit PIN
    password-generator.sh --pattern "LLLddd" # Pattern-based

EOF
}

main() {
    local length=16
    local count=1
    local passphrase_words=0
    local pin_length=0
    local pattern=""
    local analyze_pwd=""
    local interactive=false

    if [[ $# -eq 0 ]]; then
        interactive=true
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--length) length="$2"; shift 2 ;;
            -c|--count) count="$2"; shift 2 ;;
            -p|--passphrase) passphrase_words="$2"; shift 2 ;;
            --pin) pin_length="$2"; shift 2 ;;
            --pattern) pattern="$2"; shift 2 ;;
            --analyze) analyze_pwd="$2"; shift 2 ;;
            -i|--interactive) interactive=true; shift ;;
            -h|--help) show_help; exit 0 ;;
            *) shift ;;
        esac
    done

    if $interactive; then
        interactive_mode
        exit 0
    fi

    if [[ -n "$analyze_pwd" ]]; then
        render_strength "$analyze_pwd"
        exit 0
    fi

    if [[ $passphrase_words -gt 0 ]]; then
        for ((i=0; i<count; i++)); do
            generate_passphrase "$passphrase_words"
        done
        exit 0
    fi

    if [[ $pin_length -gt 0 ]]; then
        for ((i=0; i<count; i++)); do
            generate_pin "$pin_length"
        done
        exit 0
    fi

    if [[ -n "$pattern" ]]; then
        for ((i=0; i<count; i++)); do
            generate_pattern "$pattern"
        done
        exit 0
    fi

    # Default: generate random passwords
    for ((i=0; i<count; i++)); do
        generate_password "$length"
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
