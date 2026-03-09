#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██████╗  ██████╗  ██████╗██╗  ██╗███████╗██████╗     ███████╗██╗     ███████╗███████╗████████╗
#  ██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗    ██╔════╝██║     ██╔════╝██╔════╝╚══██╔══╝
#  ██║  ██║██║   ██║██║     █████╔╝ █████╗  ██████╔╝    █████╗  ██║     █████╗  █████╗     ██║
#  ██║  ██║██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗    ██╔══╝  ██║     ██╔══╝  ██╔══╝     ██║
#  ██████╔╝╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║    ██║     ███████╗███████╗███████╗   ██║
#  ╚═════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚══════╝╚══════╝╚══════╝   ╚═╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD DOCKER FLEET MANAGER v3.0
#  Container Orchestration, Monitoring & Management Dashboard
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# DOCKER DETECTION
#───────────────────────────────────────────────────────────────────────────────

check_docker() {
    if ! command -v docker &>/dev/null; then
        printf "${BR_RED}Docker is not installed!${RST}\n"
        return 1
    fi

    if ! docker info &>/dev/null; then
        printf "${BR_RED}Docker daemon is not running!${RST}\n"
        return 1
    fi

    return 0
}

#───────────────────────────────────────────────────────────────────────────────
# CONTAINER OPERATIONS
#───────────────────────────────────────────────────────────────────────────────

get_containers() {
    local filter="${1:-all}"  # all, running, stopped

    case "$filter" in
        running) docker ps --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}' 2>/dev/null ;;
        stopped) docker ps -a --filter "status=exited" --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}' 2>/dev/null ;;
        *)       docker ps -a --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}' 2>/dev/null ;;
    esac
}

get_container_count() {
    docker ps -q 2>/dev/null | wc -l | tr -d ' '
}

get_container_total() {
    docker ps -aq 2>/dev/null | wc -l | tr -d ' '
}

get_container_stats() {
    local container_id="$1"
    docker stats --no-stream --format '{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}|{{.NetIO}}|{{.BlockIO}}' "$container_id" 2>/dev/null
}

get_container_logs() {
    local container_id="$1"
    local lines="${2:-50}"
    docker logs --tail "$lines" "$container_id" 2>&1
}

get_container_inspect() {
    local container_id="$1"
    docker inspect "$container_id" 2>/dev/null
}

#───────────────────────────────────────────────────────────────────────────────
# IMAGE OPERATIONS
#───────────────────────────────────────────────────────────────────────────────

get_images() {
    docker images --format '{{.ID}}|{{.Repository}}|{{.Tag}}|{{.Size}}|{{.CreatedAt}}' 2>/dev/null
}

get_image_count() {
    docker images -q 2>/dev/null | wc -l | tr -d ' '
}

get_dangling_images() {
    docker images -f "dangling=true" -q 2>/dev/null | wc -l | tr -d ' '
}

#───────────────────────────────────────────────────────────────────────────────
# VOLUME & NETWORK OPERATIONS
#───────────────────────────────────────────────────────────────────────────────

get_volumes() {
    docker volume ls --format '{{.Name}}|{{.Driver}}|{{.Mountpoint}}' 2>/dev/null
}

get_volume_count() {
    docker volume ls -q 2>/dev/null | wc -l | tr -d ' '
}

get_networks() {
    docker network ls --format '{{.ID}}|{{.Name}}|{{.Driver}}|{{.Scope}}' 2>/dev/null
}

get_network_count() {
    docker network ls -q 2>/dev/null | wc -l | tr -d ' '
}

#───────────────────────────────────────────────────────────────────────────────
# DOCKER COMPOSE
#───────────────────────────────────────────────────────────────────────────────

detect_compose_files() {
    local search_dir="${1:-.}"
    find "$search_dir" -maxdepth 3 \( -name "docker-compose.yml" -o -name "docker-compose.yaml" -o -name "compose.yml" -o -name "compose.yaml" \) 2>/dev/null
}

