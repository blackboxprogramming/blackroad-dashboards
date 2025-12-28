#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD CACHE LIBRARY v2.0
#  High-performance caching system with TTL, compression, and invalidation
#═══════════════════════════════════════════════════════════════════════════════

# Source core library if not already loaded
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "$BLACKROAD_CORE_LOADED" ]] && source "$SCRIPT_DIR/lib-core.sh"

# Prevent multiple inclusions
[[ -n "$BLACKROAD_CACHE_LOADED" ]] && return 0
export BLACKROAD_CACHE_LOADED=1

#───────────────────────────────────────────────────────────────────────────────
# CACHE CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

export CACHE_DIR="${BLACKROAD_CACHE:-$HOME/.blackroad-dashboards/cache}"
export CACHE_DEFAULT_TTL="${CACHE_DEFAULT_TTL:-300}"    # 5 minutes default
export CACHE_MAX_SIZE="${CACHE_MAX_SIZE:-104857600}"    # 100MB max cache size
export CACHE_COMPRESSION="${CACHE_COMPRESSION:-0}"      # 0=off, 1=gzip

# Predefined TTLs for different data types
declare -A CACHE_TTL_PRESETS=(
    [realtime]=30        # 30 seconds - live metrics
    [fast]=60            # 1 minute - frequently changing
    [standard]=300       # 5 minutes - normal data
    [slow]=900           # 15 minutes - slower changing
    [hourly]=3600        # 1 hour - rarely changes
    [daily]=86400        # 24 hours - static data
    [permanent]=0        # Never expires (0 = infinite)
)

# Ensure cache directory exists
mkdir -p "$CACHE_DIR" 2>/dev/null

#───────────────────────────────────────────────────────────────────────────────
# CACHE KEY GENERATION
#───────────────────────────────────────────────────────────────────────────────

# Generate cache key from input (URL, command, etc.)
cache_key() {
    local input="$1"
    local namespace="${2:-default}"

    # Create hash of input
    local hash
    if command -v md5sum &>/dev/null; then
        hash=$(echo -n "$input" | md5sum | cut -d' ' -f1)
    elif command -v md5 &>/dev/null; then
        hash=$(echo -n "$input" | md5)
    else
        # Fallback: simple hash
        hash=$(echo -n "$input" | cksum | cut -d' ' -f1)
    fi

    echo "${namespace}_${hash}"
}

# Get cache file path for key
cache_path() {
    local key="$1"
    echo "$CACHE_DIR/${key}.cache"
}

# Get metadata file path
cache_meta_path() {
    local key="$1"
    echo "$CACHE_DIR/${key}.meta"
}

#───────────────────────────────────────────────────────────────────────────────
# CORE CACHE OPERATIONS
#───────────────────────────────────────────────────────────────────────────────

