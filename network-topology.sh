#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
#  ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
#  ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝
#  ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗
#  ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
#  ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD NETWORK TOPOLOGY VISUALIZER v3.0
#  ASCII Network Mapping, Discovery & Visualization
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# NETWORK DETECTION
#───────────────────────────────────────────────────────────────────────────────

get_local_ip() {
    hostname -I 2>/dev/null | awk '{print $1}' || \
    ip route get 1 2>/dev/null | awk '{print $7}' | head -1 || \
    ifconfig 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1 | awk '{print $2}'
}

get_gateway() {
    ip route 2>/dev/null | grep default | awk '{print $3}' | head -1 || \
    netstat -rn 2>/dev/null | grep -E '^0\.0\.0\.0' | awk '{print $2}' | head -1
}

get_subnet() {
    local ip=$(get_local_ip)
    echo "${ip%.*}.0/24"
}

get_interfaces() {
    ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -v '^lo$'
}

get_interface_info() {
    local iface="$1"
    local ip=$(ip -4 addr show "$iface" 2>/dev/null | grep -oP 'inet \K[\d.]+')
    local mac=$(ip link show "$iface" 2>/dev/null | grep -oP 'link/ether \K[\da-f:]+')
    local state=$(ip link show "$iface" 2>/dev/null | grep -oP 'state \K\w+')
    echo "$ip|$mac|$state"
}

get_dns_servers() {
    grep -E '^nameserver' /etc/resolv.conf 2>/dev/null | awk '{print $2}'
}

get_public_ip() {
    curl -s --connect-timeout 3 https://api.ipify.org 2>/dev/null || \
    curl -s --connect-timeout 3 https://ifconfig.me 2>/dev/null || \
    echo "unknown"
}

#───────────────────────────────────────────────────────────────────────────────
# NETWORK SCANNING
#───────────────────────────────────────────────────────────────────────────────

# Quick ping sweep
ping_sweep() {
    local subnet="${1:-$(get_subnet)}"
    local base="${subnet%.*}"
    local results=()

    for i in {1..254}; do
        local ip="${base}.$i"
        ping -c 1 -W 1 "$ip" &>/dev/null && results+=("$ip") &
    done
    wait

    printf '%s\n' "${results[@]}" | sort -t. -k4 -n
}

# ARP table scan
arp_scan() {
    arp -a 2>/dev/null | grep -E '\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)' | \
    while read -r line; do
        local hostname=$(echo "$line" | awk '{print $1}')
        local ip=$(echo "$line" | grep -oP '\(\K[^\)]+')
        local mac=$(echo "$line" | grep -oP 'at \K[\da-f:]+' || echo "??:??:??:??:??:??")
        local iface=$(echo "$line" | awk '{print $NF}')
        echo "$ip|$mac|$hostname|$iface"
    done
}

# Port scan (basic)
port_scan() {
    local host="$1"
    local ports="${2:-22,80,443,8080,3306,5432,27017,6379}"
    local open_ports=()

    IFS=',' read -ra port_list <<< "$ports"

    for port in "${port_list[@]}"; do
        (echo >/dev/tcp/"$host"/"$port") 2>/dev/null && open_ports+=("$port")
    done

    echo "${open_ports[*]}"
}

# Service detection
detect_service() {
    local port="$1"

    case "$port" in
        22)    echo "SSH" ;;
        80)    echo "HTTP" ;;
        443)   echo "HTTPS" ;;
        21)    echo "FTP" ;;
        25)    echo "SMTP" ;;
        53)    echo "DNS" ;;
        110)   echo "POP3" ;;
        143)   echo "IMAP" ;;
        3306)  echo "MySQL" ;;
        5432)  echo "PostgreSQL" ;;
        27017) echo "MongoDB" ;;
        6379)  echo "Redis" ;;
        8080)  echo "HTTP-Alt" ;;
        8443)  echo "HTTPS-Alt" ;;
        3000)  echo "Node/Dev" ;;
        5000)  echo "Flask" ;;
        *)     echo "Unknown" ;;
    esac
}

#───────────────────────────────────────────────────────────────────────────────
# TOPOLOGY DATA STRUCTURES
#───────────────────────────────────────────────────────────────────────────────

declare -A NETWORK_NODES
declare -A NODE_TYPES
declare -A NODE_CONNECTIONS

