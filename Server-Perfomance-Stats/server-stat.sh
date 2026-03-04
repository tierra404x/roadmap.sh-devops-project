#!/usr/bin/env bash
set -euo pipefail

# ===== Colors (ANSI) =====
BLUE='\033[1;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

hr() { echo "----------------------------------------"; }
title() { echo -e "${BLUE}$1${NC}"; }
label() { echo -e "${GREEN}$1${NC}"; }
value() { echo -e "${YELLOW}$1${NC}"; }

# ===== 1) CPU usage =====
get_cpu_usage() {
  # Parse idle% from top, then usage = 100 - idle
  # Line example: %Cpu(s):  3.0 us,  1.2 sy, 95.1 id, ...
  top -bn1 2>/dev/null | awk -F'[, ]+' '
    /^%Cpu\(s\):/ {
      for (i=1; i<=NF; i++) if ($i=="id") idle=$(i-1)
    }
    END { if (idle=="") { exit 1 } else { printf "%.2f", 100-idle } }
  '
}

# ===== 2) Memory usage =====
get_mem_usage() {
  # Use bytes for accuracy then convert to GiB
  free -b | awk '
    /^Mem:/ {
      total=$2; used=$3; free=$4;
      gib=1024*1024*1024;
      usedp=used/total*100;
      freep=free/total*100;
      printf "Total: %.2f GiB\nUsed : %.2f GiB (%.2f%%)\nFree : %.2f GiB (%.2f%%)\n",
        total/gib, used/gib, usedp, free/gib, freep
    }'
}

# ===== 3) Disk usage (root /) =====
get_disk_usage() {
  df -P -h / | awk 'NR==2 {
    printf "Total: %s\nUsed : %s (%s)\nFree : %s\n", $2, $3, $5, $4
  }'
}

# ===== 4) Top processes =====
top_cpu_procs() {
  # user pid %cpu %mem command (top 5)
  ps -eo user,pid,%cpu,%mem,comm --sort=-%cpu | head -n 6
}

top_mem_procs() {
  ps -eo user,pid,%mem,%cpu,comm --sort=-%mem | head -n 6
}

# ===== Main output =====
title "SERVER PERFORMANCE STATS"
hr

label "CPU Usage:"
cpu="$(get_cpu_usage || echo "N/A")"
echo -e "  $(value "${cpu}%")"
echo

label "Memory Usage:"
get_mem_usage | sed 's/^/  /'
echo

label "Disk Usage ( / ):"
get_disk_usage | sed 's/^/  /'
echo

label "Top 5 Processes by CPU:"
echo "  USER       PID     %CPU  %MEM  COMMAND"
top_cpu_procs | sed 's/^/  /'
echo

label "Top 5 Processes by Memory:"
echo "  USER       PID     %MEM  %CPU  COMMAND"
top_mem_procs | sed 's/^/  /'
hr