get_compose_services() {
    local compose_file="$1"
    if [[ -f "$compose_file" ]]; then
        grep -E "^  [a-zA-Z0-9_-]+:" "$compose_file" 2>/dev/null | sed 's/://g' | awk '{print $1}'
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# RESOURCE USAGE
#───────────────────────────────────────────────────────────────────────────────

get_docker_disk_usage() {
    docker system df 2>/dev/null
}

get_docker_disk_usage_json() {
    docker system df --format '{{json .}}' 2>/dev/null
}

calculate_total_resources() {
    local total_cpu=0
    local total_mem=0

    while IFS='|' read -r cpu mem_usage mem_perc net block; do
        # Extract numeric CPU percentage
        local cpu_num=${cpu%\%}
        cpu_num=${cpu_num//[^0-9.]/}

        # Extract numeric memory percentage
        local mem_num=${mem_perc%\%}
        mem_num=${mem_num//[^0-9.]/}

        total_cpu=$(echo "$total_cpu + ${cpu_num:-0}" | bc 2>/dev/null || echo "$total_cpu")
        total_mem=$(echo "$total_mem + ${mem_num:-0}" | bc 2>/dev/null || echo "$total_mem")
    done < <(docker stats --no-stream --format '{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}|{{.NetIO}}|{{.BlockIO}}' 2>/dev/null)

    printf "%.1f|%.1f" "$total_cpu" "$total_mem"
}

#───────────────────────────────────────────────────────────────────────────────
# CONTAINER ACTIONS
#───────────────────────────────────────────────────────────────────────────────

container_start() {
    local container="$1"
    docker start "$container" 2>&1
}

container_stop() {
    local container="$1"
    docker stop "$container" 2>&1
}

container_restart() {
    local container="$1"
    docker restart "$container" 2>&1
}

container_remove() {
    local container="$1"
    local force="${2:-false}"

    if [[ "$force" == "true" ]]; then
        docker rm -f "$container" 2>&1
    else
        docker rm "$container" 2>&1
    fi
}

container_exec() {
    local container="$1"
    local cmd="$2"
    docker exec "$container" $cmd 2>&1
}

container_shell() {
    local container="$1"
    local shell="${2:-/bin/sh}"
    docker exec -it "$container" "$shell"
}

#───────────────────────────────────────────────────────────────────────────────
# CLEANUP OPERATIONS
#───────────────────────────────────────────────────────────────────────────────

cleanup_stopped_containers() {
    docker container prune -f 2>&1
}

cleanup_dangling_images() {
    docker image prune -f 2>&1
}

cleanup_unused_volumes() {
    docker volume prune -f 2>&1
}

cleanup_unused_networks() {
    docker network prune -f 2>&1
}

cleanup_all() {
    docker system prune -af --volumes 2>&1
}

#───────────────────────────────────────────────────────────────────────────────
# VISUALIZATION
#───────────────────────────────────────────────────────────────────────────────

render_container_status() {
    local status="$1"

    if [[ "$status" == *"Up"* ]]; then
        printf "${BR_GREEN}●${RST}"
    elif [[ "$status" == *"Exited"* ]]; then
        printf "${BR_RED}●${RST}"
    elif [[ "$status" == *"Restarting"* ]]; then
        printf "${BR_YELLOW}◐${RST}"
    elif [[ "$status" == *"Paused"* ]]; then
        printf "${BR_BLUE}◑${RST}"
    else
        printf "${TEXT_MUTED}○${RST}"
    fi
}

render_resource_bar() {
    local value="$1"
    local max="${2:-100}"
    local width="${3:-20}"
    local label="${4:-}"

    local filled=$((value * width / max))
    [[ $filled -gt $width ]] && filled=$width
    local empty=$((width - filled))

    local color="$BR_GREEN"
    [[ $value -gt 50 ]] && color="$BR_YELLOW"
    [[ $value -gt 80 ]] && color="$BR_RED"

    printf "%s" "$color"
    printf "%0.s█" $(seq 1 $filled 2>/dev/null) || true
    printf "${TEXT_MUTED}"
    printf "%0.s░" $(seq 1 $empty 2>/dev/null) || true
    printf "${RST}"

    [[ -n "$label" ]] && printf " %s" "$label"
}

render_container_card() {
    local id="$1"
    local name="$2"
    local image="$3"
    local status="$4"
    local ports="$5"

    local stats=$(get_container_stats "$id")
    IFS='|' read -r cpu mem_usage mem_perc net block <<< "$stats"

    printf "${BR_CYAN}┌─────────────────────────────────────────────────────────────────┐${RST}\n"
    printf "${BR_CYAN}│${RST} "
    render_container_status "$status"
    printf " ${BOLD}%-20s${RST} ${TEXT_MUTED}%s${RST}%*s${BR_CYAN}│${RST}\n" "${name:0:20}" "${id:0:12}" $((29 - ${#id})) ""

    printf "${BR_CYAN}│${RST}   ${TEXT_SECONDARY}Image: %-50s${RST} ${BR_CYAN}│${RST}\n" "${image:0:50}"
    printf "${BR_CYAN}│${RST}   ${TEXT_SECONDARY}Status: %-49s${RST} ${BR_CYAN}│${RST}\n" "${status:0:49}"

    if [[ -n "$ports" ]]; then
        printf "${BR_CYAN}│${RST}   ${TEXT_SECONDARY}Ports: %-50s${RST} ${BR_CYAN}│${RST}\n" "${ports:0:50}"
    fi

    if [[ -n "$cpu" ]]; then
        local cpu_num=${cpu%\%}
        cpu_num=${cpu_num//[^0-9]/}
        local mem_num=${mem_perc%\%}
        mem_num=${mem_num//[^0-9]/}

        printf "${BR_CYAN}│${RST}   CPU: "
        render_resource_bar "${cpu_num:-0}" 100 15
        printf " %-6s  MEM: " "$cpu"
        render_resource_bar "${mem_num:-0}" 100 15
        printf " %-6s ${BR_CYAN}│${RST}\n" "$mem_perc"
    fi

    printf "${BR_CYAN}└─────────────────────────────────────────────────────────────────┘${RST}\n"
}

#───────────────────────────────────────────────────────────────────────────────
# CONTAINER LIST VIEW
#───────────────────────────────────────────────────────────────────────────────

render_container_list() {
    local filter="${1:-all}"

    printf "${BOLD}%-4s %-15s %-25s %-15s %-20s${RST}\n" "ST" "NAME" "IMAGE" "STATUS" "PORTS"
    printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────────────────────────────────────────────────"

    local count=0
    while IFS='|' read -r id name image status ports; do
        [[ -z "$id" ]] && continue

        printf " "
        render_container_status "$status"
        printf "  ${BR_CYAN}%-15s${RST} " "${name:0:15}"
        printf "${TEXT_SECONDARY}%-25s${RST} " "${image:0:25}"

        if [[ "$status" == *"Up"* ]]; then
            printf "${BR_GREEN}%-15s${RST} " "${status:0:15}"
        else
            printf "${BR_RED}%-15s${RST} " "${status:0:15}"
        fi

        printf "${TEXT_MUTED}%-20s${RST}\n" "${ports:0:20}"

        ((count++))
        [[ $count -ge 15 ]] && break
    done < <(get_containers "$filter")

    local total=$(get_container_total)
    [[ $count -lt $total ]] && printf "${TEXT_MUTED}... and %d more containers${RST}\n" "$((total - count))"
}

#───────────────────────────────────────────────────────────────────────────────
# IMAGE LIST VIEW
#───────────────────────────────────────────────────────────────────────────────

render_image_list() {
    printf "${BOLD}%-15s %-30s %-10s %-12s${RST}\n" "ID" "REPOSITORY" "TAG" "SIZE"
    printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────────────────────────────────────────────────"

    local count=0
    while IFS='|' read -r id repo tag size created; do
        [[ -z "$id" ]] && continue

        printf "  ${BR_YELLOW}%-13s${RST} " "${id:0:12}"
        printf "${BR_CYAN}%-30s${RST} " "${repo:0:30}"
        printf "${TEXT_SECONDARY}%-10s${RST} " "${tag:0:10}"
        printf "${BR_PURPLE}%-12s${RST}\n" "${size:0:12}"

        ((count++))
        [[ $count -ge 10 ]] && break
    done < <(get_images)
}

#───────────────────────────────────────────────────────────────────────────────
# STATS DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

render_live_stats() {
    printf "${BOLD}Live Container Statistics${RST}\n\n"

    printf "%-20s %-10s %-20s %-20s %-15s\n" "CONTAINER" "CPU" "MEMORY" "NET I/O" "BLOCK I/O"
    printf "${TEXT_MUTED}%s${RST}\n" "────────────────────────────────────────────────────────────────────────────────"

    docker stats --no-stream --format '{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}|{{.NetIO}}|{{.BlockIO}}' 2>/dev/null | \
    while IFS='|' read -r name cpu mem net block; do
        printf "${BR_CYAN}%-20s${RST} " "${name:0:20}"
        printf "${BR_GREEN}%-10s${RST} " "$cpu"
        printf "${BR_YELLOW}%-20s${RST} " "$mem"
        printf "${TEXT_SECONDARY}%-20s${RST} " "$net"
        printf "${TEXT_MUTED}%-15s${RST}\n" "$block"
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

render_docker_dashboard() {
    clear_screen
    cursor_hide

    if ! check_docker; then
        sleep 2
        return 1
    fi

    # Header
    printf "${BR_BLUE}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                       🐳 DOCKER FLEET MANAGER                                ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    # Summary stats
    local running=$(get_container_count)
    local total=$(get_container_total)
    local images=$(get_image_count)
    local volumes=$(get_volume_count)
    local networks=$(get_network_count)
    local dangling=$(get_dangling_images)

    printf "  ${BOLD}Running:${RST} ${BR_GREEN}%s${RST}/${TEXT_MUTED}%s${RST}  " "$running" "$total"
    printf "${BOLD}Images:${RST} ${BR_PURPLE}%s${RST}  " "$images"
    printf "${BOLD}Volumes:${RST} ${BR_YELLOW}%s${RST}  " "$volumes"
    printf "${BOLD}Networks:${RST} ${BR_CYAN}%s${RST}  " "$networks"
    [[ $dangling -gt 0 ]] && printf "${BR_RED}(%d dangling)${RST}" "$dangling"
    printf "\n\n"

    # Two-column layout
    printf "${BR_CYAN}┌───────────────────────────────────────┬──────────────────────────────────────┐${RST}\n"
    printf "${BR_CYAN}│${RST} ${BOLD}Running Containers${RST}                   ${BR_CYAN}│${RST} ${BOLD}Resource Usage${RST}                     ${BR_CYAN}│${RST}\n"
    printf "${BR_CYAN}├───────────────────────────────────────┼──────────────────────────────────────┤${RST}\n"

    # Left column - running containers
    local left_lines=()
    while IFS='|' read -r id name image status ports; do
        [[ -z "$id" ]] && continue
        local line=$(printf "%-12s %-20s" "${name:0:12}" "${status:0:20}")
        left_lines+=("$line")
    done < <(get_containers "running" | head -8)

    # Right column - stats
    local right_lines=()
    while IFS='|' read -r name cpu mem net block; do
        [[ -z "$name" ]] && continue
        local cpu_num=${cpu%\%}
        local line=$(printf "%-12s CPU:%-6s MEM:%-8s" "${name:0:12}" "$cpu" "${mem%%/*}")
        right_lines+=("$line")
    done < <(docker stats --no-stream --format '{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}|{{.NetIO}}|{{.BlockIO}}' 2>/dev/null | head -8)

    # Render rows
    local max_rows=8
    for ((i=0; i<max_rows; i++)); do
        local left="${left_lines[$i]:-}"
        local right="${right_lines[$i]:-}"
        printf "${BR_CYAN}│${RST} %-37s ${BR_CYAN}│${RST} %-36s ${BR_CYAN}│${RST}\n" "$left" "$right"
    done

    printf "${BR_CYAN}└───────────────────────────────────────┴──────────────────────────────────────┘${RST}\n\n"

    # Recent Images
    printf "${BOLD}Recent Images:${RST}\n"
    get_images | head -5 | while IFS='|' read -r id repo tag size created; do
        printf "  ${BR_YELLOW}%s${RST} ${BR_CYAN}%s${RST}:${TEXT_SECONDARY}%s${RST} ${TEXT_MUTED}(%s)${RST}\n" "${id:0:12}" "${repo:0:30}" "${tag:0:10}" "$size"
    done

    printf "\n${TEXT_MUTED}─────────────────────────────────────────────────────────────────────────────${RST}\n"
    printf "  ${TEXT_SECONDARY}[s]tart  [t]op  [r]estart  [k]ill  [l]ogs  [e]xec  [i]mages  [c]lean  [q]uit${RST}\n"
}

docker_dashboard_loop() {
    while true; do
        render_docker_dashboard

        if read -rsn1 -t 3 key 2>/dev/null; then
            case "$key" in
                s|S)
                    printf "\n${BR_CYAN}Container name to start: ${RST}"
                    cursor_show
                    read -r name
                    cursor_hide
                    [[ -n "$name" ]] && container_start "$name"
                    sleep 1
                    ;;
                t|T)
                    printf "\n${BR_CYAN}Container name to stop: ${RST}"
                    cursor_show
                    read -r name
                    cursor_hide
                    [[ -n "$name" ]] && container_stop "$name"
                    sleep 1
                    ;;
                r|R)
                    printf "\n${BR_CYAN}Container name to restart: ${RST}"
                    cursor_show
                    read -r name
                    cursor_hide
                    [[ -n "$name" ]] && container_restart "$name"
                    sleep 1
                    ;;
                k|K)
                    printf "\n${BR_CYAN}Container name to remove: ${RST}"
                    cursor_show
                    read -r name
                    cursor_hide
                    [[ -n "$name" ]] && container_remove "$name" "true"
                    sleep 1
                    ;;
                l|L)
                    printf "\n${BR_CYAN}Container name for logs: ${RST}"
                    cursor_show
                    read -r name
                    cursor_hide
                    if [[ -n "$name" ]]; then
                        clear_screen
                        printf "${BOLD}Logs for %s:${RST}\n\n" "$name"
                        get_container_logs "$name" 30
                        printf "\n${TEXT_MUTED}Press any key...${RST}"
                        read -rsn1
                    fi
                    ;;
                e|E)
                    printf "\n${BR_CYAN}Container name: ${RST}"
                    cursor_show
                    read -r name
                    printf "${BR_CYAN}Command: ${RST}"
                    read -r cmd
                    cursor_hide
                    if [[ -n "$name" && -n "$cmd" ]]; then
                        container_exec "$name" "$cmd"
                        sleep 2
                    fi
                    ;;
                i|I)
                    clear_screen
                    printf "${BOLD}Docker Images${RST}\n\n"
                    render_image_list
                    printf "\n${TEXT_MUTED}Press any key...${RST}"
                    read -rsn1
                    ;;
                c|C)
                    printf "\n${BR_YELLOW}Cleanup Menu:${RST}\n"
                    printf "  1. Stopped containers\n"
                    printf "  2. Dangling images\n"
                    printf "  3. Unused volumes\n"
                    printf "  4. Unused networks\n"
                    printf "  5. Everything\n"
                    read -rsn1 choice
                    case "$choice" in
                        1) cleanup_stopped_containers ;;
                        2) cleanup_dangling_images ;;
                        3) cleanup_unused_volumes ;;
                        4) cleanup_unused_networks ;;
                        5) cleanup_all ;;
                    esac
                    sleep 2
                    ;;
                q|Q) break ;;
            esac
        fi
    done

    cursor_show
}

