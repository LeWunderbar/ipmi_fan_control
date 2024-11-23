# Lenovo System x3650 M5 - IPMI Fan Control Script

This script automatically adjusts fan speeds based on CPU temperature readings from the server. It fetches temperature data via IPMI and uses a set of predefined temperature thresholds to set appropriate fan speeds. The fan speed is adjusted through IPMI commands to keep the system cool and quiet.

## Prerequisites

### Linux Systems
- **ipmitool**: This script requires `ipmitool` to communicate with the system's baseboard management controller (BMC) and fetch sensor data.
  
To install `ipmitool` on a Linux system, use the package manager for your distribution:

- On Debian/Ubuntu:
  ```bash
  sudo apt-get install ipmitool
  ```
- On CentOS/RHEL:
  ```bash
  sudo yum install ipmitool
  ```

### Unraid OS
For Unraid, the following plugins are required:
- **NerdTools plugin**: Provides access to `ipmitool`.
- **User Scripts plugin**: Enables you to schedule or run custom scripts on your Unraid server.

To install these:
1. Install the **NerdTools plugin** via the Unraid web GUI.
2. Install **ipmitool** via the NerdTools plugin.
3. Install **User Scripts** plugin via the Unraid web GUI to enable running the script at the start of the array.

## Features

- Fetches CPU temperature data from the server's IPMI sensor.
- Calculates fan speeds based on temperature thresholds.
- Adjusts fan speeds accordingly using raw IPMI commands.
- Displays real-time status of the CPU temperatures and fan speeds.

## Temperature and Fan Speed Mapping

The script adjusts the fan speed in hexadecimal values based on the following temperature thresholds:

- **Fan Speed** levels: 0%, 25%, 30%, 35%, 40%, 50%, 60%, 70%, 80%, 90%, and 100%.
- **Temperature thresholds**: 40°C, 45°C, 50°C, 55°C, 60°C, 65°C, 70°C, 75°C, 80°C, 85°C, 90°C, 95°C, and 100°C.

For example, if the CPU temperature is above 40°C but below 45°C, the fan speed is set to 25%. This process ensures that the system keeps the temperature within safe limits while avoiding unnecessary noise by adjusting fan speeds dynamically.

## How to Use

1. Ensure that `ipmitool` is installed and properly configured on your system.
2. Place the script in an executable location, e.g., `/usr/local/bin/ipmi_fan_control.sh`.
3. Make the script executable:
   ```bash
   chmod +x /usr/local/bin/ipmi_fan_control.sh
   ```
4. Run the script:
   ```bash
   ./ipmi_fan_control.sh
   ```

The script will continuously check the CPU temperature every 30 seconds and adjust the fan speeds based on predefined temperature-to-speed mappings.

## Script Breakdown

- **`fetch_ipmi_data()`**: Fetches and caches the current temperature data from IPMI.
- **`get_cpu_temperature(label)`**: Extracts the temperature for a specific CPU from the IPMI cache file.
- **`calculate_fan_speed(temp)`**: Determines the fan speed (in percentage) based on the CPU temperature.
- **`set_fan_speed(fan_bank, speed)`**: Sets the fan speed for a specific fan bank (either CPU 1 or CPU 2).
- **`display_status(cpu1_temp, cpu2_temp, fan1_speed, fan2_speed)`**: Displays the current CPU temperatures and fan speeds in the console.

## Troubleshooting

- **Failed to fetch IPMI data**: Ensure `ipmitool` is properly installed and your system's IPMI interface is accessible.
- **Failed to read CPU temperatures**: Check that your server's IPMI system is properly configured and can provide temperature data.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Notes:
- This README covers the basic setup instructions and the functionality of the script.
- It provides information on dependencies (like `ipmitool`) and system requirements (for Linux and Unraid).
- The script will continuously loop, fetching temperatures and adjusting fan speeds in real-time, with status messages printed to the console.
