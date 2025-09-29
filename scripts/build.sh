#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

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
else
    echo "Build failed!"
    exit 1
fi
