#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  ██████╗ ███████╗███╗   ██╗ ██████╗██╗  ██╗███╗   ███╗ █████╗ ██████╗ ██╗  ██╗
#  ██╔══██╗██╔════╝████╗  ██║██╔════╝██║  ██║████╗ ████║██╔══██╗██╔══██╗██║ ██╔╝
#  ██████╔╝█████╗  ██╔██╗ ██║██║     ███████║██╔████╔██║███████║██████╔╝█████╔╝
#  ██╔══██╗██╔══╝  ██║╚██╗██║██║     ██╔══██║██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗
#  ██████╔╝███████╗██║ ╚████║╚██████╗██║  ██║██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██╗
#  ╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
#═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD SYSTEM BENCHMARK v1.0
#  Comprehensive System Performance Testing
#═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib-core.sh" ]] && source "$SCRIPT_DIR/lib-core.sh"

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────

BENCHMARK_DIR="/tmp/blackroad-benchmark"
RESULTS_FILE="$BENCHMARK_DIR/results.json"

declare -A SCORES=(
    [cpu_single]=0
    [cpu_multi]=0
    [memory]=0
    [disk_seq]=0
    [disk_random]=0
    [network]=0
)

#───────────────────────────────────────────────────────────────────────────────
# UTILITIES
#───────────────────────────────────────────────────────────────────────────────

