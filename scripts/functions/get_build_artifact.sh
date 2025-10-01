#!/bin/bash

# Function to get and validate build artifacts
get_build_artifact() {
    local PROJECT_TYPE="$1"
    local BUILD_MODE="$2"  # "1" for debug, "2" for release
    local PROJECT_DIR="$3"
    local CURRENT_ARCH="$4"
    local PROJECT_NAME="$5"
    local VALIDATE_ONLY="$6"  # "true" to only validate, empty to return path
    
    if [[ "$PROJECT_TYPE" == "service" ]]; then
        # Service projects must produce an executable binary
        if [[ "$BUILD_MODE" == "1" ]]; then
            BINARY_PATH="$PROJECT_DIR/target/$CURRENT_ARCH/debug/$PROJECT_NAME"
        else
            BINARY_PATH="$PROJECT_DIR/target/$CURRENT_ARCH/release/$PROJECT_NAME"
        fi
        
        if [[ "$VALIDATE_ONLY" == "true" ]]; then
            echo "Binary created at: $BINARY_PATH"
            
            # Check if binary actually exists for service projects
            if [[ ! -f "$BINARY_PATH" ]]; then
                echo "Error: Expected binary not found at $BINARY_PATH. Service projects must produce an executable."
                exit 1
            fi
            
            # Check for action.toml in service projects
            ACTION_CONFIG=$(get_config_file "action.toml")
        else
            echo "$BINARY_PATH"
        fi
    elif [[ "$PROJECT_TYPE" == "lib" ]]; then
        # Library projects should produce library artifacts
        if [[ "$BUILD_MODE" == "1" ]]; then
            LIB_PATH="$PROJECT_DIR/target/$CURRENT_ARCH/debug/lib*.rlib"
        else
            LIB_PATH="$PROJECT_DIR/target/$CURRENT_ARCH/release/lib*.rlib"
        fi
        
        if [[ "$VALIDATE_ONLY" == "true" ]]; then
            if ! ls $LIB_PATH 1> /dev/null 2>&1; then
                echo "Error: Expected library artifact not found at $LIB_PATH. Library projects must produce a library."
                exit 1
            fi
            echo "Library artifacts found at: $LIB_PATH"
        else
            echo "$LIB_PATH"
        fi
    else
        echo "Error: Unknown project type. Cannot determine expected build artifacts."
        exit 1
    fi
}

# Export function for use in other scripts
export -f get_build_artifact
