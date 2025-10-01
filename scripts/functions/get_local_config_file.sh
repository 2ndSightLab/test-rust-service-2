#!/bin/bash

# Function to get local config file path
get_local_config_file() {
    local LOCAL_CONFIG_DIR=$(get_local_config_directory)
    local PROJECT_TYPE=$(get_project_type)
    
    if [[ "$PROJECT_TYPE" == "service" ]]; then
        echo "$LOCAL_CONFIG_DIR/service.toml"
    else
        echo "$LOCAL_CONFIG_DIR/lib.toml"
    fi
}

# Export function for use in other scripts
export -f get_local_config_file
