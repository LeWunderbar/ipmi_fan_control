#!/bin/bash

# Fan speed levels (hexadecimal values)
FAN_SPEED_0=0x12    # 0% fan speed
FAN_SPEED_25=0x30   # 25% fan speed
FAN_SPEED_30=0x35   # 30% fan speed
FAN_SPEED_35=0x3A   # 35% fan speed
FAN_SPEED_40=0x40   # 40% fan speed
FAN_SPEED_50=0x50   # 50% fan speed
FAN_SPEED_60=0x60   # 60% fan speed
FAN_SPEED_70=0x70   # 70% fan speed
FAN_SPEED_80=0x80   # 80% fan speed
FAN_SPEED_90=0x90   # 90% fan speed
FAN_SPEED_100=0xFF  # 100% fan speed (maximum)

# Temperature thresholds (degrees Celsius)
TEMP_40=40
TEMP_45=45
TEMP_50=50
TEMP_55=55
TEMP_60=60
TEMP_65=65
TEMP_70=70
TEMP_75=75
TEMP_80=80
TEMP_85=85
TEMP_90=90
TEMP_95=95
TEMP_100=100

# Temporary file for caching IPMI data
IPMI_CACHE_FILE="/tmp/ipmi_temperature_cache.txt"

# Function to fetch and cache IPMI data (overwrite cache file)
fetch_ipmi_data() {
    # Overwrite the cache file (use ">" to redirect and overwrite)
    ipmitool sdr type temperature > "$IPMI_CACHE_FILE"
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    return 0
}

# Function to get CPU temperature by name
get_cpu_temperature() {
    local label=$1
    # Extract temperature from the appropriate field using awk and sed
    grep -w "$label" "$IPMI_CACHE_FILE" | awk -F'|' '{print $5}' | sed 's/[^0-9.]//g'
}

# Function to determine fan speed based on temperature
calculate_fan_speed() {
    local temp=$1
    if (( temp < TEMP_40 )); then
        echo 0   # 0% fan speed
    elif (( temp < TEMP_45 )); then
        echo 25  # 25% fan speed
    elif (( temp < TEMP_50 )); then
        echo 30  # 30% fan speed
    elif (( temp < TEMP_55 )); then
        echo 35  # 35% fan speed
    elif (( temp < TEMP_60 )); then
        echo 40  # 40% fan speed
    elif (( temp < TEMP_65 )); then
        echo 50  # 50% fan speed
    elif (( temp < TEMP_70 )); then
        echo 60  # 60% fan speed
    elif (( temp < TEMP_75 )); then
        echo 70  # 70% fan speed
    elif (( temp < TEMP_80 )); then
        echo 80  # 80% fan speed
    elif (( temp < TEMP_85 )); then
        echo 90  # 90% fan speed
    elif (( temp < TEMP_90 )); then
        echo 95  # 95% fan speed
    else
        echo 100 # 100% fan speed (max)
    fi
}

# Function to set fan speed
set_fan_speed() {
    local fan_bank=$1
    local speed=$2
    # Convert percentage to hexadecimal fan speed value
    case $speed in
        0)  hex_speed=0x12 ;;
        25) hex_speed=0x30 ;;
        30) hex_speed=0x35 ;;
        35) hex_speed=0x3A ;;
        40) hex_speed=0x40 ;;
        50) hex_speed=0x50 ;;
        60) hex_speed=0x60 ;;
        70) hex_speed=0x70 ;;
        80) hex_speed=0x80 ;;
        90) hex_speed=0x90 ;;
        95) hex_speed=0xA0 ;;
        100) hex_speed=0xFF ;;
    esac
    ipmitool raw 0x3a 0x07 "$fan_bank" "$hex_speed" 0x01
}

# Function to display status (simple text output)
display_status() {
    local cpu1_temp=$1
    local cpu2_temp=$2
    local fan1_speed=$3
    local fan2_speed=$4

    echo "----------------------------------"
    echo "Fan Control Status"
    echo "----------------------------------"
    echo "CPU 1 Temperature: $cpu1_temp°C"
    echo "CPU 2 Temperature: $cpu2_temp°C"
    echo "Fan Bank CPU 1: Speed $fan1_speed%"
    echo "Fan Bank CPU 2: Speed $fan2_speed%"
    echo "----------------------------------"
    echo "Last updated: $(date +"%Y-%m-%d %H:%M:%S")"
    echo "----------------------------------"
}

# Main loop
while true; do
    # Fetch IPMI data and cache it (overwrite the file each time)
    echo "Fetching IPMI data..."
    fetch_ipmi_data
    if [[ $? -ne 0 ]]; then
        echo "Failed to fetch IPMI data. Retrying..."
        sleep 10
        continue
    fi

    # Periodically print a status message every 10 seconds to indicate the script is running
    echo "Processing... (fetching temperatures and adjusting fan speeds)"
    sleep 10  # Simulate waiting time for the user to see the message

    # Get temperatures for both CPUs
    CPU1_TEMP=$(get_cpu_temperature "CPU 1 Temp")
    CPU2_TEMP=$(get_cpu_temperature "CPU 2 Temp")

    # Ensure valid temperature readings
    if [[ -z "$CPU1_TEMP" || -z "$CPU2_TEMP" ]]; then
        echo "Failed to read CPU temperatures. Retrying..."
        sleep 10
        continue
    fi

    # Calculate fan speeds for each bank in percentage
    FAN_SPEED_CPU1=$(calculate_fan_speed "$CPU1_TEMP")
    FAN_SPEED_CPU2=$(calculate_fan_speed "$CPU2_TEMP")

    # Apply fan speeds to respective banks
    echo "Adjusting fan speeds based on temperature readings..."
    set_fan_speed 0x01 "$FAN_SPEED_CPU1"  # CPU1 -> Fan Bank CPU 1
    set_fan_speed 0x02 "$FAN_SPEED_CPU2"  # CPU2 -> Fan Bank CPU 2

    # Display status
    display_status "$CPU1_TEMP" "$CPU2_TEMP" "$FAN_SPEED_CPU1" "$FAN_SPEED_CPU2"

    # Indicate that the script will wait for the next cycle
    echo "Waiting 30 seconds before the next probe..."

    # Wait before checking again
    sleep 30
done
