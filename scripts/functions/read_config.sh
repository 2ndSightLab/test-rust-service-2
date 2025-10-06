#!/bin/bash

# Function to read config value from TOML file
read_config_value() {
    local key="$1"
    local config_file="$2"
    local debug_suffix="$3"
    
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Config file not found: $config_file" >&2
        return 1
    fi
    
    # Read the value and apply debug suffix if needed
    local VALUE=$(grep "^${key} = " "$config_file" | sed 's/.*= *"\([^"]*\)".*/\1/')
    
    if [[ -n "$debug_suffix" && "$VALUE" != *"$debug_suffix" ]]; then
        VALUE="${VALUE}${debug_suffix}"
    fi
    
    echo "$VALUE"
}

# Export function for use in other scripts
export -f read_config_value
