#!/bin/bash

# Function to get base project directory
get_project_dir() {
    cargo locate-project --workspace --message-format=plain | xargs dirname
}

# Export function for use in other scripts
export -f get_project_dir
