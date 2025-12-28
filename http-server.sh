#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██╗  ██╗████████╗████████╗██████╗     ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗
#  ██║  ██║╚══██╔══╝╚══██╔══╝██╔══██╗    ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗
#  ███████║   ██║      ██║   ██████╔╝    ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝
#  ██╔══██║   ██║      ██║   ██╔═══╝     ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗
#  ██║  ██║   ██║      ██║   ██║         ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║
#  ╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝         ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD HTTP DASHBOARD SERVER v3.0
#  Real-time Web Dashboard with Live Metrics API
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

HTTP_PORT="${HTTP_PORT:-8888}"
HTTP_HOST="${HTTP_HOST:-0.0.0.0}"
HTTP_ROOT="${SCRIPT_DIR}/www"
HTTP_LOG="${BLACKROAD_LOGS:-/tmp}/http-server.log"

mkdir -p "$HTTP_ROOT" 2>/dev/null

#───────────────────────────────────────────────────────────────────────────────
# API ENDPOINTS
#───────────────────────────────────────────────────────────────────────────────

# Get system metrics
api_metrics() {
    local cpu=$(get_cpu_usage 2>/dev/null || echo "0")
    local mem=$(get_memory_usage 2>/dev/null || echo "0")
    local disk=$(get_disk_usage "/" 2>/dev/null || echo "0")
    local uptime=$(get_uptime_seconds 2>/dev/null || echo "0")
    local load=$(cat /proc/loadavg 2>/dev/null | awk '{print $1}' || echo "0")

    cat << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "cpu": {
        "usage": $cpu,
        "cores": $(nproc 2>/dev/null || echo 1)
    },
    "memory": {
        "usage": $mem,
        "total_mb": $(free -m 2>/dev/null | awk '/Mem:/ {print $2}' || echo 0),
        "used_mb": $(free -m 2>/dev/null | awk '/Mem:/ {print $3}' || echo 0)
    },
    "disk": {
        "usage": $disk,
        "path": "/"
    },
    "system": {
        "uptime_seconds": $uptime,
        "load_average": $load,
        "hostname": "$(hostname)",
        "os": "$(uname -s)",
        "kernel": "$(uname -r)"
    }
}
EOF
}

# Get network status
api_network() {
    local devices=(
        '{"name":"Lucidia Prime","host":"192.168.4.38"}'
        '{"name":"BlackRoad Pi","host":"192.168.4.64"}'
        '{"name":"Codex VPS","host":"159.65.43.12"}'
    )

    printf '{"timestamp":"%s","devices":[' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    local first=true
    for dev in "${devices[@]}"; do
        local host=$(echo "$dev" | grep -oE '"host":"[^"]+"' | cut -d'"' -f4)
        local name=$(echo "$dev" | grep -oE '"name":"[^"]+"' | cut -d'"' -f4)

        local status="offline"
        ping -c 1 -W 1 "$host" &>/dev/null && status="online"

        [[ "$first" != "true" ]] && printf ","
        first=false
        printf '{"name":"%s","host":"%s","status":"%s"}' "$name" "$host" "$status"
    done

    printf ']}'
}

# Get crypto prices
api_crypto() {
    local btc=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true" 2>/dev/null)
    local eth=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd&include_24hr_change=true" 2>/dev/null)
    local sol=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=solana&vs_currencies=usd&include_24hr_change=true" 2>/dev/null)

    cat << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "prices": {
        "bitcoin": $(echo "$btc" | grep -oE '"bitcoin":\{[^}]+\}' || echo '{"usd":0}'),
        "ethereum": $(echo "$eth" | grep -oE '"ethereum":\{[^}]+\}' || echo '{"usd":0}'),
        "solana": $(echo "$sol" | grep -oE '"solana":\{[^}]+\}' || echo '{"usd":0}')
    }
}
EOF
}

# Get all data
api_dashboard() {
    local metrics=$(api_metrics)
    local network=$(api_network)

    cat << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "metrics": $metrics,
    "network": $network,
    "version": "3.0.0"
}
EOF
}

#───────────────────────────────────────────────────────────────────────────────
# HTML TEMPLATES
#───────────────────────────────────────────────────────────────────────────────

