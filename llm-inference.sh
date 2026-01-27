#!/bin/bash

# BlackRoad OS - LLM Inference Monitor
# Real-time monitoring of large language model inference serving

source ~/blackroad-dashboards/themes.sh 2>/dev/null || true

# Colors
ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GREEN="\033[38;2;20;241;149m"
RED="\033[38;2;255;0;107m"
YELLOW="\033[38;2;255;193;7m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

show_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${PINK}🤖${RESET} ${BOLD}LLM INFERENCE MONITOR${RESET}                                            ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Service Status
    echo -e "${TEXT_MUTED}╭─ SERVICE STATUS ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Model:${RESET}              ${BOLD}${CYAN}GPT-4-Turbo${RESET}         ${TEXT_MUTED}(175B parameters)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}             ${GREEN}●${RESET} ${BOLD}${GREEN}SERVING${RESET}            ${TEXT_MUTED}Uptime: 47d 12h${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Instances:${RESET}          ${BOLD}${ORANGE}12${RESET} / ${BOLD}${GREEN}12${RESET} Active      ${TEXT_MUTED}Auto-scaling enabled${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Version:${RESET}            ${BOLD}v2.3.1${RESET}              ${TEXT_MUTED}Latest stable${RESET}"
    echo ""

    # Request Metrics
    echo -e "${TEXT_MUTED}╭─ REQUEST METRICS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Requests/sec:${RESET}       ${BOLD}${GREEN}847${RESET}                ${TEXT_SECONDARY}current throughput${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Avg Latency:${RESET}        ${BOLD}${CYAN}234ms${RESET}              ${TEXT_SECONDARY}(p50: 187ms, p99: 847ms)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Tokens/sec:${RESET}         ${BOLD}${PURPLE}42,847${RESET}            ${TEXT_SECONDARY}generation speed${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Success Rate:${RESET}       ${BOLD}${GREEN}99.7%${RESET}              ${TEXT_SECONDARY}(12 errors/hour)${RESET}"
    echo ""

    # Latency Distribution
    echo -e "${TEXT_MUTED}╭─ LATENCY DISTRIBUTION ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Percentile${RESET}      ${CYAN}Latency${RESET}     ${TEXT_SECONDARY}Graph${RESET}"
    echo -e "  ${TEXT_MUTED}──────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}p50${RESET}            ${CYAN}187ms${RESET}       ${GREEN}████████████${RESET}"
    echo -e "  ${BOLD}p75${RESET}            ${CYAN}234ms${RESET}       ${GREEN}███████████████${RESET}"
    echo -e "  ${BOLD}p90${RESET}            ${ORANGE}389ms${RESET}       ${ORANGE}████████████████████${RESET}"
    echo -e "  ${BOLD}p95${RESET}            ${ORANGE}547ms${RESET}       ${ORANGE}████████████████████████${RESET}"
    echo -e "  ${BOLD}p99${RESET}            ${RED}847ms${RESET}       ${RED}███████████████████████████${RESET}"
    echo ""

    # GPU Utilization
    echo -e "${TEXT_MUTED}╭─ COMPUTE RESOURCES ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Instance${RESET}        ${CYAN}GPUs${RESET}    ${ORANGE}Memory${RESET}      ${PINK}Requests${RESET}    ${PURPLE}Load${RESET}"
    echo -e "  ${TEXT_MUTED}────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}llm-1${RESET}          ${CYAN}4xA100${RESET}  ${ORANGE}176/192GB${RESET}   ${PINK}87/sec${RESET}     ${PURPLE}78%${RESET}"
    echo -e "  ${BOLD}llm-2${RESET}          ${CYAN}4xA100${RESET}  ${ORANGE}184/192GB${RESET}   ${PINK}92/sec${RESET}     ${PURPLE}84%${RESET}"
    echo -e "  ${BOLD}llm-3${RESET}          ${CYAN}4xA100${RESET}  ${ORANGE}172/192GB${RESET}   ${PINK}79/sec${RESET}     ${PURPLE}72%${RESET}"
    echo ""

    # Request Types
    echo -e "${TEXT_MUTED}╭─ REQUEST BREAKDOWN ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Type${RESET}                ${CYAN}Count${RESET}      ${ORANGE}Avg Tokens${RESET}    ${PINK}Latency${RESET}"
    echo -e "  ${TEXT_MUTED}───────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}Chat Completion${RESET}    ${CYAN}547/sec${RESET}    ${ORANGE}487${RESET}           ${PINK}234ms${RESET}"
    echo -e "  ${BOLD}Code Generation${RESET}    ${CYAN}189/sec${RESET}    ${ORANGE}1,247${RESET}         ${PINK}847ms${RESET}"
    echo -e "  ${BOLD}Summarization${RESET}      ${CYAN}78/sec${RESET}     ${ORANGE}892${RESET}           ${PINK}412ms${RESET}"
    echo -e "  ${BOLD}Translation${RESET}        ${CYAN}33/sec${RESET}     ${ORANGE}234${RESET}           ${PINK}187ms${RESET}"
    echo ""

    # Token Statistics
    echo -e "${TEXT_MUTED}╭─ TOKEN STATISTICS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Input Tokens:${RESET}       ${BOLD}${CYAN}847K/sec${RESET}           ${TEXT_SECONDARY}average prompt length${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Output Tokens:${RESET}      ${BOLD}${PURPLE}423K/sec${RESET}           ${TEXT_SECONDARY}average completion${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Tokens:${RESET}       ${BOLD}${ORANGE}1.27M/sec${RESET}          ${TEXT_SECONDARY}combined throughput${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Cache Hit Rate:${RESET}     ${BOLD}${GREEN}47.2%${RESET}              ${TEXT_SECONDARY}KV cache efficiency${RESET}"
    echo ""

    # Model Performance
    echo -e "${TEXT_MUTED}╭─ MODEL QUALITY ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}●${RESET} ${BOLD}BLEU Score:${RESET}         ${GREEN}0.847${RESET}  ${TEXT_MUTED}(translation quality)${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}Perplexity:${RESET}         ${GREEN}12.4${RESET}   ${TEXT_MUTED}(generation quality)${RESET}"
    echo -e "  ${PINK}●${RESET} ${BOLD}Coherence:${RESET}          ${GREEN}94.7%${RESET}  ${TEXT_MUTED}(response quality)${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Safety Score:${RESET}       ${GREEN}98.2%${RESET}  ${TEXT_MUTED}(content moderation)${RESET}"
    echo ""

    # Error Analysis
    echo -e "${TEXT_MUTED}╭─ ERROR ANALYSIS ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Error Type${RESET}              ${RED}Count${RESET}      ${ORANGE}Rate${RESET}"
    echo -e "  ${TEXT_MUTED}──────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}Context Length${RESET}         ${RED}5${RESET}          ${ORANGE}0.01%${RESET}"
    echo -e "  ${BOLD}Rate Limit${RESET}             ${RED}4${RESET}          ${ORANGE}0.008%${RESET}"
    echo -e "  ${BOLD}Timeout${RESET}                ${RED}2${RESET}          ${ORANGE}0.004%${RESET}"
    echo -e "  ${BOLD}Server Error${RESET}           ${RED}1${RESET}          ${ORANGE}0.002%${RESET}"
    echo ""

    # Queue Status
    echo -e "${TEXT_MUTED}╭─ QUEUE STATUS ────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Pending Requests:${RESET}   ${BOLD}${CYAN}23${RESET}                 ${TEXT_SECONDARY}in queue${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Avg Queue Time:${RESET}     ${BOLD}${ORANGE}47ms${RESET}               ${TEXT_SECONDARY}waiting time${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Queue Capacity:${RESET}     ${BOLD}${PURPLE}23/1000${RESET}            ${TEXT_SECONDARY}(2.3% full)${RESET}"
    echo ""

    # Live Requests
    echo -e "${TEXT_MUTED}╭─ LIVE REQUESTS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}⚡${RESET} ${TEXT_SECONDARY}Chat completion • 487 tokens${RESET}               ${TEXT_MUTED}234ms • llm-1${RESET}"
    echo -e "  ${CYAN}⚡${RESET} ${TEXT_SECONDARY}Code generation • 1,247 tokens${RESET}             ${TEXT_MUTED}847ms • llm-2${RESET}"
    echo -e "  ${PURPLE}⚡${RESET} ${TEXT_SECONDARY}Summarization • 892 tokens${RESET}                ${TEXT_MUTED}412ms • llm-3${RESET}"
    echo -e "  ${ORANGE}⚡${RESET} ${TEXT_SECONDARY}Translation • 234 tokens${RESET}                  ${TEXT_MUTED}187ms • llm-1${RESET}"
    echo ""

    # Cost Metrics
    echo -e "${TEXT_MUTED}╭─ COST ANALYSIS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Cost/Request:${RESET}       ${BOLD}${ORANGE}\$0.0234${RESET}            ${TEXT_SECONDARY}average${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Cost/Hour:${RESET}          ${BOLD}${RED}\$71,234${RESET}            ${TEXT_SECONDARY}current burn rate${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Cost/Day:${RESET}           ${BOLD}${RED}\$1.71M${RESET}             ${TEXT_SECONDARY}projected${RESET}"
    echo ""

    # Footer
    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}Updated: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Backend: ${RESET}${BOLD}vLLM${RESET}  ${TEXT_SECONDARY}|  Nodes: ${RESET}${BOLD}12xA100${RESET}"
    echo ""
}

# Main loop
if [[ "$1" == "--watch" ]]; then
    while true; do
        show_dashboard
        sleep 2
    done
else
    show_dashboard
fi
