#!/bin/bash

# Function to get the config file location
get_config_file() {
    local PROJECT_NAME="$1"
    local BUILD_TYPE="$2"
    
    # Get project root directory using cargo (same as test.sh)
    local PROJECT_DIR=$(get_project_dir)
    
    # Config directory has the local config
    local CONFIG_DIRECTORY="$PROJECT_DIR/config"
    
    # Check Cargo.toml for project type (same logic as test.sh)
    local CARGO_TOML="$PROJECT_DIR/Cargo.toml"
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
    
    # Get install directory using the function
    local INSTALL_DIRECTORY=$(get_install_directory "$BUILD_TYPE")
    
    # Set config file path
    echo "$INSTALL_DIRECTORY/$CONFIG_FILE_NAME"
}

# Export functions for use in other scripts
export -f get_config_file