# Node types
NODE_TYPE_ROUTER="router"
NODE_TYPE_SERVER="server"
NODE_TYPE_WORKSTATION="workstation"
NODE_TYPE_MOBILE="mobile"
NODE_TYPE_IOT="iot"
NODE_TYPE_UNKNOWN="unknown"

# Add a node to topology
add_node() {
    local id="$1"
    local ip="$2"
    local mac="$3"
    local hostname="$4"
    local type="${5:-$NODE_TYPE_UNKNOWN}"

    NETWORK_NODES[$id]="$ip|$mac|$hostname"
    NODE_TYPES[$id]="$type"
}

# Detect node type from MAC prefix
detect_node_type() {
    local mac="$1"
    local hostname="$2"

    # Check hostname patterns
    [[ "$hostname" == *router* ]] && echo "$NODE_TYPE_ROUTER" && return
    [[ "$hostname" == *gateway* ]] && echo "$NODE_TYPE_ROUTER" && return
    [[ "$hostname" == *server* ]] && echo "$NODE_TYPE_SERVER" && return
    [[ "$hostname" == *iphone* ]] && echo "$NODE_TYPE_MOBILE" && return
    [[ "$hostname" == *android* ]] && echo "$NODE_TYPE_MOBILE" && return
    [[ "$hostname" == *esp* ]] && echo "$NODE_TYPE_IOT" && return

    # Check MAC prefix (OUI) for common manufacturers
    local prefix="${mac:0:8}"

    case "$prefix" in
        "00:0c:29"|"00:50:56"|"00:1c:42") echo "$NODE_TYPE_SERVER" ;;  # VMware/Parallels
        "b8:27:eb"|"dc:a6:32") echo "$NODE_TYPE_IOT" ;;  # Raspberry Pi
        "00:17:88") echo "$NODE_TYPE_IOT" ;;  # Philips IoT
        *) echo "$NODE_TYPE_WORKSTATION" ;;
    esac
}

#───────────────────────────────────────────────────────────────────────────────
# ASCII TOPOLOGY RENDERING
#───────────────────────────────────────────────────────────────────────────────

# Node icons
render_node_icon() {
    local type="$1"
    local status="${2:-up}"

    local color="$BR_GREEN"
    [[ "$status" == "down" ]] && color="$BR_RED"
    [[ "$status" == "unknown" ]] && color="$TEXT_MUTED"

    case "$type" in
        router)
            printf "${color}"
            printf "    ┌───┐    \n"
            printf "  ╔═╡ R ╞═╗  \n"
            printf "  ║ └───┘ ║  \n"
            printf "  ╚═══════╝  \n"
            printf "${RST}"
            ;;
        server)
            printf "${color}"
            printf "  ┌───────┐  \n"
            printf "  │ ═══ S │  \n"
            printf "  │ ═══   │  \n"
            printf "  └───────┘  \n"
            printf "${RST}"
            ;;
        workstation)
            printf "${color}"
            printf "   ┌─────┐   \n"
            printf "   │ ═══ │   \n"
            printf "   └──┬──┘   \n"
            printf "   ═══╧═══   \n"
            printf "${RST}"
            ;;
        mobile)
            printf "${color}"
            printf "    ┌───┐    \n"
            printf "    │   │    \n"
            printf "    │ ○ │    \n"
            printf "    └───┘    \n"
            printf "${RST}"
            ;;
        iot)
            printf "${color}"
            printf "     ╭─╮     \n"
            printf "    ╭╯ ╰╮    \n"
            printf "    │ ● │    \n"
            printf "    ╰───╯    \n"
            printf "${RST}"
            ;;
        *)
            printf "${color}"
            printf "    ┌─┐      \n"
            printf "    │?│      \n"
            printf "    └─┘      \n"
            printf "${RST}"
            ;;
    esac
}

# Render small node for topology map
render_small_node() {
    local type="$1"
    local status="${2:-up}"

    local color="$BR_GREEN"
    [[ "$status" == "down" ]] && color="$BR_RED"

    case "$type" in
        router)      printf "${color}[R]${RST}" ;;
        server)      printf "${color}[S]${RST}" ;;
        workstation) printf "${color}[W]${RST}" ;;
        mobile)      printf "${color}[M]${RST}" ;;
        iot)         printf "${color}[I]${RST}" ;;
        internet)    printf "${BR_CYAN}[☁]${RST}" ;;
        *)           printf "${color}[?]${RST}" ;;
    esac
}

