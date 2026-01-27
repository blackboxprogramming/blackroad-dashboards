#!/bin/bash

# BlackRoad OS - Dashboard Preview Browser
# Opens the web-based template browser

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREVIEW_HTML="$SCRIPT_DIR/previews/index.html"

# Colors
CYAN="\033[38;2;0;212;255m"
GREEN="\033[38;2;20;241;149m"
ORANGE="\033[38;2;247;147;26m"
PURPLE="\033[38;2;153;69;255m"
RESET="\033[0m"
BOLD="\033[1m"

clear
echo ""
echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${PURPLE}║${RESET}  ${ORANGE}🌐${RESET} ${BOLD}Dashboard Preview Browser${RESET}                                        ${BOLD}${PURPLE}║${RESET}"
echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Check if preview data exists
if [ ! -f "$SCRIPT_DIR/previews/templates.json" ]; then
    echo -e "${CYAN}📝 Generating preview data...${RESET}"
    echo ""
    "$SCRIPT_DIR/generate-previews.sh"
    echo ""
fi

echo -e "${CYAN}🚀 Opening dashboard browser...${RESET}"
echo ""
echo -e "  ${GREEN}•${RESET} Browse ${BOLD}128 templates${RESET}"
echo -e "  ${GREEN}•${RESET} Search and filter by category"
echo -e "  ${GREEN}•${RESET} Click any template to preview"
echo ""

# Try to open in browser
if command -v open &> /dev/null; then
    # macOS
    open "$PREVIEW_HTML"
elif command -v xdg-open &> /dev/null; then
    # Linux
    xdg-open "$PREVIEW_HTML"
elif command -v start &> /dev/null; then
    # Windows
    start "$PREVIEW_HTML"
else
    echo -e "${ORANGE}⚠️  Could not auto-open browser${RESET}"
    echo ""
    echo -e "  ${CYAN}Please open this file manually:${RESET}"
    echo -e "  ${BOLD}$PREVIEW_HTML${RESET}"
    echo ""
fi

echo -e "${GREEN}✓ Preview browser launched!${RESET}"
echo ""
echo -e "${CYAN}📍 Local URL:${RESET} file://$PREVIEW_HTML"
echo ""
