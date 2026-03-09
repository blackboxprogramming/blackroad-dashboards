#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ███████╗██╗  ██╗██████╗  ██████╗ ██████╗ ████████╗
#  ██╔════╝╚██╗██╔╝██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝
#  █████╗   ╚███╔╝ ██████╔╝██║   ██║██████╔╝   ██║
#  ██╔══╝   ██╔██╗ ██╔═══╝ ██║   ██║██╔══██╗   ██║
#  ███████╗██╔╝ ██╗██║     ╚██████╔╝██║  ██║   ██║
#  ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD DATA EXPORT SYSTEM v2.0
#  Export dashboard data to JSON, CSV, HTML, and Markdown
#═══════════════════════════════════════════════════════════════════════════════

# Source core library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

EXPORT_DIR="${BLACKROAD_DATA:-$HOME/.blackroad-dashboards/exports}"
mkdir -p "$EXPORT_DIR" 2>/dev/null

# Supported formats
EXPORT_FORMATS=("json" "csv" "html" "md" "txt")

#───────────────────────────────────────────────────────────────────────────────
# CORE EXPORT FUNCTIONS
#───────────────────────────────────────────────────────────────────────────────

# Generate export filename
generate_filename() {
    local prefix="${1:-export}"
    local format="${2:-json}"
    local timestamp=$(date "+%Y%m%d_%H%M%S")

    echo "${EXPORT_DIR}/${prefix}_${timestamp}.${format}"
}

# Export to JSON
export_json() {
    local data="$1"
    local filename="${2:-$(generate_filename "data" "json")}"

    # Validate JSON if jq available
    if command -v jq &>/dev/null; then
        echo "$data" | jq '.' > "$filename" 2>/dev/null || {
            # If invalid JSON, wrap as raw
            jq -n --arg raw "$data" '{data: $raw, exported_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))}' > "$filename"
        }
    else
        echo "$data" > "$filename"
    fi

    log_info "Exported to JSON: $filename"
    echo "$filename"
}

# Export to CSV
export_csv() {
    local json_data="$1"
    local filename="${2:-$(generate_filename "data" "csv")}"

    if ! command -v jq &>/dev/null; then
        log_error "jq is required for CSV export"
        return 1
    fi

    # Detect if array or object
    local data_type=$(echo "$json_data" | jq -r 'type' 2>/dev/null)

    case "$data_type" in
        array)
            # Get headers from first object
            local headers=$(echo "$json_data" | jq -r '.[0] | keys_unsorted | @csv' 2>/dev/null)

            if [[ -n "$headers" ]]; then
                echo "$headers" > "$filename"
                echo "$json_data" | jq -r '.[] | [.[]] | @csv' >> "$filename" 2>/dev/null
            else
                # Simple array
                echo "value" > "$filename"
                echo "$json_data" | jq -r '.[]' >> "$filename"
            fi
            ;;
        object)
            # Single object - key,value format
            echo "key,value" > "$filename"
            echo "$json_data" | jq -r 'to_entries[] | [.key, .value] | @csv' >> "$filename" 2>/dev/null
            ;;
        *)
            echo "data" > "$filename"
            echo "$json_data" >> "$filename"
            ;;
    esac

    log_info "Exported to CSV: $filename"
    echo "$filename"
}

