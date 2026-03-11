#!/bin/bash

# BlackRoad OS - Agent-to-Agent Communication Hub
# Real-time messaging system for all 10 corporate AI agents

source ~/blackroad-dashboards/themes.sh
load_theme

COMM_DIR="$HOME/.agent-communication-hub"
MESSAGES_LOG="$COMM_DIR/messages.log"
BROADCASTS_LOG="$COMM_DIR/broadcasts.log"
AGENT_STATUS="$COMM_DIR/agent-status.json"
DIRECT_MESSAGES="$COMM_DIR/direct-messages"

mkdir -p "$COMM_DIR" "$DIRECT_MESSAGES"

# Agent definitions
declare -A AGENTS=(
    ["ceo"]="Alexa|👑|GOLD"
    ["cfo"]="Silas|💼|GREEN"
    ["cto"]="Cecilia|👨‍💻|CYAN"
    ["coo"]="Cadence|📊|ORANGE"
    ["cmo"]="Aria|🎨|PINK"
    ["gc"]="Alice|📝|PURPLE"
    ["vpe"]="DevOps-Swarm|🤖|BLUE"
    ["ciso"]="Guardian|🔒|RED"
    ["vph"]="Lucidia|🔧|GOLD"
    ["vpp"]="Product-Swarm|🎯|PINK"
)

# Send message from one agent to another
send_message() {
    local from=$1
    local to=$2
    local message=$3
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Validate agents
    if [ -z "${AGENTS[$from]}" ] || [ -z "${AGENTS[$to]}" ]; then
        echo -e "${RED}Error: Invalid agent${RESET}"
        return 1
    fi

    # Log message
    echo "$timestamp|$from|$to|$message" >> "$MESSAGES_LOG"

    # Create DM file for recipient
    local dm_file="$DIRECT_MESSAGES/${to}-inbox.log"
    echo "$timestamp|$from|$message" >> "$dm_file"

    # Get sender info
    IFS='|' read -r from_name from_icon from_color <<< "${AGENTS[$from]}"
    IFS='|' read -r to_name to_icon to_color <<< "${AGENTS[$to]}"

    echo -e "${GREEN}✓${RESET} Message sent from ${from_name} to ${to_name}"

    # Log to MEMORY
    ~/memory-system.sh log updated "[CORPORATE]+[AGENTS]+[MESSAGE] $from_name → $to_name" "Agent communication: $message" "agent-communication-hub" 2>/dev/null
}

# Broadcast message to all agents
broadcast_message() {
    local from=$1
    local message=$2
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Log broadcast
    echo "$timestamp|$from|ALL|$message" >> "$BROADCASTS_LOG"

    # Send to all agents
    for agent in "${!AGENTS[@]}"; do
        if [ "$agent" != "$from" ]; then
            local dm_file="$DIRECT_MESSAGES/${agent}-inbox.log"
            echo "$timestamp|$from|[BROADCAST] $message" >> "$dm_file"
        fi
    done

    # Get sender info
    IFS='|' read -r from_name from_icon from_color <<< "${AGENTS[$from]}"

    echo -e "${GREEN}✓${RESET} Broadcast sent from ${from_name} to all agents"

    # Log to MEMORY
    ~/memory-system.sh log updated "[CORPORATE]+[AGENTS]+[BROADCAST] $from_name → ALL" "Agent broadcast: $message" "agent-communication-hub" 2>/dev/null
}

# Get unread message count for agent
get_unread_count() {
    local agent=$1
    local inbox="$DIRECT_MESSAGES/${agent}-inbox.log"

    if [ -f "$inbox" ]; then
        wc -l < "$inbox" | xargs
    else
        echo "0"
    fi
}

