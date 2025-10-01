#!/bin/bash

# Function to get local config directory
get_local_config_directory() {
    echo "$(get_project_dir)/config"
}

# Export function for use in other scripts
export -f get_local_config_directory
