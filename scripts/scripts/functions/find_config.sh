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
    local PROJECT_NAME="$1"
    local BUILD_TYPE="$2"
    
    # Get project root directory
    local SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
    local PROJECT_ROOT=$(dirname "$(dirname "$SCRIPT_DIR")")
    
    # Determine project type by checking Cargo.toml
    local CARGO_TOML="$PROJECT_ROOT/Cargo.toml"
    local HAS_BIN=$(grep -q "^\[\[bin\]\]" "$CARGO_TOML" && echo "true" || echo "false")
    local HAS_LIB=$(grep -q "^\[lib\]" "$CARGO_TOML" && echo "true" || echo "false")
    
    # Set project type
    local PROJECT_TYPE
    if [[ "$HAS_BIN" == "true" ]]; then
        PROJECT_TYPE="service"
    elif [[ "$HAS_LIB" == "true" ]]; then
        PROJECT_TYPE="lib"
    fi
    
    # Set config file name based on project type
    local CONFIG_FILE_NAME="${PROJECT_TYPE}.toml"
    
    # Get local config file path
    local LOCAL_CONFIG_FILE="$PROJECT_ROOT/config/$CONFIG_FILE_NAME"
    
    # Get install directory from local config
    local INSTALL_DIRECTORY=$(grep "^INSTALL_DIR" "$LOCAL_CONFIG_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/')
    
    # Set config file path based on build type
    if [[ "$BUILD_TYPE" == "release" ]]; then
        echo "$INSTALL_DIRECTORY/$PROJECT_NAME/$CONFIG_FILE_NAME"
    else
        echo "$INSTALL_DIRECTORY/$PROJECT_NAME-debug/$CONFIG_FILE_NAME"
    fi
}

# Export functions for use in other scripts
export -f get_service_name
export -f find_config_file
