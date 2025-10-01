#!/bin/bash

# Function to get script directory
get_script_directory() {
    echo "$(get_project_dir)/scripts"
}

# Export function for use in other scripts
export -f get_script_directory