generate_dashboard_html() {
    cat << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BlackRoad Dashboard</title>
    <style>
        :root {
            --bg-primary: #0a0a14;
            --bg-secondary: #12121f;
            --bg-card: #1a1a2e;
            --text-primary: #ffffff;
            --text-secondary: #a0a0b0;
            --accent-cyan: #00d4ff;
            --accent-pink: #e91e8c;
            --accent-orange: #f7931a;
            --accent-green: #14f195;
            --accent-purple: #9945ff;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'SF Mono', 'Monaco', monospace;
            background: var(--bg-primary);
            color: var(--text-primary);
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 1400px; margin: 0 auto; }
        header {
            text-align: center;
            padding: 30px;
            background: linear-gradient(135deg, var(--accent-pink), var(--accent-purple), var(--accent-cyan));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            font-size: 2.5rem;
            font-weight: bold;
            margin-bottom: 30px;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
        .card {
            background: var(--bg-card);
            border-radius: 12px;
            padding: 20px;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .card h2 {
            color: var(--accent-cyan);
            margin-bottom: 15px;
            font-size: 1.1rem;
        }
        .metric {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin: 10px 0;
        }
        .metric-label { color: var(--text-secondary); }
        .metric-value { font-size: 1.5rem; font-weight: bold; }
        .progress-bar {
            width: 100%;
            height: 8px;
            background: rgba(255,255,255,0.1);
            border-radius: 4px;
            margin-top: 5px;
            overflow: hidden;
        }
        .progress-fill {
            height: 100%;
            border-radius: 4px;
            transition: width 0.5s ease;
        }
        .status-online { color: var(--accent-green); }
        .status-offline { color: #ff5252; }
        .refresh-btn {
            background: var(--accent-purple);
            border: none;
            color: white;
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            margin-bottom: 20px;
        }
        .refresh-btn:hover { opacity: 0.8; }
        #last-update { color: var(--text-secondary); font-size: 0.9rem; }
    </style>
</head>
<body>
    <div class="container">
        <header>BLACKROAD DASHBOARD</header>
        <button class="refresh-btn" onclick="fetchData()">Refresh</button>
        <span id="last-update">Loading...</span>

        <div class="grid">
            <div class="card">
                <h2>CPU</h2>
                <div class="metric">
                    <span class="metric-label">Usage</span>
                    <span class="metric-value" id="cpu-value">--%</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill" id="cpu-bar" style="width: 0%; background: var(--accent-cyan);"></div>
                </div>
            </div>

            <div class="card">
                <h2>Memory</h2>
                <div class="metric">
                    <span class="metric-label">Usage</span>
                    <span class="metric-value" id="mem-value">--%</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill" id="mem-bar" style="width: 0%; background: var(--accent-pink);"></div>
                </div>
            </div>

            <div class="card">
                <h2>Disk</h2>
                <div class="metric">
                    <span class="metric-label">Usage</span>
                    <span class="metric-value" id="disk-value">--%</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill" id="disk-bar" style="width: 0%; background: var(--accent-orange);"></div>
                </div>
            </div>

            <div class="card">
                <h2>System</h2>
                <div class="metric">
                    <span class="metric-label">Hostname</span>
                    <span id="hostname">--</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Uptime</span>
                    <span id="uptime">--</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Load</span>
                    <span id="load">--</span>
                </div>
            </div>

            <div class="card" style="grid-column: span 2;">
                <h2>Network Devices</h2>
                <div id="devices"></div>
            </div>
        </div>
    </div>

    <script>
        async function fetchData() {
            try {
                const res = await fetch('/api/dashboard');
                const data = await res.json();

                // Update metrics
                const cpu = data.metrics.cpu.usage;
                const mem = data.metrics.memory.usage;
                const disk = data.metrics.disk.usage;

                document.getElementById('cpu-value').textContent = cpu + '%';
                document.getElementById('cpu-bar').style.width = cpu + '%';
                document.getElementById('cpu-bar').style.background = cpu > 80 ? '#ff5252' : 'var(--accent-cyan)';

                document.getElementById('mem-value').textContent = mem + '%';
                document.getElementById('mem-bar').style.width = mem + '%';
                document.getElementById('mem-bar').style.background = mem > 80 ? '#ff5252' : 'var(--accent-pink)';

                document.getElementById('disk-value').textContent = disk + '%';
                document.getElementById('disk-bar').style.width = disk + '%';

                document.getElementById('hostname').textContent = data.metrics.system.hostname;
                document.getElementById('uptime').textContent = formatUptime(data.metrics.system.uptime_seconds);
                document.getElementById('load').textContent = data.metrics.system.load_average;

                // Update devices
                const devicesHtml = data.network.devices.map(d =>
                    `<div class="metric">
                        <span class="metric-label">${d.name}</span>
                        <span class="${d.status === 'online' ? 'status-online' : 'status-offline'}">
                            ${d.status === 'online' ? '● Online' : '○ Offline'}
                        </span>
                    </div>`
                ).join('');
                document.getElementById('devices').innerHTML = devicesHtml;

                document.getElementById('last-update').textContent = 'Last updated: ' + new Date().toLocaleTimeString();
            } catch (e) {
                console.error('Fetch error:', e);
            }
        }

        function formatUptime(seconds) {
            const days = Math.floor(seconds / 86400);
            const hours = Math.floor((seconds % 86400) / 3600);
            const mins = Math.floor((seconds % 3600) / 60);
            return `${days}d ${hours}h ${mins}m`;
        }

        fetchData();
        setInterval(fetchData, 5000);
    </script>
</body>
</html>
HTML
}

#───────────────────────────────────────────────────────────────────────────────
# HTTP SERVER
#───────────────────────────────────────────────────────────────────────────────

# Parse HTTP request
parse_request() {
    local request="$1"
    local method=$(echo "$request" | head -1 | awk '{print $1}')
    local path=$(echo "$request" | head -1 | awk '{print $2}')

    echo "$method $path"
}

# Send HTTP response
send_response() {
    local status="$1"
    local content_type="$2"
    local body="$3"
    local content_length=${#body}

    printf "HTTP/1.1 %s\r\n" "$status"
    printf "Content-Type: %s\r\n" "$content_type"
    printf "Content-Length: %d\r\n" "$content_length"
    printf "Access-Control-Allow-Origin: *\r\n"
    printf "Connection: close\r\n"
    printf "\r\n"
    printf "%s" "$body"
}

# Handle request
handle_request() {
    local request=""
    local line

    # Read request headers
    while IFS= read -r line; do
        line="${line%$'\r'}"
        [[ -z "$line" ]] && break
        request+="$line"$'\n'
    done

    local method_path=$(parse_request "$request")
    local method="${method_path%% *}"
    local path="${method_path#* }"

    # Log request
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $method $path" >> "$HTTP_LOG"

    # Route request
    case "$path" in
        /|/index.html)
            local html=$(generate_dashboard_html)
            send_response "200 OK" "text/html; charset=utf-8" "$html"
            ;;
        /api/metrics)
            local json=$(api_metrics)
            send_response "200 OK" "application/json" "$json"
            ;;
        /api/network)
            local json=$(api_network)
            send_response "200 OK" "application/json" "$json"
            ;;
        /api/crypto)
            local json=$(api_crypto)
            send_response "200 OK" "application/json" "$json"
            ;;
        /api/dashboard)
            local json=$(api_dashboard)
            send_response "200 OK" "application/json" "$json"
            ;;
        /health)
            send_response "200 OK" "application/json" '{"status":"healthy"}'
            ;;
        *)
            send_response "404 Not Found" "application/json" '{"error":"Not Found"}'
            ;;
    esac
}