#───────────────────────────────────────────────────────────────────────────────
# DOCKER COMPOSE MANAGER
#───────────────────────────────────────────────────────────────────────────────

compose_manager() {
    local compose_file="${1:-docker-compose.yml}"

    clear_screen
    printf "${BOLD}Docker Compose Manager${RST}\n\n"

    if [[ ! -f "$compose_file" ]]; then
        printf "${BR_RED}Compose file not found: %s${RST}\n" "$compose_file"
        return 1
    fi

    printf "${BR_CYAN}File: %s${RST}\n\n" "$compose_file"

    printf "${BOLD}Services:${RST}\n"
    get_compose_services "$compose_file" | while read -r service; do
        printf "  ${BR_GREEN}●${RST} %s\n" "$service"
    done

    printf "\n${TEXT_SECONDARY}[u]p  [d]own  [r]estart  [l]ogs  [p]s  [b]uild  [q]uit${RST}\n"

    while true; do
        read -rsn1 key
        case "$key" in
            u) docker-compose -f "$compose_file" up -d ;;
            d) docker-compose -f "$compose_file" down ;;
            r) docker-compose -f "$compose_file" restart ;;
            l) docker-compose -f "$compose_file" logs --tail=50 ;;
            p) docker-compose -f "$compose_file" ps ;;
            b) docker-compose -f "$compose_file" build ;;
            q) break ;;
        esac
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-dashboard}" in
        dashboard)  docker_dashboard_loop ;;
        list)       render_container_list "${2:-all}" ;;
        stats)      render_live_stats ;;
        images)     render_image_list ;;
        start)      container_start "$2" ;;
        stop)       container_stop "$2" ;;
        restart)    container_restart "$2" ;;
        remove)     container_remove "$2" "${3:-false}" ;;
        logs)       get_container_logs "$2" "${3:-50}" ;;
        exec)       container_exec "$2" "$3" ;;
        shell)      container_shell "$2" "${3:-/bin/sh}" ;;
        clean)      cleanup_all ;;
        compose)    compose_manager "$2" ;;
        *)
            printf "Usage: %s [dashboard|list|stats|images|start|stop|restart|remove|logs|exec|shell|clean|compose]\n" "$0"
            ;;
    esac
fi
