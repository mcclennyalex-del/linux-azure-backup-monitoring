#!/bin/bash
set -euo pipefail

echo "===== System Monitor (monitor.sh) ====="
echo "Date:     $(date)"
echo "Hostname: $(hostname)"
echo

echo "---- Uptime / Load ----"
uptime
echo

echo "---- Memory (free -h) ----"
free -h
echo

echo "---- Disk (df -h /) ----"
df -h /
echo

echo "---- Top 5 processes by CPU ----"
ps aux --sort=-%cpu | head -n 6
echo

echo "---- Logged-in users (who) ----"
who
echo

echo "===== End of report ====="