# Start server using netcat
start_server_nc() {
    log_info "Starting HTTP server on http://$HTTP_HOST:$HTTP_PORT"
    printf "${BR_GREEN}${BOLD}BlackRoad HTTP Server v3.0${RST}\n"
    printf "${TEXT_SECONDARY}Listening on http://%s:%s${RST}\n\n" "$HTTP_HOST" "$HTTP_PORT"
    printf "${TEXT_MUTED}Endpoints:${RST}\n"
    printf "  ${BR_CYAN}/              ${TEXT_SECONDARY}- Dashboard UI${RST}\n"
    printf "  ${BR_CYAN}/api/metrics   ${TEXT_SECONDARY}- System metrics${RST}\n"
    printf "  ${BR_CYAN}/api/network   ${TEXT_SECONDARY}- Network status${RST}\n"
    printf "  ${BR_CYAN}/api/crypto    ${TEXT_SECONDARY}- Crypto prices${RST}\n"
    printf "  ${BR_CYAN}/api/dashboard ${TEXT_SECONDARY}- All data${RST}\n"
    printf "  ${BR_CYAN}/health        ${TEXT_SECONDARY}- Health check${RST}\n"
    printf "\n${TEXT_MUTED}Press Ctrl+C to stop${RST}\n\n"

    while true; do
        # Use netcat or socat
        if command -v nc &>/dev/null; then
            nc -l -p "$HTTP_PORT" -c "$(realpath "$0") handle" 2>/dev/null || \
            nc -l "$HTTP_PORT" -e "$(realpath "$0") handle" 2>/dev/null || \
            {
                # Fallback: simple nc without -c/-e
                { handle_request | nc -l -p "$HTTP_PORT" -q 1; } 2>/dev/null
            }
        elif command -v socat &>/dev/null; then
            socat TCP-LISTEN:"$HTTP_PORT",reuseaddr,fork EXEC:"$(realpath "$0") handle"
        else
            log_error "Neither nc nor socat found. Install netcat or socat."
            exit 1
        fi
    done
}

# Simple bash-only server (slower but more compatible)
start_server_bash() {
    log_info "Starting HTTP server (bash mode) on port $HTTP_PORT"

    # Create named pipe
    local pipe="/tmp/blackroad_http_$$"
    mkfifo "$pipe" 2>/dev/null

    trap "rm -f $pipe; exit" INT TERM EXIT

    while true; do
        cat "$pipe" | handle_request | nc -l -p "$HTTP_PORT" > "$pipe" 2>/dev/null
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-start}" in
        start)
            trap "echo; log_info 'Server stopped'; exit 0" INT TERM
            start_server_nc
            ;;
        handle)
            handle_request
            ;;
        api)
            case "$2" in
                metrics)   api_metrics ;;
                network)   api_network ;;
                crypto)    api_crypto ;;
                dashboard) api_dashboard ;;
            esac
            ;;
        *)
            printf "Usage: %s [start|api <endpoint>]\n" "$0"
            printf "       %s start           # Start HTTP server\n" "$0"
            printf "       %s api metrics     # Get metrics JSON\n" "$0"
            ;;
    esac
fi
