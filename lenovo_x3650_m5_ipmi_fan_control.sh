#!/bin/bash

DUAL_CPU_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dual-cpu)
            DUAL_CPU_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Define temperature thresholds and desired fan speed in %
declare -A TEMP_TO_SPEED=(
    [20]=0
    [25]=2
    [30]=5
    [35]=5
    [40]=5
    [45]=10
    [50]=15
    [55]=15
    [60]=20
    [65]=30
    [70]=40
    [75]=50
    [80]=60
    [85]=70
    [90]=100
)

percent_to_hex() {
    local percent=$1
    local min_hex=0x12
    local max_hex=0xFF
    printf "0x%02X" $(( ( (max_hex - min_hex) * percent / 100 ) + min_hex ))
}

IPMI_CACHE_FILE="/tmp/ipmi_temperature_cache.txt"

fetch_ipmi_data() {
    ipmitool sdr type temperature > "$IPMI_CACHE_FILE"
    return $?
}

get_cpu_temperature() {
    local label=$1
    grep -w "$label" "$IPMI_CACHE_FILE" | awk -F'|' '{print $5}' | sed 's/[^0-9.]//g'
}

get_fan_speed() {
    local temp=$1
    local last_threshold=0
    for t in "${!TEMP_TO_SPEED[@]}"; do
        if (( temp >= t )); then
            last_threshold=$t
        fi
    done
    echo "${TEMP_TO_SPEED[$last_threshold]}"
}

set_fan_speed() {
    local fan_bank=$1
    local speed=$2
    local hex_speed=$(percent_to_hex "$speed")
    ipmitool raw 0x3a 0x07 "$fan_bank" "$hex_speed" 0x01
}

display_status() {
    local cpu1_temp=$1
    local cpu2_temp=$2
    local fan1_speed=$3
    local fan2_speed=$4

    echo "----------------------------------"
    echo "Fan Control Status"
    echo "----------------------------------"
    echo "CPU 1 Temperature: $cpu1_temp°C"
    $DUAL_CPU_MODE && echo "CPU 2 Temperature: $cpu2_temp°C"
    echo "Fan Bank CPU 1: Speed $fan1_speed%"
    $DUAL_CPU_MODE && echo "Fan Bank CPU 2: Speed $fan2_speed%"
    echo "----------------------------------"
    echo "Last updated: $(date +"%Y-%m-%d %H:%M:%S")"
    echo "----------------------------------"
}

while true; do
    echo "Fetching IPMI data..."
    if ! fetch_ipmi_data; then
        echo "Failed to fetch IPMI data. Retrying..."
        sleep 15
        continue
    fi

    CPU1_TEMP=$(get_cpu_temperature "CPU 1 Temp")
    CPU2_TEMP=$($DUAL_CPU_MODE && get_cpu_temperature "CPU 2 Temp" || echo "N/A")

    if [[ -z "$CPU1_TEMP" ]] || ($DUAL_CPU_MODE && [[ -z "$CPU2_TEMP" || "$CPU2_TEMP" == "N/A" ]]); then
        echo "Failed to read CPU temperatures. Retrying..."
        sleep 15
        continue
    fi

    FAN_SPEED_CPU1=$(get_fan_speed "$CPU1_TEMP")
    FAN_SPEED_CPU2=$($DUAL_CPU_MODE && get_fan_speed "$CPU2_TEMP" || echo "$FAN_SPEED_CPU1")

    echo "Adjusting fan speeds..."
    set_fan_speed 0x01 "$FAN_SPEED_CPU1"
    set_fan_speed 0x02 "$FAN_SPEED_CPU2"

    display_status "$CPU1_TEMP" "$CPU2_TEMP" "$FAN_SPEED_CPU1" "$FAN_SPEED_CPU2"

    echo "Waiting 15 seconds before the next probe..."
    sleep 15
done