#!/bin/bash

# Function to get the install directory based on build mode
get_install_directory() {
    local BUILD_MODE="$1"
    
    # Check if this is a library project
    local PROJECT_TYPE=$(get_project_type)
    if [[ "$PROJECT_TYPE" == "lib" ]]; then
        echo "Error: No installation directory required for library projects. Libraries are used as dependencies." >&2
        return 1
    fi
    
    # Convert numeric choice to mode string
    if [[ "$BUILD_MODE" == "1" ]]; then
        BUILD_MODE="debug"
    elif [[ "$BUILD_MODE" == "2" ]]; then
        BUILD_MODE="release"
    fi
    
    # Use get_cargo_config_value to get install_dir from Cargo.toml metadata
    local INSTALL_DIR=$(get_cargo_config_value "metadata" "install_dir")
    local PROJECT_NAME=$(get_project_name)
    
    if [[ -z "$INSTALL_DIR" ]]; then
        echo "Error: install_dir not found in Cargo.toml metadata" >&2
        return 1
    fi
    
    # Build full path with project name and debug suffix
    if [[ "$BUILD_MODE" == "debug" ]]; then
        echo "${INSTALL_DIR}-debug/${PROJECT_NAME}-debug"
    else
        echo "$INSTALL_DIR/$PROJECT_NAME"
    fi
}

# Export function for use in other scripts
export -f get_install_directory