# Render connection line
render_connection() {
    local direction="$1"  # h (horizontal), v (vertical), tr, tl, br, bl

    case "$direction" in
        h)  printf "════" ;;
        v)  printf "║" ;;
        tr) printf "╗" ;;
        tl) printf "╔" ;;
        br) printf "╝" ;;
        bl) printf "╚" ;;
        t)  printf "╦" ;;
        b)  printf "╩" ;;
        l)  printf "╠" ;;
        r)  printf "╣" ;;
        x)  printf "╬" ;;
        *)  printf " " ;;
    esac
}

#───────────────────────────────────────────────────────────────────────────────
# STAR TOPOLOGY (Common Home/Office Network)
#───────────────────────────────────────────────────────────────────────────────

render_star_topology() {
    local gateway=$(get_gateway)
    local local_ip=$(get_local_ip)
    local public_ip=$(get_public_ip)

    clear_screen

    printf "${BR_CYAN}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                      🌐 NETWORK TOPOLOGY - STAR                              ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    # Internet cloud
    printf "                              ${BR_CYAN}╭──────────────╮${RST}\n"
    printf "                              ${BR_CYAN}│   INTERNET   │${RST}\n"
    printf "                              ${BR_CYAN}│   %s  │${RST}\n" "${public_ip:0:12}"
    printf "                              ${BR_CYAN}╰──────┬───────╯${RST}\n"
    printf "                                     ${TEXT_MUTED}║${RST}\n"
    printf "                                     ${TEXT_MUTED}║${RST}\n"

    # Router/Gateway
    printf "                              ${BR_ORANGE}┌───────────────┐${RST}\n"
    printf "                              ${BR_ORANGE}│    ROUTER     │${RST}\n"
    printf "                              ${BR_ORANGE}│   %s   │${RST}\n" "${gateway:-0.0.0.0}"
    printf "                              ${BR_ORANGE}└───────┬───────┘${RST}\n"
    printf "                   ${TEXT_MUTED}╔══════════════╬══════════════╗${RST}\n"
    printf "                   ${TEXT_MUTED}║              ║              ║${RST}\n"

    # Discover devices
    local devices=()
    while IFS='|' read -r ip mac hostname iface; do
        [[ -n "$ip" ]] && devices+=("$ip|$mac|$hostname")
    done < <(arp_scan 2>/dev/null | head -6)

    # Render devices in a row
    local device_count=${#devices[@]}
    local positions=(0 1 2 3 4 5)

    for idx in "${!devices[@]}"; do
        IFS='|' read -r ip mac hostname <<< "${devices[$idx]}"
        local type=$(detect_node_type "$mac" "$hostname")

        local spacing=$((idx * 12 + 5))

        if [[ "$ip" == "$local_ip" ]]; then
            printf "           ${BR_GREEN}┌─────────┐${RST}"
        else
            printf "           ${BR_PURPLE}┌─────────┐${RST}"
        fi
    done
    printf "\n"

    for idx in "${!devices[@]}"; do
        IFS='|' read -r ip mac hostname <<< "${devices[$idx]}"

        if [[ "$ip" == "$local_ip" ]]; then
            printf "           ${BR_GREEN}│ THIS PC │${RST}"
        else
            printf "           ${BR_PURPLE}│ %-7s │${RST}" "${hostname:0:7}"
        fi
    done
    printf "\n"

    for idx in "${!devices[@]}"; do
        IFS='|' read -r ip mac hostname <<< "${devices[$idx]}"

        if [[ "$ip" == "$local_ip" ]]; then
            printf "           ${BR_GREEN}│%-9s│${RST}" "${ip:0:9}"
        else
            printf "           ${BR_PURPLE}│%-9s│${RST}" "${ip:0:9}"
        fi
    done
    printf "\n"

    for idx in "${!devices[@]}"; do
        if [[ "$ip" == "$local_ip" ]]; then
            printf "           ${BR_GREEN}└─────────┘${RST}"
        else
            printf "           ${BR_PURPLE}└─────────┘${RST}"
        fi
    done
    printf "\n\n"

    # Legend
    printf "${TEXT_MUTED}Legend: ${BR_GREEN}● This Device${RST}  ${BR_PURPLE}● Network Device${RST}  ${BR_ORANGE}● Router/Gateway${RST}  ${BR_CYAN}● Internet${RST}\n"
}

#───────────────────────────────────────────────────────────────────────────────
# DETAILED DEVICE VIEW
#───────────────────────────────────────────────────────────────────────────────

render_device_details() {
    local ip="$1"

    printf "\n${BR_CYAN}╔════════════════════════════════════════════════════════════╗${RST}\n"
    printf "${BR_CYAN}║${RST} ${BOLD}Device Details: %s${RST}%*s${BR_CYAN}║${RST}\n" "$ip" $((42 - ${#ip})) ""
    printf "${BR_CYAN}╠════════════════════════════════════════════════════════════╣${RST}\n"

    # Get MAC from ARP
    local mac=$(arp -n "$ip" 2>/dev/null | grep -oP '[\da-f:]{17}' | head -1)
    printf "${BR_CYAN}║${RST}  MAC Address: %-42s ${BR_CYAN}║${RST}\n" "${mac:-Unknown}"

    # Hostname
    local hostname=$(host "$ip" 2>/dev/null | awk '/domain name pointer/ {print $5}' | sed 's/\.$//')
    printf "${BR_CYAN}║${RST}  Hostname:    %-42s ${BR_CYAN}║${RST}\n" "${hostname:-Unknown}"

    # Ping
    local ping_result=$(ping -c 1 -W 1 "$ip" 2>/dev/null | grep -oP 'time=\K[\d.]+' || echo "timeout")
    printf "${BR_CYAN}║${RST}  Latency:     %-42s ${BR_CYAN}║${RST}\n" "${ping_result}ms"

    # Open ports
    printf "${BR_CYAN}║${RST}  Open Ports:  "
    local ports=$(port_scan "$ip" "22,80,443,8080,3000,5000,3306,5432")
    if [[ -n "$ports" ]]; then
        printf "%-42s ${BR_CYAN}║${RST}\n" "$ports"
    else
        printf "%-42s ${BR_CYAN}║${RST}\n" "None detected"
    fi

    printf "${BR_CYAN}╚════════════════════════════════════════════════════════════╝${RST}\n"
}

#───────────────────────────────────────────────────────────────────────────────
# INTERFACE STATUS
#───────────────────────────────────────────────────────────────────────────────

render_interface_status() {
    printf "${BOLD}Network Interfaces${RST}\n\n"

    printf "%-15s %-18s %-20s %-10s\n" "INTERFACE" "IP ADDRESS" "MAC ADDRESS" "STATE"
    printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────────────────────────────────────"

    for iface in $(get_interfaces); do
        IFS='|' read -r ip mac state <<< "$(get_interface_info "$iface")"

        local state_color="$BR_GREEN"
        [[ "$state" != "UP" ]] && state_color="$BR_RED"

        printf "%-15s " "$iface"
        printf "${BR_CYAN}%-18s${RST} " "${ip:-N/A}"
        printf "${TEXT_MUTED}%-20s${RST} " "${mac:-N/A}"
        printf "${state_color}%-10s${RST}\n" "${state:-DOWN}"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# CONNECTION MONITOR
#───────────────────────────────────────────────────────────────────────────────

render_connections() {
    printf "${BOLD}Active Connections${RST}\n\n"

    printf "%-8s %-25s %-25s %-12s\n" "PROTO" "LOCAL" "REMOTE" "STATE"
    printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────────────────────────────────────────────"

    netstat -tunapl 2>/dev/null | grep -E '^(tcp|udp)' | head -15 | while read -r proto recv send local remote state pid; do
        local state_color="$TEXT_MUTED"
        case "$state" in
            ESTABLISHED) state_color="$BR_GREEN" ;;
            LISTEN)      state_color="$BR_CYAN" ;;
            TIME_WAIT)   state_color="$BR_YELLOW" ;;
            CLOSE_WAIT)  state_color="$BR_RED" ;;
        esac

        printf "%-8s " "$proto"
        printf "${BR_CYAN}%-25s${RST} " "${local:0:25}"
        printf "${BR_PURPLE}%-25s${RST} " "${remote:0:25}"
        printf "${state_color}%-12s${RST}\n" "${state:0:12}"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# BANDWIDTH MONITOR
#───────────────────────────────────────────────────────────────────────────────

monitor_bandwidth() {
    local iface="${1:-$(get_interfaces | head -1)}"
    local interval="${2:-1}"

    printf "${BOLD}Bandwidth Monitor: %s${RST}\n\n" "$iface"

    local rx_prev=$(cat /sys/class/net/"$iface"/statistics/rx_bytes 2>/dev/null || echo 0)
    local tx_prev=$(cat /sys/class/net/"$iface"/statistics/tx_bytes 2>/dev/null || echo 0)

    for ((i=0; i<10; i++)); do
        sleep "$interval"

        local rx_curr=$(cat /sys/class/net/"$iface"/statistics/rx_bytes 2>/dev/null || echo 0)
        local tx_curr=$(cat /sys/class/net/"$iface"/statistics/tx_bytes 2>/dev/null || echo 0)

        local rx_rate=$(( (rx_curr - rx_prev) / 1024 ))
        local tx_rate=$(( (tx_curr - tx_prev) / 1024 ))

        printf "\r  ${BR_GREEN}↓${RST} RX: %6d KB/s  ${BR_RED}↑${RST} TX: %6d KB/s  " "$rx_rate" "$tx_rate"

        # Simple bar
        local rx_bar=$((rx_rate / 100))
        local tx_bar=$((tx_rate / 100))
        [[ $rx_bar -gt 20 ]] && rx_bar=20
        [[ $tx_bar -gt 20 ]] && tx_bar=20

        printf "${BR_GREEN}"
        printf "%0.s█" $(seq 1 $rx_bar 2>/dev/null) || true
        printf "${RST}"
        printf " "
        printf "${BR_RED}"
        printf "%0.s█" $(seq 1 $tx_bar 2>/dev/null) || true
        printf "${RST}"

        rx_prev=$rx_curr
        tx_prev=$tx_curr
    done
    printf "\n"
}

#───────────────────────────────────────────────────────────────────────────────
# DNS LOOKUP
#───────────────────────────────────────────────────────────────────────────────

dns_lookup() {
    local domain="$1"

    printf "${BOLD}DNS Lookup: %s${RST}\n\n" "$domain"

    printf "${BR_CYAN}A Records:${RST}\n"
    dig +short A "$domain" 2>/dev/null | while read -r ip; do
        printf "  %s\n" "$ip"
    done

    printf "\n${BR_CYAN}AAAA Records:${RST}\n"
    dig +short AAAA "$domain" 2>/dev/null | while read -r ip; do
        printf "  %s\n" "$ip"
    done

    printf "\n${BR_CYAN}MX Records:${RST}\n"
    dig +short MX "$domain" 2>/dev/null | while read -r mx; do
        printf "  %s\n" "$mx"
    done

    printf "\n${BR_CYAN}NS Records:${RST}\n"
    dig +short NS "$domain" 2>/dev/null | while read -r ns; do
        printf "  %s\n" "$ns"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# TRACEROUTE VISUALIZATION
#───────────────────────────────────────────────────────────────────────────────

visual_traceroute() {
    local target="$1"
    local max_hops="${2:-15}"

    printf "${BOLD}Traceroute to %s${RST}\n\n" "$target"

    local hop=0
    traceroute -n -m "$max_hops" -w 2 "$target" 2>/dev/null | while read -r line; do
        if [[ "$line" == *"traceroute"* ]]; then
            continue
        fi

        ((hop++))

        local ip=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
        local time=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+ ms' | head -1)

        if [[ -n "$ip" ]]; then
            printf "  ${BR_CYAN}%2d${RST} ──▶ ${BR_GREEN}%-15s${RST} " "$hop" "$ip"

            # Latency bar
            local ms=${time%% *}
            local bar_len=$(printf "%.0f" "$(echo "$ms / 10" | bc -l 2>/dev/null || echo 1)")
            [[ $bar_len -gt 30 ]] && bar_len=30
            [[ $bar_len -lt 1 ]] && bar_len=1

            local bar_color="$BR_GREEN"
            [[ ${ms%.*} -gt 50 ]] && bar_color="$BR_YELLOW"
            [[ ${ms%.*} -gt 100 ]] && bar_color="$BR_RED"

            printf "%s" "$bar_color"
            printf "%0.s█" $(seq 1 $bar_len 2>/dev/null) || true
            printf "${RST} %s\n" "$time"
        else
            printf "  ${BR_CYAN}%2d${RST} ──▶ ${TEXT_MUTED}*          timeout${RST}\n" "$hop"
        fi
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

render_network_dashboard() {
    clear_screen
    cursor_hide

    printf "${BR_CYAN}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                     🌐 NETWORK TOPOLOGY VISUALIZER                           ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    # Network summary
    local local_ip=$(get_local_ip)
    local gateway=$(get_gateway)
    local public_ip=$(get_public_ip)
    local dns=$(get_dns_servers | head -1)

    printf "  ${BOLD}Local IP:${RST}   ${BR_GREEN}%s${RST}  " "$local_ip"
    printf "${BOLD}Gateway:${RST}    ${BR_ORANGE}%s${RST}  " "$gateway"
    printf "${BOLD}Public IP:${RST} ${BR_CYAN}%s${RST}\n" "$public_ip"
    printf "  ${BOLD}DNS:${RST}        ${TEXT_MUTED}%s${RST}\n\n" "$dns"

    # Interface status
    render_interface_status
    printf "\n"

    # Quick device scan
    printf "${BOLD}Discovered Devices (ARP)${RST}\n\n"
    printf "%-18s %-20s %-20s\n" "IP ADDRESS" "MAC ADDRESS" "HOSTNAME"
    printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────────────────────────────────"

    arp_scan 2>/dev/null | head -8 | while IFS='|' read -r ip mac hostname iface; do
        [[ -z "$ip" ]] && continue

        local type=$(detect_node_type "$mac" "$hostname")

        printf "  "
        render_small_node "$type"
        printf " ${BR_CYAN}%-15s${RST} " "$ip"
        printf "${TEXT_MUTED}%-20s${RST} " "$mac"
        printf "${TEXT_SECONDARY}%-20s${RST}\n" "${hostname:0:20}"
    done

    printf "\n${TEXT_MUTED}─────────────────────────────────────────────────────────────────────────────${RST}\n"
    printf "  ${TEXT_SECONDARY}[t]opology  [s]can  [c]onnections  [b]andwidth  [d]ns  [r]efresh  [q]uit${RST}\n"
}

network_dashboard_loop() {
    while true; do
        render_network_dashboard

        if read -rsn1 -t 5 key 2>/dev/null; then
            case "$key" in
                t|T)
                    render_star_topology
                    printf "\n${TEXT_MUTED}Press any key...${RST}"
                    read -rsn1
                    ;;
                s|S)
                    printf "\n${BR_CYAN}Scanning network...${RST}\n"
                    ping_sweep | while read -r ip; do
                        printf "  Found: %s\n" "$ip"
                    done
                    printf "${TEXT_MUTED}Press any key...${RST}"
                    read -rsn1
                    ;;
                c|C)
                    clear_screen
                    render_connections
                    printf "\n${TEXT_MUTED}Press any key...${RST}"
                    read -rsn1
                    ;;
                b|B)
                    clear_screen
                    monitor_bandwidth
                    printf "\n${TEXT_MUTED}Press any key...${RST}"
                    read -rsn1
                    ;;
                d|D)
                    printf "\n${BR_CYAN}Domain to lookup: ${RST}"
                    cursor_show
                    read -r domain
                    cursor_hide
                    [[ -n "$domain" ]] && dns_lookup "$domain"
                    printf "\n${TEXT_MUTED}Press any key...${RST}"
                    read -rsn1
                    ;;
                r|R) continue ;;
                q|Q) break ;;
            esac
        fi
    done

    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-dashboard}" in
        dashboard)   network_dashboard_loop ;;
        topology)    render_star_topology ;;
        interfaces)  render_interface_status ;;
        connections) render_connections ;;
        scan)        ping_sweep "${2:-}" ;;
        arp)         arp_scan ;;
        ports)       port_scan "$2" "${3:-22,80,443,8080}" ;;
        bandwidth)   monitor_bandwidth "$2" ;;
        dns)         dns_lookup "$2" ;;
        trace)       visual_traceroute "$2" ;;
        device)      render_device_details "$2" ;;
        *)
            printf "Usage: %s [dashboard|topology|interfaces|connections|scan|arp|ports|bandwidth|dns|trace|device]\n" "$0"
            ;;
    esac
fi
