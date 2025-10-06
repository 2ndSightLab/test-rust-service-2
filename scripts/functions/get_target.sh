#!/bin/bash

# Function to get target type (debug/release) from command line args or user input
get_target() {
    local DEBUG_CHOICE=1
    local RELEASE_CHOICE=2
    local CHOICE
    
    # Check for command line arguments or non-interactive mode
    if [[ "$1" == "--debug" ]] || [[ -n "$CI" ]]; then
        CHOICE=$DEBUG_CHOICE
    elif [[ "$1" == "--release" ]]; then
        CHOICE=$RELEASE_CHOICE
    elif [[ ! -t 0 ]]; then
        # Read from stdin when input is piped
        read CHOICE
    else
        echo "Select build type:"
        echo "1) Debug"
        echo "2) Release"
        read -p "Enter choice (1 or 2): " CHOICE
    fi
    
    # Validate and return choice
    case $CHOICE in
        1)
            echo "1"
            ;;
        2)
            echo "2"
            ;;
        *)
            echo "Invalid choice. Please enter 1 or 2." >&2
            return 1
            ;;
    esac
}

# Export function for use in other scripts
export -f get_target
