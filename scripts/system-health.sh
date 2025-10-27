#!/bin/bash

###############################################
# Linux System Health Monitoring Script
# Checks CPU, Memory, Disk, and Processes
# Logs alerts if usage exceeds thresholds
###############################################

# === Configuration ===
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=80
PROC_THRESHOLD=300

LOG_FILE="/home/ubuntu/wisecow/scripts/system_health.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# === Log Function ===
log_alert() {
    echo "$DATE - ALERT: $1" >> "$LOG_FILE"
}

# === CPU Check ===
check_cpu() {
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d. -f1)
    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        log_alert "High CPU Usage: ${cpu_usage}%"
        echo "High CPU Usage: ${cpu_usage}%"
    else
        echo "CPU Usage OK: ${cpu_usage}%"
    fi
}

# === Memory Check ===
check_memory() {
    mem_usage=$(free | awk '/Mem/ {printf("%.0f"), $3/$2*100}')
    if [ "$mem_usage" -gt "$MEM_THRESHOLD" ]; then
        log_alert "High Memory Usage: ${mem_usage}%"
        echo "High Memory Usage: ${mem_usage}%"
    else
        echo "Memory Usage OK: ${mem_usage}%"
    fi
}

# === Disk Check ===
check_disk() {
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        log_alert "High Disk Usage: ${disk_usage}%"
        echo "High Disk Usage: ${disk_usage}%"  
    else
        echo "Disk Usage OK: ${disk_usage}%"
    fi
}

# === Process Count Check ===
check_processes() {
    proc_count=$(ps -e --no-headers | wc -l)
    if [ "$proc_count" -gt "$PROC_THRESHOLD" ]; then
        log_alert "High Process Count: ${proc_count}"
        echo "High Process Count: ${proc_count}"    
    else
        echo "Process Count OK: ${proc_count}"
    fi
}

# === Main ===
echo "=========================================="
echo "🧾 System Health Check at $DATE"
echo "=========================================="

check_cpu
check_memory
check_disk
check_processes

echo "✅ Health check completed. Log saved to $LOG_FILE"
echo "=========================================="
