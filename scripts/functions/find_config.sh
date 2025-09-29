#!/bin/bash

# Function to get SERVICE_NAME from config file
get_service_name() {
    # First try to find service.toml in standard locations
    local CONFIG_PATHS=(
        "/etc/service.toml"
        "/opt/service.toml"
        "/usr/local/etc/service.toml"
        "config/service.toml"
    )
    
    for PATH in "${CONFIG_PATHS[@]}"; do
        if [[ -f "$PATH" ]]; then
            # Extract SERVICE_NAME from TOML file
            SERVICE_NAME=$(/usr/bin/grep '^SERVICE_NAME' "$PATH" | /usr/bin/sed 's/SERVICE_NAME = "\(.*\)"/\1/' | /usr/bin/tr -d '"')
            if [[ -n "$SERVICE_NAME" ]]; then
                echo "$SERVICE_NAME"
                return 0
            fi
        fi
    done
    
    echo "Error: Could not find SERVICE_NAME in config files" >&2
    return 1
}

# Function to find the config file location
find_config_file() {
    local CONFIG_NAME="$1"
    local ADDITIONAL_PATH1="$2"
    local ADDITIONAL_PATH2="$3"
    
    # Default to service.toml if no name provided
    if [[ -z "$CONFIG_NAME" ]]; then
        CONFIG_NAME="service.toml"
    fi
    
    # Check additional paths first if provided
    if [[ -n "$ADDITIONAL_PATH1" && -f "$ADDITIONAL_PATH1/$CONFIG_NAME" ]]; then
        echo "$ADDITIONAL_PATH1/$CONFIG_NAME"
        return 0
    fi
    
    if [[ -n "$ADDITIONAL_PATH2" && -f "$ADDITIONAL_PATH2/$CONFIG_NAME" ]]; then
        echo "$ADDITIONAL_PATH2/$CONFIG_NAME"
        return 0
    fi
    
    # Use local config directory
    local SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
    local PROJECT_ROOT=$(dirname "$(dirname "$SCRIPT_DIR")")
    local LOCAL_CONFIG="$PROJECT_ROOT/config/$CONFIG_NAME"
    
    if [[ -f "$LOCAL_CONFIG" ]]; then
        echo "$LOCAL_CONFIG"
        return 0
    fi
    
    echo "Error: Config file $CONFIG_NAME not found in local config directory" >&2
    return 1
}

# Export functions for use in other scripts
export -f get_service_name
export -f find_config_file
