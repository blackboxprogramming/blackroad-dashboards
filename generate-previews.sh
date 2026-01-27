#!/bin/bash

# BlackRoad OS - Dashboard Preview Generator
# Generates visual previews and metadata for all dashboard templates

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREVIEW_DIR="$SCRIPT_DIR/previews"
DATA_FILE="$PREVIEW_DIR/templates.json"

mkdir -p "$PREVIEW_DIR"

# Colors for output
CYAN="\033[38;2;0;212;255m"
GREEN="\033[38;2;20;241;149m"
ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
RESET="\033[0m"
BOLD="\033[1m"

echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${PURPLE}║${RESET}  ${ORANGE}📸${RESET} ${BOLD}Dashboard Preview Generator${RESET}                                      ${BOLD}${PURPLE}║${RESET}"
echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Extract metadata from a dashboard script
extract_metadata() {
    local script_file=$1
    local script_name=$(basename "$script_file" .sh)
    
    # Extract comments from the top of the file
    local description=$(head -20 "$script_file" | grep "^#" | grep -v "^#!/" | head -5 | sed 's/^# *//' | tr '\n' ' ' | sed 's/  */ /g')
    
    # Try to determine category
    local category="general"
    if [[ $script_name =~ ^blackroad ]]; then
        category="core"
    elif [[ $script_name =~ (dashboard|monitor|system) ]]; then
        category="monitoring"
    elif [[ $script_name =~ (ai|agent|neural|brain|model|training|llm) ]]; then
        category="ai"
    elif [[ $script_name =~ (crypto|blockchain|bitcoin|defi|nft|token) ]]; then
        category="crypto"
    elif [[ $script_name =~ (api|network|cloud|docker|database|kubernetes|redis|queue) ]]; then
        category="infrastructure"
    elif [[ $script_name =~ (graph|chart|visual|3d|heatmap|map|geographic) ]]; then
        category="visualization"
    elif [[ $script_name =~ (security|alert|anomaly|firewall|intrusion|vulnerability) ]]; then
        category="security"
    elif [[ $script_name =~ (quantum|cosmic|galaxy|universe|time|reality|wormhole|antimatter|fusion|particle) ]]; then
        category="scifi"
    fi
    
    # Check if script has interactive mode
    local interactive="false"
    if grep -q "\-\-watch" "$script_file" || grep -q "read.*key" "$script_file"; then
        interactive="true"
    fi
    
    # Check for sound effects
    local has_sound="false"
    if grep -q "afplay\|aplay\|paplay" "$script_file"; then
        has_sound="true"
    fi
    
    # Check for API integration
    local has_api="false"
    if grep -q "curl\|wget\|api\|API" "$script_file"; then
        has_api="true"
    fi
    
    echo "{
  \"name\": \"$script_name\",
  \"file\": \"$script_name.sh\",
  \"description\": \"$description\",
  \"category\": \"$category\",
  \"interactive\": $interactive,
  \"has_sound\": $has_sound,
  \"has_api\": $has_api
}"
}

# Generate JSON data for all templates
echo -e "${CYAN}📝 Extracting metadata from dashboard templates...${RESET}"
echo ""

echo "[" > "$DATA_FILE"

first=true
for script in "$SCRIPT_DIR"/*.sh; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script")
        
        # Skip special scripts
        if [[ "$script_name" == "generate-previews.sh" ]] || \
           [[ "$script_name" == "setup.sh" ]] || \
           [[ "$script_name" == "launch.sh" ]]; then
            continue
        fi
        
        echo -ne "  ${ORANGE}•${RESET} Processing ${BOLD}${script_name}${RESET}..."
        
        if [ "$first" = false ]; then
            echo "," >> "$DATA_FILE"
        fi
        first=false
        
        extract_metadata "$script" >> "$DATA_FILE"
        echo -e " ${GREEN}✓${RESET}"
    fi
done

echo "" >> "$DATA_FILE"
echo "]" >> "$DATA_FILE"

echo ""
echo -e "${GREEN}✓ Metadata generated: ${BOLD}$DATA_FILE${RESET}"

# Count templates by category
echo ""
echo -e "${PURPLE}📊 Dashboard Categories:${RESET}"
echo ""

for category in core monitoring ai crypto infrastructure visualization security scifi general; do
    count=$(grep "\"category\": \"$category\"" "$DATA_FILE" | wc -l | xargs)
    if [ "$count" -gt 0 ]; then
        echo -e "  ${CYAN}$category:${RESET} ${BOLD}$count${RESET} templates"
    fi
done

total=$(grep "\"name\":" "$DATA_FILE" | wc -l | xargs)
echo ""
echo -e "${BOLD}${PINK}Total: $total dashboard templates${RESET}"
echo ""
echo -e "${GREEN}✓ Preview generation complete!${RESET}"
echo ""
