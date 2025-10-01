#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Clean up any leftover cargo install temp directories
rm -rf /tmp/cargo-install* 2>/dev/null

# Source config reading functions
source "$SCRIPT_DIR/functions/read_config.sh"
source "$SCRIPT_DIR/functions/find_config.sh"

# Get current architecture
CURRENT_ARCH=$(rustc --version --verbose | grep host | cut -d' ' -f2)

echo "Building for architecture: $CURRENT_ARCH"
# Check for command line arguments or non-interactive mode
if [[ "$1" == "--debug" ]] || [[ -n "$CI" ]] || [[ ! -t 0 ]]; then
    choice=1
elif [[ "$1" == "--release" ]]; then
    choice=2
else
    echo "Select build type:"
    echo "1) Debug (all binaries including tests, examples, and benchmarks)"
    echo "2) Release"
    read -p "Enter choice (1 or 2): " choice
fi

case $choice in
    1)
        echo "Building in debug mode..."
        echo "Building everything (main binary, tests, examples, benchmarks)..."
        cargo build --all-targets --target $CURRENT_ARCH
        ;;
    2)
        echo "Building in release mode..."
        cargo build --release --target $CURRENT_ARCH
        ;;
    *)
        echo "Invalid choice. Please enter 1 or 2."
        exit 1
        ;;
esac

if [ $? -eq 0 ]; then
    echo "Build completed successfully!"
    
    # Validate that the correct artifacts were created based on project type
    # Service projects (service.toml) must produce an executable binary
    # Library projects (lib.toml) don't require binaries
    SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
    source "$SCRIPT_DIR/functions/read_config.sh"
    source "$SCRIPT_DIR/functions/find_config.sh"
    CONFIG_FILE=$(find_config_file "service.toml")
    if [[ $? -eq 0 ]]; then
        SERVICE_NAME=$(grep "^SERVICE_NAME" "$CONFIG_FILE" | sed 's/SERVICE_NAME = "\(.*\)"/\1/' | tr -d '"')
        if [[ "$choice" == "1" ]]; then
            BINARY_PATH="target/$CURRENT_ARCH/debug/$SERVICE_NAME"
        else
            BINARY_PATH="target/$CURRENT_ARCH/release/$SERVICE_NAME"
        fi
        echo "Binary created at: $BINARY_PATH"
        
        # Check if binary actually exists for service projects
        if [[ ! -f "$BINARY_PATH" ]]; then
            echo "Error: Expected binary not found at $BINARY_PATH. Service projects must produce an executable."
            exit 1
        fi
        
        # Check for action.toml in service projects
        ACTION_CONFIG=$(find_config_file "action.toml")
        if [[ $? -ne 0 ]]; then
            echo "Error: No action.toml configuration file found. Service projects require action configuration."
            exit 1
        fi
    else
        # Check for lib.toml (library projects don't need binaries but should have library artifacts)
        LIB_CONFIG=$(find_config_file "lib.toml")
        if [[ $? -eq 0 ]]; then
            # For library projects, check that library artifact exists
            if [[ "$choice" == "1" ]]; then
                LIB_PATH="target/$CURRENT_ARCH/debug/lib*.rlib"
            else
                LIB_PATH="target/$CURRENT_ARCH/release/lib*.rlib"
            fi
            
            if ! ls $LIB_PATH 1> /dev/null 2>&1; then
                echo "Error: Expected library artifact not found at $LIB_PATH. Library projects must produce a library."
                exit 1
            fi
            echo "Library artifacts found at: $LIB_PATH"
        else
            echo "Error: No service.toml or lib.toml configuration file found. Cannot determine expected build artifacts."
            exit 1
        fi
    fi
else
    echo "Build failed!"
    exit 1
fi
