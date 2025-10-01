#!/bin/bash

# Function to get project name from Cargo.toml
get_project_name() {
    # Get project type
    local PROJECT_TYPE=$(get_project_type)
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Get project name from Cargo.toml based on type
    local PROJECT_NAME
    if [[ "$PROJECT_TYPE" == "service" ]]; then
        PROJECT_NAME=$(get_cargo_config_value "package" "name")
    elif [[ "$PROJECT_TYPE" == "lib" ]]; then
        # For libraries, get the lib target name specifically
        PROJECT_NAME=$(cargo metadata --format-version 1 --no-deps | jq -r '.packages[0].targets[] | select(.kind[] == "lib") | .name')
    fi
    
    # Error if name not found
    if [[ -z "$PROJECT_NAME" ]]; then
        echo "ERROR: No name found in Cargo.toml for the configured section." >&2
        if [[ "$PROJECT_TYPE" == "service" ]]; then
            echo "Add name to your [[bin]] section:" >&2
            echo "[[bin]]" >&2
            echo "name = \"your-app-name\"" >&2
            echo "path = \"src/main.rs\"" >&2
        elif [[ "$PROJECT_TYPE" == "lib" ]]; then
            echo "Add name to your [lib] section:" >&2
            echo "[lib]" >&2
            echo "name = \"your_lib_name\"" >&2
            echo "path = \"src/lib.rs\"" >&2
        fi
        return 1
    fi
    
    echo "$PROJECT_NAME"
}

# Export function for use in other scripts
export -f get_project_name
