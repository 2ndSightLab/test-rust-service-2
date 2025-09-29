#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Source config reading functions
source "$SCRIPT_DIR/functions/read_config.sh"
source "$SCRIPT_DIR/functions/find_config.sh"

# Validate running as appropriate user (not root for safety)
if [[ $EUID -eq 0 ]]; then
    echo "Warning: Running as root. This script will use sudo for privileged operations."
fi

# Check for command line arguments or non-interactive mode
if [[ "$1" == "--debug" ]] || [[ -n "$CI" ]] || [[ ! -t 0 ]]; then
    choice=1
elif [[ "$1" == "--release" ]]; then
    choice=2
else
    echo "Select binary type to install:"
    echo "1) Debug (all binaries including tests, examples, and benchmarks)"
    echo "2) Release"
    read -p "Enter choice (1 or 2): " choice
fi

case $choice in
    1)
        BINARY_TYPE="debug"
        DEBUG_SUFFIX="-debug"
        ;;
    2)
        BINARY_TYPE="release"
        DEBUG_SUFFIX=""
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

BINARY_PATH="target/$CURRENT_ARCH/$BINARY_TYPE/$SERVICE_NAME"

# Read directories from config file
INSTALL_DIR=$(read_config_value "INSTALL_DIR" "$CONFIG_FILE" "$DEBUG_SUFFIX")
LOG_DIR=$(read_config_value "LOG_FILE_PATH" "$CONFIG_FILE" "$DEBUG_SUFFIX")
CONFIG_DIR="$INSTALL_DIR"
SERVICE_NAME=$(read_config_value "SERVICE_NAME" "$CONFIG_FILE")

# Set service user based on debug mode
if [[ "$choice" == "1" ]]; then
    SERVICE_USER="$SERVICE_NAME-debug"
else
    SERVICE_USER="$SERVICE_NAME"
fi

echo "Installing $SERVICE_NAME ($BINARY_TYPE)..."
echo "Install dir: $INSTALL_DIR"
echo "Config dir: $CONFIG_DIR"
echo "Log dir: $LOG_DIR"

# Validate binary exists before installation
if [[ ! -f "$BINARY_PATH" ]]; then
    echo "Error: Binary not found at $BINARY_PATH. Run './scripts/build.sh' first."
    exit 1
fi

# Create service user with restricted shell
if ! id "$SERVICE_USER" &>/dev/null; then
    echo "Creating service user: $SERVICE_USER"
    sudo useradd --system --no-create-home --shell /bin/false --home-dir "$INSTALL_DIR" "$SERVICE_USER"
fi

# Create directories
echo "Creating directories..."
sudo mkdir -p "$INSTALL_DIR"
sudo mkdir -p "$LOG_DIR"

# Copy binary
echo "Installing binary..."
sudo cp "$BINARY_PATH" "$INSTALL_DIR/"
sudo chmod +x "$INSTALL_DIR/$SERVICE_NAME"

# Copy config (only if source and destination are different)
echo "Installing configuration..."
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
LOCAL_CONFIG="$PROJECT_ROOT/config/service.toml"

if [[ -f "$LOCAL_CONFIG" ]]; then
    sudo cp "$LOCAL_CONFIG" "$CONFIG_DIR/"
else
    echo "Error: Local config file not found at $LOCAL_CONFIG"
    exit 1
fi

# Also install action config from local directory
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
LOCAL_ACTION_CONFIG="$PROJECT_ROOT/config/action.toml"
if [[ -f "$LOCAL_ACTION_CONFIG" ]]; then
    sudo cp "$LOCAL_ACTION_CONFIG" "$CONFIG_DIR/"
fi

# Set ownership
echo "Setting permissions..."
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$LOG_DIR"
sudo chown root:root "$CONFIG_DIR/service.toml"
sudo chmod 644 "$CONFIG_DIR/service.toml"

# Set permissions for action config if it exists
if [[ -f "$CONFIG_DIR/action.toml" ]]; then
    sudo chown root:root "$CONFIG_DIR/action.toml"
    sudo chmod 644 "$CONFIG_DIR/action.toml"
fi
sudo chown root:root "$CONFIG_DIR/service.toml"
sudo chmod 644 "$CONFIG_DIR/service.toml"

# Set permissions for action config if it exists
if [[ -f "$CONFIG_DIR/action.toml" ]]; then
    sudo chown root:root "$CONFIG_DIR/action.toml"
    sudo chmod 644 "$CONFIG_DIR/action.toml"
fi

echo "Installation complete!"
echo "Binary: $INSTALL_DIR/$SERVICE_NAME"
echo "Config: $CONFIG_DIR/service.toml"
echo "Logs: $LOG_DIR/"
echo ""
echo "To run: sudo -u $SERVICE_USER $INSTALL_DIR/$SERVICE_NAME"
