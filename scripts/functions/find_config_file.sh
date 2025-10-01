#!/bin/bash

# Function to find the config file location
find_config_file() {
    local PROJECT_NAME="$1"
    local BUILD_TYPE="$2"
    
    # Get project root directory using cargo (same as test.sh)
    local BASE_DIRECTORY=$(cargo locate-project --workspace --message-format=plain | xargs dirname)
    
    # Config directory has the local config
    local CONFIG_DIRECTORY="$BASE_DIRECTORY/config"
    
    # Check Cargo.toml for project type (same logic as test.sh)
    local CARGO_TOML="$BASE_DIRECTORY/Cargo.toml"
    local HAS_LIB=$(grep -q "^\[lib\]" "$CARGO_TOML" && echo "true" || echo "false")
    local HAS_BIN=$(grep -q "^\[\[bin\]\]" "$CARGO_TOML" && echo "true" || echo "false")
    
    # Set project type (same logic as test.sh)
    local PROJECT_TYPE
    if [[ "$HAS_BIN" == "true" ]]; then
        PROJECT_TYPE="service"
    elif [[ "$HAS_LIB" == "true" ]]; then
        PROJECT_TYPE="lib"
    fi
    
    # Set config file name (same as test.sh)
    local CONFIG_FILE_NAME="${PROJECT_TYPE}.toml"
    
    # Get local config file (same as test.sh)
    local LOCAL_CONFIG_FILE="$CONFIG_DIRECTORY/$CONFIG_FILE_NAME"
    
    # Get install directory (same as test.sh)
    local INSTALL_DIRECTORY=$(read_config_value "INSTALL_DIR" "$LOCAL_CONFIG_FILE")
    
    # Set config file path based on build type (same as test.sh)
    if [[ "$BUILD_TYPE" == "release" ]]; then
        echo "$INSTALL_DIRECTORY/$PROJECT_NAME/$CONFIG_FILE_NAME"
    else
        echo "$INSTALL_DIRECTORY/$PROJECT_NAME-debug/$CONFIG_FILE_NAME"
    fi
}

# Export functions for use in other scripts
export -f find_config_file