# Set cache value
cache_set() {
    local key="$1"
    local value="$2"
    local ttl="${3:-$CACHE_DEFAULT_TTL}"

    local cache_file=$(cache_path "$key")
    local meta_file=$(cache_meta_path "$key")
    local now=$(date +%s)
    local expires=$((now + ttl))

    # Handle TTL presets
    if [[ -n "${CACHE_TTL_PRESETS[$ttl]}" ]]; then
        expires=$((now + ${CACHE_TTL_PRESETS[$ttl]}))
        [[ "${CACHE_TTL_PRESETS[$ttl]}" == "0" ]] && expires=0
    fi

    # Write metadata
    cat > "$meta_file" << EOF
{
    "key": "$key",
    "created": $now,
    "expires": $expires,
    "ttl": $ttl,
    "size": ${#value},
    "compressed": $CACHE_COMPRESSION,
    "hits": 0
}
EOF

    # Write data (optionally compressed)
    if [[ "$CACHE_COMPRESSION" == "1" ]] && command -v gzip &>/dev/null; then
        echo "$value" | gzip > "$cache_file"
    else
        echo "$value" > "$cache_file"
    fi

    log_debug "Cache SET: $key (TTL: ${ttl}s, Size: ${#value} bytes)"
    return 0
}

# Get cache value
cache_get() {
    local key="$1"
    local cache_file=$(cache_path "$key")
    local meta_file=$(cache_meta_path "$key")

    # Check if cache exists
    if [[ ! -f "$cache_file" ]] || [[ ! -f "$meta_file" ]]; then
        log_debug "Cache MISS: $key (not found)"
        return 1
    fi

    # Check expiration
    local now=$(date +%s)
    local expires=$(grep -o '"expires": [0-9]*' "$meta_file" | grep -o '[0-9]*')

    if [[ "$expires" != "0" ]] && [[ $now -gt $expires ]]; then
        log_debug "Cache MISS: $key (expired)"
        rm -f "$cache_file" "$meta_file" 2>/dev/null
        return 1
    fi

    # Update hit count
    if command -v jq &>/dev/null; then
        local hits=$(jq '.hits' "$meta_file" 2>/dev/null || echo "0")
        jq ".hits = $((hits + 1))" "$meta_file" > "${meta_file}.tmp" 2>/dev/null
        mv "${meta_file}.tmp" "$meta_file" 2>/dev/null
    fi

    # Read data (decompress if needed)
    local compressed=$(grep -o '"compressed": [01]' "$meta_file" | grep -o '[01]')
    if [[ "$compressed" == "1" ]] && command -v gunzip &>/dev/null; then
        gunzip -c "$cache_file"
    else
        cat "$cache_file"
    fi

    log_debug "Cache HIT: $key"
    return 0
}

# Check if cache key exists and is valid
cache_exists() {
    local key="$1"
    local cache_file=$(cache_path "$key")
    local meta_file=$(cache_meta_path "$key")

    [[ ! -f "$cache_file" ]] && return 1
    [[ ! -f "$meta_file" ]] && return 1

    local now=$(date +%s)
    local expires=$(grep -o '"expires": [0-9]*' "$meta_file" | grep -o '[0-9]*')

    [[ "$expires" != "0" ]] && [[ $now -gt $expires ]] && return 1

    return 0
}

# Delete cache key
cache_delete() {
    local key="$1"
    local cache_file=$(cache_path "$key")
    local meta_file=$(cache_meta_path "$key")

    rm -f "$cache_file" "$meta_file" 2>/dev/null
    log_debug "Cache DELETE: $key"
    return 0
}

# Get remaining TTL for key
cache_ttl() {
    local key="$1"
    local meta_file=$(cache_meta_path "$key")

    [[ ! -f "$meta_file" ]] && echo "-1" && return 1

    local now=$(date +%s)
    local expires=$(grep -o '"expires": [0-9]*' "$meta_file" | grep -o '[0-9]*')

    if [[ "$expires" == "0" ]]; then
        echo "infinite"
    else
        local remaining=$((expires - now))
        [[ $remaining -lt 0 ]] && remaining=0
        echo "$remaining"
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# CACHED FUNCTION WRAPPERS
#───────────────────────────────────────────────────────────────────────────────

# Cache a curl request
cache_curl() {
    local url="$1"
    local ttl="${2:-$CACHE_DEFAULT_TTL}"
    shift 2
    local curl_args=("$@")

    local key=$(cache_key "$url ${curl_args[*]}" "curl")

    # Try to get from cache
    local cached
    if cached=$(cache_get "$key"); then
        echo "$cached"
        return 0
    fi

    # Fetch and cache
    local result
    if result=$(curl -s "${curl_args[@]}" "$url" 2>/dev/null); then
        cache_set "$key" "$result" "$ttl"
        echo "$result"
        return 0
    fi

    return 1
}

# Cache any command output
cache_command() {
    local ttl="$1"
    shift
    local cmd=("$@")

    local key=$(cache_key "${cmd[*]}" "cmd")

    # Try to get from cache
    local cached
    if cached=$(cache_get "$key"); then
        echo "$cached"
        return 0
    fi

    # Execute and cache
    local result
    if result=$("${cmd[@]}" 2>/dev/null); then
        cache_set "$key" "$result" "$ttl"
        echo "$result"
        return 0
    fi

    return 1
}

# Memoize a function (cache its output based on args)
memoize() {
    local func="$1"
    local ttl="${2:-$CACHE_DEFAULT_TTL}"
    shift 2
    local args=("$@")

    local key=$(cache_key "$func ${args[*]}" "memo")

    # Try cache
    local cached
    if cached=$(cache_get "$key"); then
        echo "$cached"
        return 0
    fi

    # Call function and cache
    local result
    if result=$("$func" "${args[@]}"); then
        cache_set "$key" "$result" "$ttl"
        echo "$result"
        return 0
    fi

    return 1
}

#───────────────────────────────────────────────────────────────────────────────
# NAMESPACE OPERATIONS
#───────────────────────────────────────────────────────────────────────────────

# Clear all cache for a namespace
cache_clear_namespace() {
    local namespace="$1"
    local count=0

    for file in "$CACHE_DIR/${namespace}_"*.cache; do
        [[ -f "$file" ]] && rm -f "$file" "${file%.cache}.meta" && ((count++))
    done

    log_info "Cleared $count cache entries for namespace: $namespace"
    return 0
}

# List all keys in namespace
cache_list_namespace() {
    local namespace="$1"

    for file in "$CACHE_DIR/${namespace}_"*.meta; do
        [[ -f "$file" ]] && basename "$file" .meta
    done
}

#───────────────────────────────────────────────────────────────────────────────
# CACHE MAINTENANCE
#───────────────────────────────────────────────────────────────────────────────

# Clean expired entries
cache_cleanup() {
    local now=$(date +%s)
    local count=0

    for meta_file in "$CACHE_DIR"/*.meta; do
        [[ ! -f "$meta_file" ]] && continue

        local expires=$(grep -o '"expires": [0-9]*' "$meta_file" | grep -o '[0-9]*')

        if [[ "$expires" != "0" ]] && [[ $now -gt $expires ]]; then
            local cache_file="${meta_file%.meta}.cache"
            rm -f "$cache_file" "$meta_file" 2>/dev/null
            ((count++))
        fi
    done

    log_info "Cache cleanup: removed $count expired entries"
    return 0
}

# Clear all cache
cache_clear_all() {
    rm -f "$CACHE_DIR"/*.cache "$CACHE_DIR"/*.meta 2>/dev/null
    log_info "Cache cleared completely"
    return 0
}

# Get cache statistics
cache_stats() {
    local total_files=0
    local total_size=0
    local total_hits=0
    local expired=0
    local now=$(date +%s)

    for meta_file in "$CACHE_DIR"/*.meta; do
        [[ ! -f "$meta_file" ]] && continue

        ((total_files++))

        local cache_file="${meta_file%.meta}.cache"
        [[ -f "$cache_file" ]] && total_size=$((total_size + $(stat -f%z "$cache_file" 2>/dev/null || stat -c%s "$cache_file" 2>/dev/null || echo 0)))

        local hits=$(grep -o '"hits": [0-9]*' "$meta_file" | grep -o '[0-9]*')
        total_hits=$((total_hits + ${hits:-0}))

        local expires=$(grep -o '"expires": [0-9]*' "$meta_file" | grep -o '[0-9]*')
        [[ "$expires" != "0" ]] && [[ $now -gt $expires ]] && ((expired++))
    done

    cat << EOF
{
    "total_entries": $total_files,
    "total_size_bytes": $total_size,
    "total_size_human": "$(format_bytes $total_size)",
    "total_hits": $total_hits,
    "expired_entries": $expired,
    "cache_directory": "$CACHE_DIR",
    "max_size_bytes": $CACHE_MAX_SIZE,
    "compression_enabled": $CACHE_COMPRESSION
}
EOF
}

# Prune cache if over size limit
cache_prune() {
    local current_size=0

    for cache_file in "$CACHE_DIR"/*.cache; do
        [[ -f "$cache_file" ]] && current_size=$((current_size + $(stat -f%z "$cache_file" 2>/dev/null || stat -c%s "$cache_file" 2>/dev/null || echo 0)))
    done

    if [[ $current_size -gt $CACHE_MAX_SIZE ]]; then
        log_warn "Cache size ($current_size) exceeds limit ($CACHE_MAX_SIZE), pruning..."

        # Remove oldest files first
        ls -t "$CACHE_DIR"/*.cache 2>/dev/null | tail -n +$((CACHE_MAX_SIZE / 10000)) | while read file; do
            rm -f "$file" "${file%.cache}.meta" 2>/dev/null
            current_size=$((current_size - $(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)))
            [[ $current_size -lt $CACHE_MAX_SIZE ]] && break
        done
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# CACHE WARMING
#───────────────────────────────────────────────────────────────────────────────

# Warm cache with predefined URLs/commands
cache_warm() {
    local -a urls=("$@")
    local count=0

    for url in "${urls[@]}"; do
        cache_curl "$url" "standard" -H "Accept: application/json" &
        ((count++))
    done

    wait
    log_info "Cache warmed with $count entries"
}

#───────────────────────────────────────────────────────────────────────────────
# API-SPECIFIC CACHED FETCHERS
#───────────────────────────────────────────────────────────────────────────────

# Cached GitHub API call
cache_github() {
    local endpoint="$1"
    local ttl="${2:-standard}"

    local url="https://api.github.com/$endpoint"
    local headers=(-H "Accept: application/vnd.github.v3+json")

    [[ -n "$GITHUB_TOKEN" ]] && headers+=(-H "Authorization: token $GITHUB_TOKEN")

    cache_curl "$url" "$ttl" "${headers[@]}"
}

# Cached Cloudflare API call
cache_cloudflare() {
    local endpoint="$1"
    local ttl="${2:-standard}"

    [[ -z "$CLOUDFLARE_TOKEN" ]] && return 1

    local url="https://api.cloudflare.com/client/v4/$endpoint"

    cache_curl "$url" "$ttl" \
        -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
        -H "Content-Type: application/json"
}

# Cached crypto price (fast TTL)
cache_crypto_price() {
    local coin="${1:-bitcoin}"
    local ttl="${2:-fast}"

    cache_curl "https://api.coingecko.com/api/v3/simple/price?ids=$coin&vs_currencies=usd&include_24hr_change=true" "$ttl"
}

#───────────────────────────────────────────────────────────────────────────────
# CACHE DASHBOARD
#───────────────────────────────────────────────────────────────────────────────

# Display cache dashboard
cache_dashboard() {
    clear_screen

    printf "${BR_CYAN}${BOLD}"
    printf "╔══════════════════════════════════════════════════════════════╗\n"
    printf "║              📦 BLACKROAD CACHE DASHBOARD                    ║\n"
    printf "╚══════════════════════════════════════════════════════════════╝\n"
    printf "${RST}\n"

    local stats=$(cache_stats)

    if command -v jq &>/dev/null; then
        local entries=$(echo "$stats" | jq -r '.total_entries')
        local size=$(echo "$stats" | jq -r '.total_size_human')
        local hits=$(echo "$stats" | jq -r '.total_hits')
        local expired=$(echo "$stats" | jq -r '.expired_entries')

        printf "${TEXT_SECONDARY}┌─────────────────┬───────────────────┐${RST}\n"
        printf "${TEXT_SECONDARY}│${RST} ${BR_ORANGE}Total Entries${RST}   ${TEXT_SECONDARY}│${RST} %-17s ${TEXT_SECONDARY}│${RST}\n" "$entries"
        printf "${TEXT_SECONDARY}│${RST} ${BR_GREEN}Cache Size${RST}      ${TEXT_SECONDARY}│${RST} %-17s ${TEXT_SECONDARY}│${RST}\n" "$size"
        printf "${TEXT_SECONDARY}│${RST} ${BR_CYAN}Total Hits${RST}      ${TEXT_SECONDARY}│${RST} %-17s ${TEXT_SECONDARY}│${RST}\n" "$hits"
        printf "${TEXT_SECONDARY}│${RST} ${BR_RED}Expired${RST}         ${TEXT_SECONDARY}│${RST} %-17s ${TEXT_SECONDARY}│${RST}\n" "$expired"
        printf "${TEXT_SECONDARY}└─────────────────┴───────────────────┘${RST}\n"
    else
        echo "$stats"
    fi

    printf "\n${TEXT_MUTED}Cache directory: $CACHE_DIR${RST}\n"
    printf "\n${TEXT_SECONDARY}Commands: [c]leanup [p]rune [x]clear all [q]uit${RST}\n"
}

log_debug "BlackRoad Cache Library v2.0 loaded"
