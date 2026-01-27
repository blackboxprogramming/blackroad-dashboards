#!/bin/bash

# BlackRoad OS - AI Model Training Dashboard
# Real-time ML model training metrics, loss curves, and performance

source ~/blackroad-dashboards/themes.sh 2>/dev/null || true

# Colors
ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GREEN="\033[38;2;20;241;149m"
RED="\033[38;2;255;0;107m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

show_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${PINK}🤖${RESET} ${BOLD}AI MODEL TRAINING DASHBOARD${RESET}                                      ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Training Overview
    echo -e "${TEXT_MUTED}╭─ TRAINING STATUS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Model:${RESET}              ${BOLD}${CYAN}GPT-Neo-2.7B${RESET}         ${TEXT_MUTED}Fine-tuning${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Epoch:${RESET}              ${BOLD}${ORANGE}47${RESET} / ${BOLD}100${RESET}            ${TEXT_MUTED}47% complete${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Batch:${RESET}              ${BOLD}${PINK}2,847${RESET} / ${BOLD}5,000${RESET}      ${TEXT_MUTED}56.9% of epoch${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}ETA:${RESET}                ${BOLD}${PURPLE}3h 24m${RESET}             ${TEXT_MUTED}to completion${RESET}"
    echo ""

    # Progress Bar
    echo -e "${TEXT_MUTED}╭─ TRAINING PROGRESS ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}████████████████████${TEXT_MUTED}█████████████████████${RESET}  ${BOLD}47%${RESET}"
    echo ""

    # Metrics
    echo -e "${TEXT_MUTED}╭─ CURRENT METRICS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Training Loss:${RESET}      ${BOLD}${GREEN}0.234${RESET}              ${GREEN}↓ -0.012${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Validation Loss:${RESET}    ${BOLD}${CYAN}0.287${RESET}              ${GREEN}↓ -0.008${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Learning Rate:${RESET}      ${BOLD}${ORANGE}1.2e-5${RESET}             ${TEXT_MUTED}(decay schedule)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Perplexity:${RESET}         ${BOLD}${PURPLE}12.4${RESET}               ${GREEN}↓ -0.8${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Accuracy:${RESET}           ${BOLD}${PINK}94.7%${RESET}              ${GREEN}↑ +0.3%${RESET}"
    echo ""

    # Loss Curves
    echo -e "${TEXT_MUTED}╭─ LOSS CURVES ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}Training Loss${RESET}"
    echo -e "  1.0  ${RED}╮${RESET}"
    echo -e "  0.8  ${ORANGE}│╲${RESET}"
    echo -e "  0.6  ${ORANGE}│ ╲${RESET}"
    echo -e "  0.4  ${CYAN}│  ╲╲${RESET}"
    echo -e "  0.2  ${GREEN}│    ╲╲─────${RESET}  ${BOLD}0.234${RESET}"
    echo -e "  0.0  ${TEXT_MUTED}└────────────────────────────────────${RESET}"
    echo -e "       ${TEXT_MUTED}0    10   20   30   40   50 (epochs)${RESET}"
    echo ""

    # GPU Utilization
    echo -e "${TEXT_MUTED}╭─ GPU UTILIZATION ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}GPU${RESET}      ${CYAN}Usage${RESET}      ${ORANGE}Memory${RESET}      ${PINK}Temp${RESET}      ${PURPLE}Power${RESET}"
    echo -e "  ${TEXT_MUTED}──────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}GPU 0${RESET}   ${CYAN}98%${RESET}        ${ORANGE}47/48 GB${RESET}   ${PINK}72°C${RESET}     ${PURPLE}320W${RESET}"
    echo -e "  ${BOLD}GPU 1${RESET}   ${CYAN}97%${RESET}        ${ORANGE}46/48 GB${RESET}   ${PINK}71°C${RESET}     ${PURPLE}315W${RESET}"
    echo -e "  ${BOLD}GPU 2${RESET}   ${CYAN}96%${RESET}        ${ORANGE}45/48 GB${RESET}   ${PINK}70°C${RESET}     ${PURPLE}310W${RESET}"
    echo -e "  ${BOLD}GPU 3${RESET}   ${CYAN}98%${RESET}        ${ORANGE}47/48 GB${RESET}   ${PINK}73°C${RESET}     ${PURPLE}325W${RESET}"
    echo ""

    # Dataset Info
    echo -e "${TEXT_MUTED}╭─ DATASET INFORMATION ─────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Training Samples:${RESET}   ${BOLD}${CYAN}2.4M${RESET}               ${TEXT_SECONDARY}(text pairs)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Validation Samples:${RESET} ${BOLD}${ORANGE}240K${RESET}               ${TEXT_SECONDARY}(10% split)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Batch Size:${RESET}         ${BOLD}${PINK}32${RESET}                 ${TEXT_SECONDARY}per GPU${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Sequence Length:${RESET}    ${BOLD}${PURPLE}2048${RESET}               ${TEXT_SECONDARY}tokens${RESET}"
    echo ""

    # Model Checkpoints
    echo -e "${TEXT_MUTED}╭─ MODEL CHECKPOINTS ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}✓${RESET} ${BOLD}epoch_47${RESET}          Loss: ${CYAN}0.234${RESET}  Acc: ${PINK}94.7%${RESET}  ${TEXT_MUTED}2.1 GB • 2m ago${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${BOLD}epoch_46${RESET}          Loss: ${CYAN}0.246${RESET}  Acc: ${PINK}94.4%${RESET}  ${TEXT_MUTED}2.1 GB • 27m ago${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${BOLD}epoch_45${RESET}          Loss: ${CYAN}0.258${RESET}  Acc: ${PINK}94.1%${RESET}  ${TEXT_MUTED}2.1 GB • 52m ago${RESET}"
    echo -e "  ${CYAN}⭐${RESET} ${BOLD}best_model${RESET}        Loss: ${CYAN}0.234${RESET}  Acc: ${PINK}94.7%${RESET}  ${TEXT_MUTED}2.1 GB • epoch 47${RESET}"
    echo ""

    # Hyperparameters
    echo -e "${TEXT_MUTED}╭─ HYPERPARAMETERS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}●${RESET} ${BOLD}Learning Rate:${RESET}      ${ORANGE}1.2e-5${RESET}  ${TEXT_MUTED}(cosine annealing)${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}Optimizer:${RESET}          ${PINK}AdamW${RESET}   ${TEXT_MUTED}(β1=0.9, β2=0.999)${RESET}"
    echo -e "  ${PINK}●${RESET} ${BOLD}Weight Decay:${RESET}       ${PURPLE}0.01${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Warmup Steps:${RESET}       ${CYAN}1000${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}Gradient Clip:${RESET}      ${GREEN}1.0${RESET}"
    echo ""

    # Training Stats
    echo -e "${TEXT_MUTED}╭─ TRAINING STATISTICS ─────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Tokens/Second:${RESET}      ${BOLD}${GREEN}847,234${RESET}            ${TEXT_MUTED}(throughput)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Samples/Second:${RESET}     ${BOLD}${CYAN}412${RESET}                ${TEXT_MUTED}(effective batch)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Steps Completed:${RESET}    ${BOLD}${ORANGE}142,847${RESET}            ${TEXT_MUTED}total${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Time Elapsed:${RESET}       ${BOLD}${PURPLE}23h 47m${RESET}            ${TEXT_MUTED}since start${RESET}"
    echo ""

    # Validation Metrics
    echo -e "${TEXT_MUTED}╭─ VALIDATION PERFORMANCE ──────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}BLEU Score:${RESET}         ${BOLD}${GREEN}0.847${RESET}              ${TEXT_MUTED}(translation quality)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}F1 Score:${RESET}           ${BOLD}${CYAN}0.923${RESET}              ${TEXT_MUTED}(classification)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Precision:${RESET}          ${BOLD}${ORANGE}0.941${RESET}              ${TEXT_MUTED}(positive class)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Recall:${RESET}             ${BOLD}${PINK}0.906${RESET}              ${TEXT_MUTED}(positive class)${RESET}"
    echo ""

    # Recent Logs
    echo -e "${TEXT_MUTED}╭─ TRAINING LOGS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}[INFO]${RESET} Epoch 47/100 - Batch 2847/5000"
    echo -e "  ${GREEN}[SUCCESS]${RESET} Checkpoint saved: epoch_47.pt"
    echo -e "  ${CYAN}[INFO]${RESET} Learning rate: 1.2e-5"
    echo -e "  ${CYAN}[INFO]${RESET} Training loss: 0.234 | Val loss: 0.287"
    echo ""

    # Footer
    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}Updated: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Framework: ${RESET}${BOLD}PyTorch 2.1${RESET}  ${TEXT_SECONDARY}|  GPUs: ${RESET}${BOLD}4x A100${RESET}"
    echo ""
}

# Main loop
if [[ "$1" == "--watch" ]]; then
    while true; do
        show_dashboard
        sleep 3
    done
else
    show_dashboard
fi