# Read messages for agent
read_messages() {
    local agent=$1
    local inbox="$DIRECT_MESSAGES/${agent}-inbox.log"

    if [ ! -f "$inbox" ] || [ ! -s "$inbox" ]; then
        echo -e "${TEXT_MUTED}No messages${RESET}"
        return
    fi

    IFS='|' read -r agent_name agent_icon agent_color <<< "${AGENTS[$agent]}"

    echo -e "${BOLD}${CYAN}Inbox for $agent_name $agent_icon${RESET}\n"

    cat "$inbox" | while IFS='|' read -r timestamp from message; do
        IFS='|' read -r from_name from_icon from_color <<< "${AGENTS[$from]}"

        local time=$(echo "$timestamp" | cut -d'T' -f2 | cut -d':' -f1-2)
        local date=$(echo "$timestamp" | cut -d'T' -f1)

        echo -e "${TEXT_MUTED}[$date $time]${RESET} ${from_icon} ${BOLD}$from_name${RESET}"
        echo -e "  $message"
        echo ""
    done

    # Archive read messages
    cat "$inbox" >> "$DIRECT_MESSAGES/${agent}-archive.log"
    > "$inbox"
}

# Show communication dashboard
show_comm_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${CYAN}💬${RESET} ${BOLD}AGENT-TO-AGENT COMMUNICATION HUB${RESET}                               ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "  ${TEXT_MUTED}Real-time update: $(date)${RESET}"
    echo ""

    # Agent status with unread counts
    echo -e "${TEXT_MUTED}╭─ AGENT STATUS & INBOX ────────────────────────────────────────────────╮${RESET}"
    echo ""

    for agent in ceo cfo cto coo cmo gc vpe ciso vph vpp; do
        IFS='|' read -r name icon color <<< "${AGENTS[$agent]}"

        local unread=$(get_unread_count "$agent")
        local status_icon="${GREEN}●${RESET}"

        if [ "$unread" -gt 0 ]; then
            local unread_badge="${BOLD}${ORANGE}[$unread new]${RESET}"
        else
            local unread_badge="${TEXT_MUTED}[no messages]${RESET}"
        fi

        printf "  %s %s ${BOLD}%-20s${RESET} %s\n" "$status_icon" "$icon" "${name^^}" "$unread_badge"
    done
    echo ""

    # Recent messages
    echo -e "${TEXT_MUTED}╭─ RECENT MESSAGES ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$MESSAGES_LOG" ]; then
        tail -8 "$MESSAGES_LOG" | while IFS='|' read -r timestamp from to message; do
            IFS='|' read -r from_name from_icon from_color <<< "${AGENTS[$from]}"
            IFS='|' read -r to_name to_icon to_color <<< "${AGENTS[$to]}"

            local time=$(echo "$timestamp" | cut -d'T' -f2 | cut -d':' -f1-2)

            echo -e "  ${TEXT_MUTED}[$time]${RESET} ${from_icon} ${BOLD}$from_name${RESET} → ${to_icon} ${BOLD}$to_name${RESET}"
            echo -e "    ${TEXT_MUTED}$message${RESET}"
        done
    else
        echo -e "  ${TEXT_MUTED}No messages yet${RESET}"
    fi
    echo ""

    # Recent broadcasts
    echo -e "${TEXT_MUTED}╭─ RECENT BROADCASTS ───────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$BROADCASTS_LOG" ]; then
        tail -5 "$BROADCASTS_LOG" | while IFS='|' read -r timestamp from to message; do
            IFS='|' read -r from_name from_icon from_color <<< "${AGENTS[$from]}"

            local time=$(echo "$timestamp" | cut -d'T' -f2 | cut -d':' -f1-2)

            echo -e "  ${PURPLE}📢${RESET} ${TEXT_MUTED}[$time]${RESET} ${from_icon} ${BOLD}$from_name${RESET} → ${CYAN}ALL${RESET}"
            echo -e "    ${TEXT_MUTED}$message${RESET}"
        done
    else
        echo -e "  ${TEXT_MUTED}No broadcasts yet${RESET}"
    fi
    echo ""

    # Communication statistics
    echo -e "${TEXT_MUTED}╭─ COMMUNICATION STATISTICS ────────────────────────────────────────────╮${RESET}"
    echo ""

    local total_messages=0
    local total_broadcasts=0

    [ -f "$MESSAGES_LOG" ] && total_messages=$(wc -l < "$MESSAGES_LOG" | xargs)
    [ -f "$BROADCASTS_LOG" ] && total_broadcasts=$(wc -l < "$BROADCASTS_LOG" | xargs)

    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Messages:${RESET}       ${CYAN}$total_messages${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Broadcasts:${RESET}     ${PURPLE}$total_broadcasts${RESET}"

    # Most active agents
    if [ -f "$MESSAGES_LOG" ]; then
        local most_active=$(cut -d'|' -f2 "$MESSAGES_LOG" | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
        if [ -n "$most_active" ]; then
            IFS='|' read -r active_name active_icon active_color <<< "${AGENTS[$most_active]}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Most Active:${RESET}          ${active_icon} ${GREEN}$active_name${RESET}"
        fi
    fi
    echo ""

    # Actions
    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[S]${RESET} Send Message  ${TEXT_SECONDARY}[B]${RESET} Broadcast  ${TEXT_SECONDARY}[R]${RESET} Read Inbox  ${TEXT_SECONDARY}[M]${RESET} Monitor  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Interactive send message
interactive_send() {
    clear
    echo -e "${BOLD}${CYAN}SEND DIRECT MESSAGE${RESET}\n"

    # Select sender
    echo -e "Select sender:\n"
    local i=1
    for agent in ceo cfo cto coo cmo gc vpe ciso vph vpp; do
        IFS='|' read -r name icon color <<< "${AGENTS[$agent]}"
        echo -e "  ${CYAN}$i.${RESET} $icon $name ($agent)"
        ((i++))
    done

    echo -e "\n${TEXT_SECONDARY}Enter number (1-10):${RESET} "
    read -n1 from_num
    echo ""

    local from_agent=""
    i=1
    for agent in ceo cfo cto coo cmo gc vpe ciso vph vpp; do
        if [ "$i" = "$from_num" ]; then
            from_agent="$agent"
            break
        fi
        ((i++))
    done

    if [ -z "$from_agent" ]; then
        echo -e "${RED}Invalid selection${RESET}"
        sleep 1
        return
    fi

    # Select recipient
    echo -e "\nSelect recipient:\n"
    i=1
    for agent in ceo cfo cto coo cmo gc vpe ciso vph vpp; do
        if [ "$agent" != "$from_agent" ]; then
            IFS='|' read -r name icon color <<< "${AGENTS[$agent]}"
            echo -e "  ${CYAN}$i.${RESET} $icon $name ($agent)"
        fi
        ((i++))
    done

    echo -e "\n${TEXT_SECONDARY}Enter number (1-10):${RESET} "
    read -n1 to_num
    echo ""

    local to_agent=""
    i=1
    for agent in ceo cfo cto coo cmo gc vpe ciso vph vpp; do
        if [ "$i" = "$to_num" ] && [ "$agent" != "$from_agent" ]; then
            to_agent="$agent"
            break
        fi
        ((i++))
    done

    if [ -z "$to_agent" ]; then
        echo -e "${RED}Invalid selection${RESET}"
        sleep 1
        return
    fi

    # Enter message
    echo -e "\n${TEXT_SECONDARY}Enter message:${RESET} "
    read message

    if [ -n "$message" ]; then
        send_message "$from_agent" "$to_agent" "$message"
        sleep 1
    fi
}

# Interactive broadcast
interactive_broadcast() {
    clear
    echo -e "${BOLD}${PURPLE}SEND BROADCAST TO ALL AGENTS${RESET}\n"

    # Select sender
    echo -e "Select sender:\n"
    local i=1
    for agent in ceo cfo cto coo cmo gc vpe ciso vph vpp; do
        IFS='|' read -r name icon color <<< "${AGENTS[$agent]}"
        echo -e "  ${CYAN}$i.${RESET} $icon $name ($agent)"
        ((i++))
    done

    echo -e "\n${TEXT_SECONDARY}Enter number (1-10):${RESET} "
    read -n1 from_num
    echo ""

    local from_agent=""
    i=1
    for agent in ceo cfo cto coo cmo gc vpe ciso vph vpp; do
        if [ "$i" = "$from_num" ]; then
            from_agent="$agent"
            break
        fi
        ((i++))
    done

    if [ -z "$from_agent" ]; then
        echo -e "${RED}Invalid selection${RESET}"
        sleep 1
        return
    fi

    # Enter message
    echo -e "\n${TEXT_SECONDARY}Enter broadcast message:${RESET} "
    read message

    if [ -n "$message" ]; then
        broadcast_message "$from_agent" "$message"
        sleep 1
    fi
}

# Interactive read inbox
interactive_read() {
    clear
    echo -e "${BOLD}${CYAN}READ AGENT INBOX${RESET}\n"

    # Select agent
    echo -e "Select agent:\n"
    local i=1
    for agent in ceo cfo cto coo cmo gc vpe ciso vph vpp; do
        IFS='|' read -r name icon color <<< "${AGENTS[$agent]}"
        local unread=$(get_unread_count "$agent")
        echo -e "  ${CYAN}$i.${RESET} $icon $name ($agent) ${ORANGE}[$unread unread]${RESET}"
        ((i++))
    done

    echo -e "\n${TEXT_SECONDARY}Enter number (1-10):${RESET} "
    read -n1 agent_num
    echo ""

    local selected_agent=""
    i=1
    for agent in ceo cfo cto coo cmo gc vpe ciso vph vpp; do
        if [ "$i" = "$agent_num" ]; then
            selected_agent="$agent"
            break
        fi
        ((i++))
    done

    if [ -z "$selected_agent" ]; then
        echo -e "${RED}Invalid selection${RESET}"
        sleep 1
        return
    fi

    clear
    read_messages "$selected_agent"

    echo -e "${TEXT_MUTED}Press any key to continue...${RESET}"
    read -n1
}

# Monitor mode (real-time updates)
monitor_mode() {
    local cycle=0

    echo -e "${BOLD}${GREEN}Starting communication monitor...${RESET}\n"

    while true; do
        ((cycle++))

        clear
        echo -e "${BOLD}${PURPLE}COMMUNICATION MONITOR - CYCLE #$cycle${RESET}"
        echo -e "${TEXT_MUTED}$(date)${RESET}\n"

        # Show recent activity
        echo -e "${CYAN}Recent Messages:${RESET}\n"

        if [ -f "$MESSAGES_LOG" ]; then
            tail -5 "$MESSAGES_LOG" | while IFS='|' read -r timestamp from to message; do
                IFS='|' read -r from_name from_icon from_color <<< "${AGENTS[$from]}"
                IFS='|' read -r to_name to_icon to_color <<< "${AGENTS[$to]}"

                local time=$(echo "$timestamp" | cut -d'T' -f2 | cut -d':' -f1-2)

                echo -e "${TEXT_MUTED}[$time]${RESET} ${from_icon} ${BOLD}$from_name${RESET} → ${to_icon} ${BOLD}$to_name${RESET}"
                echo -e "  ${message}"
                echo ""
            done
        fi

        echo -e "${PURPLE}Recent Broadcasts:${RESET}\n"

        if [ -f "$BROADCASTS_LOG" ]; then
            tail -3 "$BROADCASTS_LOG" | while IFS='|' read -r timestamp from to message; do
                IFS='|' read -r from_name from_icon from_color <<< "${AGENTS[$from]}"

                local time=$(echo "$timestamp" | cut -d'T' -f2 | cut -d':' -f1-2)

                echo -e "${TEXT_MUTED}[$time]${RESET} ${from_icon} ${BOLD}$from_name${RESET} → ${CYAN}ALL${RESET}"
                echo -e "  ${message}"
                echo ""
            done
        fi

        echo -e "\n${TEXT_MUTED}Next update in 30 seconds... Press Q to stop${RESET}\n"

        # Wait with interrupt
        read -t 30 -n1 key

        if [ "$key" = "q" ] || [ "$key" = "Q" ]; then
            echo -e "\n${ORANGE}Monitor stopped${RESET}\n"
            return
        fi
    done
}

# Main loop
main() {
    # Demo: Send some example messages
    if [ ! -f "$MESSAGES_LOG" ]; then
        send_message "ceo" "cto" "Please review infrastructure health report" > /dev/null
        send_message "cfo" "ceo" "Q4 portfolio update: +12% growth" > /dev/null
        send_message "cto" "vpe" "Deploy v2.1.0 to staging environment" > /dev/null
        broadcast_message "ceo" "All hands meeting today at 2 PM UTC" > /dev/null
    fi

    while true; do
        show_comm_dashboard

        read -n1 key

        case "$key" in
            's'|'S')
                interactive_send
                ;;
            'b'|'B')
                interactive_broadcast
                ;;
            'r'|'R')
                interactive_read
                ;;
            'm'|'M')
                clear
                monitor_mode
                ;;
            'q'|'Q')
                clear
                echo -e "\n${CYAN}Communication hub stopped${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