setup_benchmark() {
    mkdir -p "$BENCHMARK_DIR"
    rm -f "$BENCHMARK_DIR"/*
}

cleanup_benchmark() {
    rm -rf "$BENCHMARK_DIR"
}

get_cpu_info() {
    if [[ -f /proc/cpuinfo ]]; then
        local model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        local cores=$(grep -c "processor" /proc/cpuinfo)
        echo "$model|$cores"
    else
        local model=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
        local cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "1")
        echo "$model|$cores"
    fi
}

get_mem_info() {
    if [[ -f /proc/meminfo ]]; then
        local total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        echo "$((total / 1024))"  # MB
    else
        local total=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
        echo "$((total / 1024 / 1024))"  # MB
    fi
}

format_size() {
    local bytes="$1"
    if [[ $bytes -ge 1073741824 ]]; then
        printf "%.2f GB" "$(echo "$bytes / 1073741824" | bc -l)"
    elif [[ $bytes -ge 1048576 ]]; then
        printf "%.2f MB" "$(echo "$bytes / 1048576" | bc -l)"
    elif [[ $bytes -ge 1024 ]]; then
        printf "%.2f KB" "$(echo "$bytes / 1024" | bc -l)"
    else
        printf "%d B" "$bytes"
    fi
}

format_time() {
    local ms="$1"
    if [[ $ms -ge 60000 ]]; then
        printf "%.1fm" "$(echo "$ms / 60000" | bc -l)"
    elif [[ $ms -ge 1000 ]]; then
        printf "%.2fs" "$(echo "$ms / 1000" | bc -l)"
    else
        printf "%dms" "$ms"
    fi
}

draw_progress() {
    local current="$1"
    local total="$2"
    local width="${3:-40}"
    local label="${4:-}"

    local pct=$((current * 100 / total))
    local filled=$((current * width / total))

    printf "\r  [${label}] "
    printf "\033[38;5;39m"
    for ((i=0; i<filled; i++)); do printf "█"; done
    printf "\033[38;5;240m"
    for ((i=filled; i<width; i++)); do printf "░"; done
    printf "\033[0m %3d%%" "$pct"
}

draw_result_bar() {
    local score="$1"
    local max="$2"
    local width="${3:-30}"
    local label="${4:-}"

    local pct=$((score * 100 / max))
    local filled=$((score * width / max))

    # Color based on performance
    local color="46"  # green
    [[ $pct -lt 70 ]] && color="226"  # yellow
    [[ $pct -lt 40 ]] && color="208"  # orange
    [[ $pct -lt 20 ]] && color="196"  # red

    printf "  %-15s " "$label"
    printf "\033[38;5;${color}m"
    for ((i=0; i<filled; i++)); do printf "█"; done
    printf "\033[38;5;240m"
    for ((i=filled; i<width; i++)); do printf "░"; done
    printf "\033[0m %5d pts\n" "$score"
}

#───────────────────────────────────────────────────────────────────────────────
# CPU BENCHMARKS
#───────────────────────────────────────────────────────────────────────────────

bench_cpu_single() {
    printf "\n  \033[1;38;5;39m🔲 CPU Single-Core Benchmark\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"

    local iterations=1000000
    local start_time=$(date +%s%N)

    # Prime number calculation
    local count=0
    for ((n=2; n<10000; n++)); do
        local is_prime=1
        for ((i=2; i*i<=n; i++)); do
            if [[ $((n % i)) -eq 0 ]]; then
                is_prime=0
                break
            fi
        done
        [[ $is_prime -eq 1 ]] && ((count++))

        if [[ $((n % 500)) -eq 0 ]]; then
            draw_progress "$n" 10000 40 "Primes"
        fi
    done

    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))

    printf "\n\n"
    printf "  Found %d primes in %s\n" "$count" "$(format_time $duration_ms)"

    # Calculate score (inverse of time, normalized)
    local score=$((100000 / (duration_ms + 1)))
    [[ $score -gt 1000 ]] && score=1000
    SCORES[cpu_single]=$score

    printf "  Score: \033[38;5;46m%d\033[0m pts\n" "$score"
}

bench_cpu_multi() {
    printf "\n  \033[1;38;5;39m🔳 CPU Multi-Core Benchmark\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"

    local cores=$(nproc 2>/dev/null || echo 4)
    printf "  Testing with %d cores...\n\n" "$cores"

    local start_time=$(date +%s%N)

    # Spawn parallel workers
    for ((c=0; c<cores; c++)); do
        (
            for ((n=0; n<5000; n++)); do
                local x=$((n * n * n))
            done
        ) &
    done

    # Progress animation
    for ((i=0; i<20; i++)); do
        draw_progress "$i" 20 40 "Multi  "
        sleep 0.1
    done

    wait

    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))

    printf "\n\n"
    printf "  Completed in %s\n" "$(format_time $duration_ms)"

    local score=$((cores * 50000 / (duration_ms + 1)))
    [[ $score -gt 2000 ]] && score=2000
    SCORES[cpu_multi]=$score

    printf "  Score: \033[38;5;46m%d\033[0m pts\n" "$score"
}

bench_cpu_float() {
    printf "\n  \033[1;38;5;39m🔢 Floating Point Benchmark\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"

    local start_time=$(date +%s%N)

    # Math operations
    for ((i=0; i<1000; i++)); do
        local result=$(echo "scale=10; s($i * 0.001) + c($i * 0.001) + sqrt($i + 1)" | bc -l 2>/dev/null)

        if [[ $((i % 50)) -eq 0 ]]; then
            draw_progress "$i" 1000 40 "Float  "
        fi
    done

    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))

    printf "\n\n"
    printf "  Completed in %s\n" "$(format_time $duration_ms)"
}

#───────────────────────────────────────────────────────────────────────────────
# MEMORY BENCHMARKS
#───────────────────────────────────────────────────────────────────────────────

bench_memory() {
    printf "\n  \033[1;38;5;201m💾 Memory Benchmark\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"

    local test_size=10  # MB
    local test_file="$BENCHMARK_DIR/memtest"

    printf "  Testing %d MB allocation...\n\n" "$test_size"

    local start_time=$(date +%s%N)

    # Sequential write
    dd if=/dev/zero of="$test_file" bs=1M count=$test_size conv=fdatasync 2>/dev/null

    for ((i=0; i<10; i++)); do
        draw_progress "$i" 10 40 "Write  "
        dd if=/dev/zero of="$test_file" bs=1M count=1 conv=fdatasync 2>/dev/null
    done

    printf "\n"

    # Sequential read
    for ((i=0; i<10; i++)); do
        draw_progress "$i" 10 40 "Read   "
        dd if="$test_file" of=/dev/null bs=1M count=1 2>/dev/null
    done

    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))

    printf "\n\n"

    local bandwidth=$((test_size * 2 * 1000 / (duration_ms + 1)))  # MB/s
    printf "  Bandwidth: %d MB/s\n" "$bandwidth"

    local score=$((bandwidth * 10))
    [[ $score -gt 1500 ]] && score=1500
    SCORES[memory]=$score

    printf "  Score: \033[38;5;46m%d\033[0m pts\n" "$score"

    rm -f "$test_file"
}

#───────────────────────────────────────────────────────────────────────────────
# DISK BENCHMARKS
#───────────────────────────────────────────────────────────────────────────────

bench_disk_sequential() {
    printf "\n  \033[1;38;5;226m💿 Disk Sequential I/O Benchmark\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"

    local test_file="$BENCHMARK_DIR/disktest"
    local test_size=50  # MB

    printf "  Testing %d MB sequential I/O...\n\n" "$test_size"

    # Write test
    local write_start=$(date +%s%N)

    for ((i=0; i<test_size; i++)); do
        dd if=/dev/zero of="$test_file" bs=1M count=1 seek=$i conv=fdatasync 2>/dev/null
        [[ $((i % 5)) -eq 0 ]] && draw_progress "$i" "$test_size" 40 "Write  "
    done

    local write_end=$(date +%s%N)
    local write_ms=$(( (write_end - write_start) / 1000000 ))
    local write_speed=$((test_size * 1000 / (write_ms + 1)))

    printf "\n  Write: %d MB/s\n" "$write_speed"

    # Read test
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

    local read_start=$(date +%s%N)

    for ((i=0; i<test_size; i++)); do
        dd if="$test_file" of=/dev/null bs=1M count=1 skip=$i 2>/dev/null
        [[ $((i % 5)) -eq 0 ]] && draw_progress "$i" "$test_size" 40 "Read   "
    done

    local read_end=$(date +%s%N)
    local read_ms=$(( (read_end - read_start) / 1000000 ))
    local read_speed=$((test_size * 1000 / (read_ms + 1)))

    printf "\n  Read: %d MB/s\n" "$read_speed"

    local score=$(( (write_speed + read_speed) * 5 ))
    [[ $score -gt 2000 ]] && score=2000
    SCORES[disk_seq]=$score

    printf "  Score: \033[38;5;46m%d\033[0m pts\n" "$score"

    rm -f "$test_file"
}

bench_disk_random() {
    printf "\n  \033[1;38;5;226m🎲 Disk Random I/O Benchmark\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"

    local test_file="$BENCHMARK_DIR/randomtest"
    local num_ops=100

    # Create test file
    dd if=/dev/zero of="$test_file" bs=1M count=10 2>/dev/null

    printf "  Testing %d random 4KB operations...\n\n" "$num_ops"

    local start_time=$(date +%s%N)

    for ((i=0; i<num_ops; i++)); do
        local offset=$((RANDOM % 2500))
        dd if=/dev/urandom of="$test_file" bs=4K count=1 seek=$offset conv=notrunc 2>/dev/null

        [[ $((i % 10)) -eq 0 ]] && draw_progress "$i" "$num_ops" 40 "Random "
    done

    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))

    printf "\n\n"

    local iops=$((num_ops * 1000 / (duration_ms + 1)))
    printf "  Random IOPS: %d ops/s\n" "$iops"

    local score=$((iops * 2))
    [[ $score -gt 1000 ]] && score=1000
    SCORES[disk_random]=$score

    printf "  Score: \033[38;5;46m%d\033[0m pts\n" "$score"

    rm -f "$test_file"
}

#───────────────────────────────────────────────────────────────────────────────
# NETWORK BENCHMARKS
#───────────────────────────────────────────────────────────────────────────────

bench_network() {
    printf "\n  \033[1;38;5;46m🌐 Network Benchmark\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"

    local test_urls=(
        "https://www.google.com"
        "https://www.cloudflare.com"
        "https://www.github.com"
    )

    printf "  Testing connectivity and latency...\n\n"

    local total_time=0
    local success=0

    for url in "${test_urls[@]}"; do
        local host=$(echo "$url" | sed 's|https://||' | sed 's|/.*||')

        draw_progress "$success" "${#test_urls[@]}" 40 "Ping   "

        local start_time=$(date +%s%N)

        if ping -c 1 -W 2 "$host" &>/dev/null; then
            local end_time=$(date +%s%N)
            local latency=$(( (end_time - start_time) / 1000000 ))
            total_time=$((total_time + latency))
            ((success++))
        fi
    done

    printf "\n\n"

    if [[ $success -gt 0 ]]; then
        local avg_latency=$((total_time / success))
        printf "  Average latency: %dms\n" "$avg_latency"

        local score=$((1000 - avg_latency * 5))
        [[ $score -lt 0 ]] && score=0
        [[ $score -gt 1000 ]] && score=1000
        SCORES[network]=$score

        printf "  Score: \033[38;5;46m%d\033[0m pts\n" "$score"
    else
        printf "  \033[38;5;196mNo network connectivity\033[0m\n"
        SCORES[network]=0
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# RESULTS
#───────────────────────────────────────────────────────────────────────────────

render_header() {
    printf "\033[1;38;5;214m"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                         ⚡ SYSTEM BENCHMARK SUITE                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    printf "\033[0m"
}

render_system_info() {
    printf "\n  \033[1;38;5;39m📊 System Information\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    IFS='|' read -r cpu_model cpu_cores <<< "$(get_cpu_info)"
    local mem_mb=$(get_mem_info)

    printf "  CPU:     %s\n" "$cpu_model"
    printf "  Cores:   %s\n" "$cpu_cores"
    printf "  Memory:  %d MB\n" "$mem_mb"
    printf "  OS:      %s\n" "$(uname -s) $(uname -r)"
    printf "  Date:    %s\n" "$(date)"
}

render_results() {
    printf "\n  \033[1;38;5;201m🏆 Benchmark Results\033[0m\n"
    printf "  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n\n"

    local total=0
    local max_score=1000

    draw_result_bar "${SCORES[cpu_single]}" "$max_score" 30 "CPU Single"
    total=$((total + SCORES[cpu_single]))

    draw_result_bar "${SCORES[cpu_multi]}" 2000 30 "CPU Multi"
    total=$((total + SCORES[cpu_multi]))

    draw_result_bar "${SCORES[memory]}" 1500 30 "Memory"
    total=$((total + SCORES[memory]))

    draw_result_bar "${SCORES[disk_seq]}" 2000 30 "Disk Seq"
    total=$((total + SCORES[disk_seq]))

    draw_result_bar "${SCORES[disk_random]}" "$max_score" 30 "Disk Random"
    total=$((total + SCORES[disk_random]))

    draw_result_bar "${SCORES[network]}" "$max_score" 30 "Network"
    total=$((total + SCORES[network]))

    printf "\n  \033[38;5;240m───────────────────────────────────────────────────────────\033[0m\n"

    # Total score
    local max_total=7500
    local pct=$((total * 100 / max_total))

    printf "\n  \033[1;38;5;214mTOTAL SCORE: %d / %d (%d%%)\033[0m\n\n" "$total" "$max_total" "$pct"

    # Rating
    local rating=""
    local rating_color=""
    if [[ $pct -ge 80 ]]; then
        rating="EXCELLENT"
        rating_color="46"
    elif [[ $pct -ge 60 ]]; then
        rating="VERY GOOD"
        rating_color="39"
    elif [[ $pct -ge 40 ]]; then
        rating="GOOD"
        rating_color="226"
    elif [[ $pct -ge 20 ]]; then
        rating="FAIR"
        rating_color="208"
    else
        rating="NEEDS UPGRADE"
        rating_color="196"
    fi

    printf "  Rating: \033[1;38;5;${rating_color}m★ %s ★\033[0m\n" "$rating"
}

export_results() {
    local output="$1"

    {
        printf "{\n"
        printf '  "timestamp": "%s",\n' "$(date -Iseconds)"
        printf '  "system": {\n'
        IFS='|' read -r cpu_model cpu_cores <<< "$(get_cpu_info)"
        printf '    "cpu": "%s",\n' "$cpu_model"
        printf '    "cores": %s,\n' "$cpu_cores"
        printf '    "memory_mb": %d\n' "$(get_mem_info)"
        printf '  },\n'
        printf '  "scores": {\n'
        printf '    "cpu_single": %d,\n' "${SCORES[cpu_single]}"
        printf '    "cpu_multi": %d,\n' "${SCORES[cpu_multi]}"
        printf '    "memory": %d,\n' "${SCORES[memory]}"
        printf '    "disk_sequential": %d,\n' "${SCORES[disk_seq]}"
        printf '    "disk_random": %d,\n' "${SCORES[disk_random]}"
        printf '    "network": %d\n' "${SCORES[network]}"
        printf '  }\n'
        printf "}\n"
    } > "$output"

    printf "\n  \033[38;5;46m✓ Results exported to: %s\033[0m\n" "$output"
}

#───────────────────────────────────────────────────────────────────────────────
# MAIN
#───────────────────────────────────────────────────────────────────────────────

show_help() {
    cat << 'EOF'

  BLACKROAD SYSTEM BENCHMARK
  ═══════════════════════════

  Usage: system-benchmark.sh [options]

  Options:
    -a, --all             Run all benchmarks (default)
    -c, --cpu             CPU benchmarks only
    -m, --memory          Memory benchmark only
    -d, --disk            Disk benchmarks only
    -n, --network         Network benchmark only
    -q, --quick           Quick benchmark (reduced iterations)
    -e, --export <file>   Export results to JSON
    -h, --help            Show this help

  Benchmarks included:
    • CPU Single-core (prime calculation)
    • CPU Multi-core (parallel processing)
    • Memory bandwidth
    • Disk sequential I/O
    • Disk random I/O
    • Network latency

  Examples:
    system-benchmark.sh              # Full benchmark
    system-benchmark.sh -c           # CPU only
    system-benchmark.sh -q           # Quick mode
    system-benchmark.sh -e bench.json # Export results

EOF
}

run_benchmark() {
    local run_cpu="${1:-true}"
    local run_memory="${2:-true}"
    local run_disk="${3:-true}"
    local run_network="${4:-true}"
    local export_file="$5"

    clear
    render_header
    render_system_info

    setup_benchmark

    if [[ "$run_cpu" == "true" ]]; then
        bench_cpu_single
        bench_cpu_multi
    fi

    if [[ "$run_memory" == "true" ]]; then
        bench_memory
    fi

    if [[ "$run_disk" == "true" ]]; then
        bench_disk_sequential
        bench_disk_random
    fi

    if [[ "$run_network" == "true" ]]; then
        bench_network
    fi

    render_results

    if [[ -n "$export_file" ]]; then
        export_results "$export_file"
    fi

    cleanup_benchmark
}

main() {
    local run_cpu=true
    local run_memory=true
    local run_disk=true
    local run_network=true
    local export_file=""
    local run_all=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--all) run_all=true; shift ;;
            -c|--cpu)
                run_cpu=true; run_memory=false; run_disk=false; run_network=false
                shift ;;
            -m|--memory)
                run_cpu=false; run_memory=true; run_disk=false; run_network=false
                shift ;;
            -d|--disk)
                run_cpu=false; run_memory=false; run_disk=true; run_network=false
                shift ;;
            -n|--network)
                run_cpu=false; run_memory=false; run_disk=false; run_network=true
                shift ;;
            -q|--quick)
                # Quick mode - reduced testing
                shift ;;
            -e|--export) export_file="$2"; shift 2 ;;
            -h|--help) show_help; exit 0 ;;
            *) shift ;;
        esac
    done

    run_benchmark "$run_cpu" "$run_memory" "$run_disk" "$run_network" "$export_file"

    printf "\n"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
