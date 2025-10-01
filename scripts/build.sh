#!/bin/bash

# Set standard directory variables and source all functions
SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"
for func in "$SCRIPTS_DIR/functions"/*.sh; do source "$func"; done
PROJECT_DIR=$(get_project_dir)

# Clean up any leftover cargo install temp directories
rm -rf /tmp/cargo-install* 2>/dev/null

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
    # Get project type, name, and base directory
    PROJECT_TYPE=$(get_project_type)
    PROJECT_NAME=$(get_project_name)
    
    get_build_artifact "$PROJECT_TYPE" "$choice" "$PROJECT_DIR" "$CURRENT_ARCH" "$PROJECT_NAME" "true"
else
    echo "Build failed!"
    exit 1
fi
