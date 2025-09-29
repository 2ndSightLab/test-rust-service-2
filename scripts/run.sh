#!/bin/bash
set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
SCRIPT_DIR_RELATIVE=$(dirname "$0")

# Source config reading functions
source "$SCRIPT_DIR/functions/read_config.sh"
source "$SCRIPT_DIR/functions/find_config.sh"

echo "Select binary type to run:"
echo "1) Debug"
echo "2) Release"
read -p "Enter choice (1 or 2): " choice

case $choice in
    1)
        DEBUG_SUFFIX="-debug"
        BUILD_TYPE="debug"
        ;;
    2)
        DEBUG_SUFFIX=""
        BUILD_TYPE="release"
        ;;
    *)
        echo "Invalid choice. Please enter 1 or 2."
        exit 1
        ;;
esac

# Find config file
CONFIG_FILE=$(find_config_file "service.toml")
if [[ $? -ne 0 ]]; then
    exit 1
fi

# Read service name from config
SERVICE_NAME=$(grep "^SERVICE_NAME" "$CONFIG_FILE" | sed 's/SERVICE_NAME = "\(.*\)"/\1/' | tr -d '"')

# Get current architecture
CURRENT_ARCH=$(rustc --version --verbose | grep host | cut -d' ' -f2)

# Check if binary exists, if not build it
BINARY_PATH="target/$CURRENT_ARCH/$BUILD_TYPE/$SERVICE_NAME"
if [[ ! -f "$BINARY_PATH" ]]; then
    echo "Binary not found at $BINARY_PATH, building..."
    echo "$choice" | "$SCRIPT_DIR_RELATIVE"/build.sh
fi

# Set service user based on debug mode
if [[ "$choice" == "1" ]]; then
    SERVICE_USER="$SERVICE_NAME-debug"
else
    SERVICE_USER="$SERVICE_NAME"
fi

# First run the install.sh script
echo "$choice" | "$SCRIPT_DIR_RELATIVE"/install.sh

# Read directories from config file
INSTALL_DIR=$(read_config_value "INSTALL_DIR" "$CONFIG_FILE" "$DEBUG_SUFFIX")
CONFIG_DIR=$(read_config_value "CONFIG_DIR" "$CONFIG_FILE" "$DEBUG_SUFFIX")

# Validate target user exists and has correct setup
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "Error: $SERVICE_USER user does not exist"
    exit 1
fi

# Verify binary exists and is executable
if [[ ! -x "$INSTALL_DIR/$SERVICE_NAME" ]]; then
    echo "Error: Service binary not found or not executable at $INSTALL_DIR/$SERVICE_NAME"
    exit 1
fi

# Verify config file exists and has correct permissions
if [[ ! -f "$CONFIG_DIR/service.toml" ]]; then
    echo "Error: Config file not found at $CONFIG_DIR/service.toml"
    exit 1
fi

# Check config file permissions (should not be world-writable)
if [[ $(stat -c "%a" "$CONFIG_DIR/service.toml") -gt 644 ]]; then
    echo "Error: Config file has insecure permissions"
    exit 1
fi

# Run the program with validated user
echo "Starting service..."
sudo -u "$SERVICE_USER" "$INSTALL_DIR/$SERVICE_NAME"
