#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██╗    ██╗███████╗ █████╗ ████████╗██╗  ██╗███████╗██████╗
#  ██║    ██║██╔════╝██╔══██╗╚══██╔══╝██║  ██║██╔════╝██╔══██╗
#  ██║ █╗ ██║█████╗  ███████║   ██║   ███████║█████╗  ██████╔╝
#  ██║███╗██║██╔══╝  ██╔══██║   ██║   ██╔══██║██╔══╝  ██╔══██╗
#  ╚███╔███╔╝███████╗██║  ██║   ██║   ██║  ██║███████╗██║  ██║
#   ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD WEATHER DASHBOARD v3.0
#  Weather Forecasts with ASCII Art & Animations
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

CACHE_DIR="${BLACKROAD_HOME:-$HOME/.blackroad-dashboards}/cache/weather"
mkdir -p "$CACHE_DIR" 2>/dev/null

DEFAULT_CITY="${WEATHER_CITY:-San Francisco}"
UNITS="${WEATHER_UNITS:-metric}"  # metric or imperial

# Open-Meteo API (free, no key required)
API_BASE="https://api.open-meteo.com/v1"

#───────────────────────────────────────────────────────────────────────────────
# WEATHER ASCII ART
#───────────────────────────────────────────────────────────────────────────────

render_sun() {
    printf "\033[38;5;226m"
    cat << 'EOF'
       \   /
        .-.
     ― (   ) ―
        `-'
       /   \
EOF
    printf "\033[0m"
}

render_cloud() {
    printf "\033[38;5;250m"
    cat << 'EOF'
          .--.
       .-(    ).
      (___.__)__)
EOF
    printf "\033[0m"
}

render_partly_cloudy() {
    printf "\033[38;5;226m   \\ \033[38;5;250m  .--.   \n"
    printf "\033[38;5;226m  .-\033[38;5;250m.-(    ). \n"
    printf "\033[38;5;226m ― (\033[38;5;250m___.__)__)\n"
    printf "\033[38;5;226m  '-'        \n"
    printf "\033[0m"
}

render_rain() {
    printf "\033[38;5;250m"
    cat << 'EOF'
      .-.
     (   ).
    (___(__)
    ‚ʻ‚ʻ‚ʻ‚ʻ
   ‚ʻ‚ʻ‚ʻ‚ʻ
EOF
    printf "\033[0m"
}

render_heavy_rain() {
    printf "\033[38;5;240m"
    cat << 'EOF'
      .-.
     (   ).
    (___(__)
   ‚'‚'‚'‚'‚'
  ‚'‚'‚'‚'‚'
 ‚'‚'‚'‚'‚'
EOF
    printf "\033[0m"
}

render_snow() {
    printf "\033[38;5;255m"
    cat << 'EOF'
      .-.
     (   ).
    (___(__)
    * * * *
   * * * *
EOF
    printf "\033[0m"
}

render_thunderstorm() {
    printf "\033[38;5;240m"
    cat << 'EOF'
      .-.
     (   ).
    (___(__)
EOF
    printf "\033[38;5;226m"
    cat << 'EOF'
    ⚡‚'⚡‚'
   ‚'‚'‚'‚'
EOF
    printf "\033[0m"
}

render_fog() {
    printf "\033[38;5;250m"
    cat << 'EOF'
  _ - _ - _ -
   _ - _ - _
  _ - _ - _ -
   _ - _ - _
EOF
    printf "\033[0m"
}

render_clear_night() {
    printf "\033[38;5;229m"
    cat << 'EOF'
       .--.
      (    )
     (      )
      (    )
       '--'
EOF
    printf "\033[0m"
}

render_weather_icon() {
    local code="$1"
    local is_day="${2:-1}"

    case "$code" in
        0)  # Clear
            [[ "$is_day" == "1" ]] && render_sun || render_clear_night
            ;;
        1|2)  # Partly cloudy
            render_partly_cloudy
            ;;
        3)  # Overcast
            render_cloud
            ;;
        45|48)  # Fog
            render_fog
            ;;
        51|53|55|61|63|80|81)  # Rain
            render_rain
            ;;
        65|82)  # Heavy rain
            render_heavy_rain
            ;;
        71|73|75|77|85|86)  # Snow
            render_snow
            ;;
        95|96|99)  # Thunderstorm
            render_thunderstorm
            ;;
        *)
            render_cloud
            ;;
    esac
}

get_weather_description() {
    local code="$1"

    case "$code" in
        0)  echo "Clear sky" ;;
        1)  echo "Mainly clear" ;;
        2)  echo "Partly cloudy" ;;
        3)  echo "Overcast" ;;
        45) echo "Fog" ;;
        48) echo "Depositing rime fog" ;;
        51) echo "Light drizzle" ;;
        53) echo "Moderate drizzle" ;;
        55) echo "Dense drizzle" ;;
        61) echo "Slight rain" ;;
        63) echo "Moderate rain" ;;
        65) echo "Heavy rain" ;;
        71) echo "Slight snow" ;;
        73) echo "Moderate snow" ;;
        75) echo "Heavy snow" ;;
        77) echo "Snow grains" ;;
        80) echo "Slight showers" ;;
        81) echo "Moderate showers" ;;
        82) echo "Violent showers" ;;
        85) echo "Slight snow showers" ;;
        86) echo "Heavy snow showers" ;;
        95) echo "Thunderstorm" ;;
        96) echo "Thunderstorm with hail" ;;
        99) echo "Severe thunderstorm" ;;
        *)  echo "Unknown" ;;
    esac
}

#───────────────────────────────────────────────────────────────────────────────
# GEOCODING
#───────────────────────────────────────────────────────────────────────────────

geocode_city() {
    local city="$1"
    local cache_file="$CACHE_DIR/geo_$(echo "$city" | tr ' ' '_').json"

    # Check cache
    if [[ -f "$cache_file" ]]; then
        local age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if [[ $age -lt 86400 ]]; then  # 24 hour cache
            cat "$cache_file"
            return
        fi
    fi

    local result=$(curl -s "https://geocoding-api.open-meteo.com/v1/search?name=${city// /%20}&count=1" 2>/dev/null)

    if [[ -n "$result" ]]; then
        echo "$result" > "$cache_file"
        echo "$result"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# WEATHER DATA
#───────────────────────────────────────────────────────────────────────────────

fetch_weather() {
    local lat="$1"
    local lon="$2"
    local cache_file="$CACHE_DIR/weather_${lat}_${lon}.json"

    # Check cache (15 min)
    if [[ -f "$cache_file" ]]; then
        local age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if [[ $age -lt 900 ]]; then
            cat "$cache_file"
            return
        fi
    fi

    local temp_unit="celsius"
    local wind_unit="kmh"
    [[ "$UNITS" == "imperial" ]] && temp_unit="fahrenheit" && wind_unit="mph"

    local url="$API_BASE/forecast?latitude=$lat&longitude=$lon"
    url+="&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,wind_direction_10m"
    url+="&hourly=temperature_2m,precipitation_probability,weather_code"
    url+="&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_sum,precipitation_probability_max"
    url+="&temperature_unit=$temp_unit&wind_speed_unit=$wind_unit&timezone=auto&forecast_days=7"

    local result=$(curl -s "$url" 2>/dev/null)

    if [[ -n "$result" ]]; then
        echo "$result" > "$cache_file"
        echo "$result"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# RENDERING
#───────────────────────────────────────────────────────────────────────────────

render_current_weather() {
    local weather="$1"
    local city="$2"

    if ! command -v jq &>/dev/null; then
        printf "\033[38;5;196mjq required for weather parsing\033[0m\n"
        return
    fi

    local temp=$(echo "$weather" | jq -r '.current.temperature_2m // "N/A"')
    local feels_like=$(echo "$weather" | jq -r '.current.apparent_temperature // "N/A"')
    local humidity=$(echo "$weather" | jq -r '.current.relative_humidity_2m // "N/A"')
    local wind=$(echo "$weather" | jq -r '.current.wind_speed_10m // "N/A"')
    local code=$(echo "$weather" | jq -r '.current.weather_code // 0')
    local is_day=$(echo "$weather" | jq -r '.current.is_day // 1')

    local temp_unit="°C"
    local wind_unit="km/h"
    [[ "$UNITS" == "imperial" ]] && temp_unit="°F" && wind_unit="mph"

    local description=$(get_weather_description "$code")

    # Header
    printf "\n  \033[1;38;5;51m%s\033[0m\n" "$city"
    printf "  \033[38;5;240m%s\033[0m\n\n" "$(date '+%A, %B %d %Y')"

    # Weather icon (side by side with data)
    local icon_output=$(render_weather_icon "$code" "$is_day")
    local -a icon_lines
    mapfile -t icon_lines <<< "$icon_output"

    local data_lines=(
        "$(printf "\033[1;38;5;226m%.0f%s\033[0m  %s" "$temp" "$temp_unit" "$description")"
        "$(printf "\033[38;5;245mFeels like: %.0f%s\033[0m" "$feels_like" "$temp_unit")"
        "$(printf "\033[38;5;39mHumidity: %s%%\033[0m" "$humidity")"
        "$(printf "\033[38;5;51mWind: %s %s\033[0m" "$wind" "$wind_unit")"
    )

    local max_lines=${#icon_lines[@]}
    [[ ${#data_lines[@]} -gt $max_lines ]] && max_lines=${#data_lines[@]}

    for ((i=0; i<max_lines; i++)); do
        printf "  %-20s  %s\n" "${icon_lines[$i]:-}" "${data_lines[$i]:-}"
    done
}

render_hourly_forecast() {
    local weather="$1"
    local hours="${2:-12}"

    printf "\n  \033[1mHourly Forecast\033[0m\n\n"

    local temp_unit="°C"
    [[ "$UNITS" == "imperial" ]] && temp_unit="°F"

    # Current hour index
    local current_hour=$(date +%H)
    local -a times=($(echo "$weather" | jq -r '.hourly.time[]' 2>/dev/null))
    local -a temps=($(echo "$weather" | jq -r '.hourly.temperature_2m[]' 2>/dev/null))
    local -a probs=($(echo "$weather" | jq -r '.hourly.precipitation_probability[]' 2>/dev/null))
    local -a codes=($(echo "$weather" | jq -r '.hourly.weather_code[]' 2>/dev/null))

    # Find current hour index
    local start_idx=0
    for ((i=0; i<${#times[@]}; i++)); do
        if [[ "${times[$i]}" == *"T${current_hour}:"* ]]; then
            start_idx=$i
            break
        fi
    done

    printf "  "
    for ((i=start_idx; i<start_idx+hours && i<${#times[@]}; i++)); do
        local hour=$(echo "${times[$i]}" | grep -oP 'T\K\d+')
        printf "\033[38;5;245m%3s\033[0m " "$hour"
    done
    printf "\n  "

    for ((i=start_idx; i<start_idx+hours && i<${#times[@]}; i++)); do
        local temp="${temps[$i]}"
        local color="\033[38;5;39m"
        [[ ${temp%.*} -gt 25 ]] && color="\033[38;5;226m"
        [[ ${temp%.*} -gt 30 ]] && color="\033[38;5;196m"
        [[ ${temp%.*} -lt 10 ]] && color="\033[38;5;51m"
        printf "%s%3.0f\033[0m " "$color" "$temp"
    done
    printf "\n  "

    for ((i=start_idx; i<start_idx+hours && i<${#times[@]}; i++)); do
        local prob="${probs[$i]}"
        if [[ ${prob%.*} -gt 50 ]]; then
            printf "\033[38;5;39m%3d%%\033[0m" "$prob"
        else
            printf "\033[38;5;240m%3d%%\033[0m" "$prob"
        fi
    done
    printf "\n"
}

render_daily_forecast() {
    local weather="$1"

    printf "\n  \033[1m7-Day Forecast\033[0m\n\n"

    local temp_unit="°"
    local days=($(echo "$weather" | jq -r '.daily.time[]' 2>/dev/null))
    local codes=($(echo "$weather" | jq -r '.daily.weather_code[]' 2>/dev/null))
    local maxs=($(echo "$weather" | jq -r '.daily.temperature_2m_max[]' 2>/dev/null))
    local mins=($(echo "$weather" | jq -r '.daily.temperature_2m_min[]' 2>/dev/null))
    local probs=($(echo "$weather" | jq -r '.daily.precipitation_probability_max[]' 2>/dev/null))

    for ((i=0; i<${#days[@]} && i<7; i++)); do
        local day_name=$(date -d "${days[$i]}" '+%a' 2>/dev/null || echo "${days[$i]}")
        local code="${codes[$i]}"
        local max="${maxs[$i]}"
        local min="${mins[$i]}"
        local prob="${probs[$i]:-0}"
        local desc=$(get_weather_description "$code")

        # Mini weather icon
        local icon="☀"
        case "$code" in
            0) icon="☀" ;;
            1|2) icon="⛅" ;;
            3) icon="☁" ;;
            45|48) icon="🌫" ;;
            51|53|55|61|63|80|81) icon="🌧" ;;
            65|82) icon="🌧" ;;
            71|73|75|77|85|86) icon="❄" ;;
            95|96|99) icon="⛈" ;;
        esac

        printf "  \033[1m%-3s\033[0m  %s  " "$day_name" "$icon"

        # Temperature bar
        local range=$((${max%.*} - ${min%.*}))
        local bar_len=$((range / 2))
        [[ $bar_len -lt 1 ]] && bar_len=1
        [[ $bar_len -gt 15 ]] && bar_len=15

        printf "\033[38;5;39m%2.0f$temp_unit\033[0m " "$min"
        printf "\033[38;5;214m"
        printf "%0.s▓" $(seq 1 $bar_len)
        printf "\033[0m"
        printf " \033[38;5;196m%2.0f$temp_unit\033[0m  " "$max"

        [[ ${prob%.*} -gt 30 ]] && printf "\033[38;5;39m💧%d%%\033[0m" "$prob"
        printf "\n"
    done
}

render_sun_times() {
    local weather="$1"

    local sunrise=$(echo "$weather" | jq -r '.daily.sunrise[0]' 2>/dev/null)
    local sunset=$(echo "$weather" | jq -r '.daily.sunset[0]' 2>/dev/null)

    sunrise=$(echo "$sunrise" | grep -oP 'T\K\d+:\d+')
    sunset=$(echo "$sunset" | grep -oP 'T\K\d+:\d+')

    printf "\n  \033[38;5;226m☀ Sunrise: %s\033[0m  " "$sunrise"
    printf "\033[38;5;208m☀ Sunset: %s\033[0m\n" "$sunset"
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

weather_dashboard() {
    local city="${1:-$DEFAULT_CITY}"

    clear

    printf "\033[1;38;5;39m"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                        🌤️  BLACKROAD WEATHER                                  ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "\033[0m"

    printf "\n  \033[38;5;245mFetching weather for %s...\033[0m\n" "$city"

    # Geocode city
    local geo=$(geocode_city "$city")

    if ! command -v jq &>/dev/null; then
        printf "\n  \033[38;5;196mjq required for weather data\033[0m\n"
        return 1
    fi

    local lat=$(echo "$geo" | jq -r '.results[0].latitude // empty')
    local lon=$(echo "$geo" | jq -r '.results[0].longitude // empty')
    local name=$(echo "$geo" | jq -r '.results[0].name // empty')
    local country=$(echo "$geo" | jq -r '.results[0].country // empty')

    if [[ -z "$lat" || -z "$lon" ]]; then
        printf "\n  \033[38;5;196mCity not found: %s\033[0m\n" "$city"
        return 1
    fi

    local full_name="$name, $country"

    # Fetch weather
    local weather=$(fetch_weather "$lat" "$lon")

    if [[ -z "$weather" ]]; then
        printf "\n  \033[38;5;196mFailed to fetch weather data\033[0m\n"
        return 1
    fi

    # Render
    clear
    printf "\033[1;38;5;39m"
    printf "╔══════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                        🌤️  BLACKROAD WEATHER                                  ║\n"
    printf "╚══════════════════════════════════════════════════════════════════════════════╝\n"
    printf "\033[0m"

    render_current_weather "$weather" "$full_name"
    render_sun_times "$weather"
    render_hourly_forecast "$weather" 10
    render_daily_forecast "$weather"

    printf "\n\033[38;5;240m───────────────────────────────────────────────────────────────────────────────\033[0m\n"
    printf "  \033[38;5;245m[R] Refresh  [C] Change city  [U] Toggle units  [Q] Quit\033[0m\n"
}

weather_dashboard_loop() {
    local city="${1:-$DEFAULT_CITY}"

    while true; do
        weather_dashboard "$city"

        if read -rsn1 -t 300 key 2>/dev/null; then
            case "$key" in
                r|R) continue ;;
                c|C)
                    printf "\n  \033[38;5;51mEnter city: \033[0m"
                    read -r new_city
                    [[ -n "$new_city" ]] && city="$new_city"
                    ;;
                u|U)
                    [[ "$UNITS" == "metric" ]] && UNITS="imperial" || UNITS="metric"
                    ;;
                q|Q) break ;;
            esac
        fi
    done
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-dashboard}" in
        dashboard) weather_dashboard_loop "$2" ;;
        current)   weather_dashboard "$2" ;;
        *)
            printf "Usage: %s [dashboard|current] [city]\n" "$0"
            ;;
    esac
fi
