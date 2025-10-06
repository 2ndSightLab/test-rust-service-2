#!/bin/bash

# Function to get local config file path
get_local_config_file() {
    local LOCAL_CONFIG_DIR=$(get_local_config_directory)
    local PROJECT_DIR=$(cargo locate-project --workspace --message-format=plain | xargs dirname)
    
    if grep -q "^\[\[bin\]\]" "$PROJECT_DIR/Cargo.toml"; then
        echo "$LOCAL_CONFIG_DIR/service.toml"
    else
        echo "$LOCAL_CONFIG_DIR/service.toml"
    fi
}

# Export function for use in other scripts
export -f get_local_config_file