# Export to HTML
export_html() {
    local title="$1"
    local data="$2"
    local filename="${3:-$(generate_filename "report" "html")}"

    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    cat > "$filename" << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BlackRoad Dashboard Export</title>
    <style>
        :root {
            --bg-primary: #0a0a14;
            --bg-secondary: #12121f;
            --text-primary: #ffffff;
            --text-secondary: #a0a0b0;
            --accent-cyan: #00d4ff;
            --accent-pink: #e91e8c;
            --accent-orange: #f7931a;
            --accent-green: #14f195;
            --accent-purple: #9945ff;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'SF Mono', 'Monaco', 'Inconsolata', 'Fira Code', monospace;
            background: var(--bg-primary);
            color: var(--text-primary);
            line-height: 1.6;
            padding: 2rem;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        header {
            text-align: center;
            padding: 2rem;
            background: linear-gradient(135deg, var(--accent-pink), var(--accent-purple), var(--accent-cyan));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 2rem;
        }

        h1 {
            font-size: 2.5rem;
            font-weight: 700;
        }

        .meta {
            color: var(--text-secondary);
            font-size: 0.9rem;
            margin-top: 0.5rem;
        }

        .card {
            background: var(--bg-secondary);
            border-radius: 12px;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
            border: 1px solid rgba(255,255,255,0.1);
        }

        .card h2 {
            color: var(--accent-cyan);
            margin-bottom: 1rem;
            font-size: 1.2rem;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 1rem;
        }

        th, td {
            padding: 0.75rem;
            text-align: left;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }

        th {
            background: rgba(0,212,255,0.1);
            color: var(--accent-cyan);
            font-weight: 600;
        }

        tr:hover {
            background: rgba(255,255,255,0.05);
        }

        .status-online { color: var(--accent-green); }
        .status-offline { color: #ff5252; }
        .status-warning { color: var(--accent-orange); }

        pre {
            background: var(--bg-primary);
            padding: 1rem;
            border-radius: 8px;
            overflow-x: auto;
            font-size: 0.85rem;
            color: var(--accent-green);
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 1.5rem;
        }

        .metric {
            text-align: center;
            padding: 1.5rem;
        }

        .metric-value {
            font-size: 2.5rem;
            font-weight: 700;
            color: var(--accent-orange);
        }

        .metric-label {
            color: var(--text-secondary);
            font-size: 0.9rem;
            margin-top: 0.5rem;
        }

        footer {
            text-align: center;
            padding: 2rem;
            color: var(--text-secondary);
            font-size: 0.85rem;
        }

        footer a {
            color: var(--accent-cyan);
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>BLACKROAD DASHBOARD</h1>
HTMLHEAD

    printf '            <p class="meta">%s | Generated: %s</p>\n' "$title" "$timestamp" >> "$filename"
    echo '        </header>' >> "$filename"
    echo '' >> "$filename"

    # Add data section
    echo '        <div class="card">' >> "$filename"
    echo '            <h2>Data Export</h2>' >> "$filename"
    echo '            <pre>' >> "$filename"

    # Format data based on type
    if command -v jq &>/dev/null && echo "$data" | jq '.' &>/dev/null; then
        echo "$data" | jq '.' >> "$filename"
    else
        echo "$data" >> "$filename"
    fi

    cat >> "$filename" << 'HTMLFOOT'
            </pre>
        </div>

        <footer>
            <p>Exported by BlackRoad Dashboards | <a href="https://github.com/blackboxprogramming">GitHub</a></p>
        </footer>
    </div>
</body>
</html>
HTMLFOOT

    log_info "Exported to HTML: $filename"
    echo "$filename"
}

# Export to Markdown
export_markdown() {
    local title="$1"
    local data="$2"
    local filename="${3:-$(generate_filename "report" "md")}"

    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    cat > "$filename" << EOF
# $title

> Generated: $timestamp

---

## Data

\`\`\`json
$(echo "$data" | jq '.' 2>/dev/null || echo "$data")
\`\`\`

---

*Exported by BlackRoad Dashboards*
EOF

    log_info "Exported to Markdown: $filename"
    echo "$filename"
}

# Export to plain text
export_txt() {
    local title="$1"
    local data="$2"
    local filename="${3:-$(generate_filename "report" "txt")}"

    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    cat > "$filename" << EOF
================================================================================
  $title
  Generated: $timestamp
================================================================================

$data

================================================================================
  Exported by BlackRoad Dashboards
================================================================================
EOF

    log_info "Exported to TXT: $filename"
    echo "$filename"
}

#───────────────────────────────────────────────────────────────────────────────
# DATA COLLECTORS
#───────────────────────────────────────────────────────────────────────────────

# Collect system metrics
collect_system_metrics() {
    local cpu=$(get_cpu_usage 2>/dev/null || echo "0")
    local mem=$(get_memory_usage 2>/dev/null || echo "0")
    local disk=$(get_disk_usage "/" 2>/dev/null || echo "0")
    local uptime=$(get_uptime_seconds 2>/dev/null || echo "0")

    cat << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "system": {
        "cpu_usage_percent": $cpu,
        "memory_usage_percent": $mem,
        "disk_usage_percent": $disk,
        "uptime_seconds": $uptime,
        "hostname": "$(hostname)",
        "os": "$(uname -s)",
        "kernel": "$(uname -r)"
    }
}
EOF
}

# Collect network status
collect_network_status() {
    local devices=(
        '{"name":"Lucidia Prime","host":"192.168.4.38"}'
        '{"name":"BlackRoad Pi","host":"192.168.4.64"}'
        '{"name":"Lucidia Alt","host":"192.168.4.99"}'
        '{"name":"iPhone Koder","host":"192.168.4.68"}'
        '{"name":"Codex Infinity","host":"159.65.43.12"}'
    )

    printf '{"timestamp":"%s","devices":[' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    local first=true
    for device_json in "${devices[@]}"; do
        local name=$(echo "$device_json" | jq -r '.name')
        local host=$(echo "$device_json" | jq -r '.host')
        local status="offline"
        local latency="null"

        if ping -c 1 -W 2 "$host" &>/dev/null; then
            status="online"
            latency=$(ping -c 1 "$host" 2>/dev/null | grep -oE 'time=[0-9.]+' | cut -d= -f2)
        fi

        [[ "$first" != "true" ]] && printf ","
        first=false

        printf '{"name":"%s","host":"%s","status":"%s","latency_ms":%s}' \
            "$name" "$host" "$status" "${latency:-null}"
    done

    printf ']}'
}

# Collect crypto prices
collect_crypto_prices() {
    local btc=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true" 2>/dev/null)
    local eth=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd&include_24hr_change=true" 2>/dev/null)
    local sol=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=solana&vs_currencies=usd&include_24hr_change=true" 2>/dev/null)

    cat << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "prices": {
        "bitcoin": $(echo "$btc" | jq '.bitcoin' 2>/dev/null || echo "null"),
        "ethereum": $(echo "$eth" | jq '.ethereum' 2>/dev/null || echo "null"),
        "solana": $(echo "$sol" | jq '.solana' 2>/dev/null || echo "null")
    }
}
EOF
}

# Collect full dashboard snapshot
collect_dashboard_snapshot() {
    local system=$(collect_system_metrics)
    local network=$(collect_network_status)
    local crypto=$(collect_crypto_prices)

    cat << EOF
{
    "snapshot_id": "$(uuidgen 2>/dev/null || echo $$-$(date +%s))",
    "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "system_metrics": $(echo "$system" | jq '.system' 2>/dev/null || echo "{}"),
    "network_status": $(echo "$network" | jq '.devices' 2>/dev/null || echo "[]"),
    "crypto_prices": $(echo "$crypto" | jq '.prices' 2>/dev/null || echo "{}")
}
EOF
}

#───────────────────────────────────────────────────────────────────────────────
# EXPORT UI
#───────────────────────────────────────────────────────────────────────────────

export_ui() {
    clear_screen
    cursor_hide

    printf "${BR_CYAN}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                    📤 BLACKROAD DATA EXPORT                              ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    printf "${TEXT_SECONDARY}Select data to export:${RST}\n\n"
    printf "  ${BR_ORANGE}1.${RST} System Metrics\n"
    printf "  ${BR_ORANGE}2.${RST} Network Status\n"
    printf "  ${BR_ORANGE}3.${RST} Crypto Prices\n"
    printf "  ${BR_ORANGE}4.${RST} Full Dashboard Snapshot\n"
    printf "  ${BR_ORANGE}5.${RST} Custom JSON Data\n"
    printf "\n"

    read -p "$(printf "${BR_CYAN}Enter choice [1-5]: ${RST}")" data_choice

    local data=""
    local title=""

    case "$data_choice" in
        1) data=$(collect_system_metrics); title="System Metrics" ;;
        2) data=$(collect_network_status); title="Network Status" ;;
        3) data=$(collect_crypto_prices); title="Crypto Prices" ;;
        4) data=$(collect_dashboard_snapshot); title="Dashboard Snapshot" ;;
        5)
            printf "\n${TEXT_SECONDARY}Enter JSON data (end with empty line):${RST}\n"
            local input=""
            while IFS= read -r line; do
                [[ -z "$line" ]] && break
                input+="$line"
            done
            data="$input"
            title="Custom Export"
            ;;
        *) log_error "Invalid choice"; return 1 ;;
    esac

    printf "\n${TEXT_SECONDARY}Select export format:${RST}\n\n"
    printf "  ${BR_GREEN}1.${RST} JSON\n"
    printf "  ${BR_GREEN}2.${RST} CSV\n"
    printf "  ${BR_GREEN}3.${RST} HTML Report\n"
    printf "  ${BR_GREEN}4.${RST} Markdown\n"
    printf "  ${BR_GREEN}5.${RST} Plain Text\n"
    printf "  ${BR_GREEN}6.${RST} All Formats\n"
    printf "\n"

    read -p "$(printf "${BR_CYAN}Enter choice [1-6]: ${RST}")" format_choice

    local exported_files=()

    case "$format_choice" in
        1) exported_files+=("$(export_json "$data")") ;;
        2) exported_files+=("$(export_csv "$data")") ;;
        3) exported_files+=("$(export_html "$title" "$data")") ;;
        4) exported_files+=("$(export_markdown "$title" "$data")") ;;
        5) exported_files+=("$(export_txt "$title" "$data")") ;;
        6)
            exported_files+=("$(export_json "$data")")
            exported_files+=("$(export_csv "$data")")
            exported_files+=("$(export_html "$title" "$data")")
            exported_files+=("$(export_markdown "$title" "$data")")
            exported_files+=("$(export_txt "$title" "$data")")
            ;;
        *) log_error "Invalid format"; return 1 ;;
    esac

    printf "\n${BR_GREEN}${BOLD}Export Complete!${RST}\n\n"
    printf "${TEXT_SECONDARY}Files created:${RST}\n"
    for file in "${exported_files[@]}"; do
        printf "  ${BR_CYAN}→${RST} %s\n" "$file"
    done

    printf "\n${TEXT_MUTED}Press any key to continue...${RST}"
    read -rsn1

    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# SCHEDULED EXPORTS
#───────────────────────────────────────────────────────────────────────────────

# Run scheduled export (for cron jobs)
scheduled_export() {
    local export_type="${1:-snapshot}"
    local format="${2:-json}"

    case "$export_type" in
        system)   data=$(collect_system_metrics); title="System Metrics" ;;
        network)  data=$(collect_network_status); title="Network Status" ;;
        crypto)   data=$(collect_crypto_prices); title="Crypto Prices" ;;
        snapshot) data=$(collect_dashboard_snapshot); title="Dashboard Snapshot" ;;
    esac

    case "$format" in
        json)     export_json "$data" ;;
        csv)      export_csv "$data" ;;
        html)     export_html "$title" "$data" ;;
        md)       export_markdown "$title" "$data" ;;
        txt)      export_txt "$title" "$data" ;;
    esac
}

# List recent exports
list_exports() {
    printf "${BR_CYAN}${BOLD}Recent Exports:${RST}\n\n"

    if [[ -d "$EXPORT_DIR" ]]; then
        ls -lt "$EXPORT_DIR" | head -20 | while read -r line; do
            printf "  %s\n" "$line"
        done
    else
        printf "  ${TEXT_MUTED}No exports found.${RST}\n"
    fi
}

# Clean old exports
clean_exports() {
    local days="${1:-7}"

    find "$EXPORT_DIR" -type f -mtime "+$days" -delete 2>/dev/null
    log_info "Cleaned exports older than $days days"
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-ui}" in
        ui)        export_ui ;;
        json)      export_json "${2:-$(collect_dashboard_snapshot)}" "${3:-}" ;;
        csv)       export_csv "${2:-$(collect_dashboard_snapshot)}" "${3:-}" ;;
        html)      export_html "${2:-Dashboard}" "${3:-$(collect_dashboard_snapshot)}" "${4:-}" ;;
        md)        export_markdown "${2:-Dashboard}" "${3:-$(collect_dashboard_snapshot)}" "${4:-}" ;;
        txt)       export_txt "${2:-Dashboard}" "${3:-$(collect_dashboard_snapshot)}" "${4:-}" ;;
        scheduled) scheduled_export "$2" "$3" ;;
        list)      list_exports ;;
        clean)     clean_exports "${2:-7}" ;;
        snapshot)  collect_dashboard_snapshot ;;
        system)    collect_system_metrics ;;
        network)   collect_network_status ;;
        crypto)    collect_crypto_prices ;;
        *)
            printf "Usage: %s [ui|json|csv|html|md|txt|scheduled|list|clean|snapshot]\n" "$0"
            printf "       %s scheduled snapshot json  # For cron jobs\n" "$0"
            printf "       %s clean 30                 # Remove exports older than 30 days\n" "$0"
            ;;
    esac
fi
