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
    local value=$(grep "^${key} = " "$config_file" | sed 's/.*= *"\([^"]*\)".*/\1/')
    
    if [[ -n "$debug_suffix" && "$value" != *"$debug_suffix" ]]; then
        value="${value}${debug_suffix}"
    fi
    
    echo "$value"
}

# Export function for use in other scripts
export -f read_config_value
