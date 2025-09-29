#!/bin/bash

echo "Running Rust Best Practices Check"
echo "================================="

# Ask user for build type
echo "Select build type:"
echo "1) Debug"
echo "2) Release"
read -p "Enter choice (1 or 2): " choice

case $choice in
    1)
        BUILD_TYPE="debug"
        BUILD_FLAG=""
        ;;
    2)
        BUILD_TYPE="release"
        BUILD_FLAG="--release"
        ;;
    *)
        echo "Invalid choice. Defaulting to Debug."
        BUILD_TYPE="debug"
        BUILD_FLAG=""
        ;;
esac

echo "Using $BUILD_TYPE build..."

# Read directory paths from config file
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Source config reading functions
source "$SCRIPT_DIR/functions/find_config.sh"

# Find config file
CONFIG_FILE=$(find_config_file "service.toml")
if [[ $? -ne 0 ]]; then
    exit 1
fi

INSTALL_DIR=$(grep "^INSTALL_DIR" "$CONFIG_FILE" | sed 's/INSTALL_DIR = "\(.*\)"/\1/' | tr -d '"')
CONFIG_DIR=$(grep "^CONFIG_DIR" "$CONFIG_FILE" | sed 's/CONFIG_DIR = "\(.*\)"/\1/' | tr -d '"')
LOG_FILE_PATH=$(grep "^LOG_FILE_PATH" "$CONFIG_FILE" | sed 's/LOG_FILE_PATH = "\(.*\)"/\1/' | tr -d '"')

# Add -debug suffix for debug builds
if [ "$BUILD_TYPE" = "debug" ]; then
    INSTALL_DIR="${INSTALL_DIR}-debug"
    CONFIG_DIR="${CONFIG_DIR}-debug"
    LOG_FILE_PATH="${LOG_FILE_PATH}-debug"
fi

# Exit on any error
set -e

# Get binary name from Cargo.toml
BINARY_NAME=$(grep -A 10 "^\[\[bin\]\]" Cargo.toml | grep "^name" | head -1 | sed 's/name = "\(.*\)"/\1/' | tr -d '"')
if [ -z "$BINARY_NAME" ]; then
    # Fallback to package name if no explicit binary name
    BINARY_NAME=$(grep "^name" Cargo.toml | head -1 | sed 's/name = "\(.*\)"/\1/' | tr -d '"')
fi

echo "1. Code formatting check..."
cargo fmt --check

echo "2. Clippy linting (all levels) - DENY ALL WARNINGS except naming..."
cargo clippy --all-targets --all-features -- -D warnings -W clippy::all -W clippy::pedantic -W clippy::nursery -A non_snake_case -A clippy::upper_case_acronyms

echo "3. Documentation generation..."
RUSTDOCFLAGS="-D warnings -A non_snake_case -A clippy::upper_case_acronyms" cargo doc --no-deps --document-private-items

echo "4. Dead code detection - DENY ALL WARNINGS except naming..."
RUSTFLAGS="-D warnings -A non_snake_case -A clippy::upper_case_acronyms" cargo check

echo "5. Dependency tree analysis..."
cargo tree --duplicates

echo "6. Binary size analysis..."
RUSTFLAGS="-D warnings -A non_snake_case -A clippy::upper_case_acronyms" cargo build --release
ls -lh target/release/$BINARY_NAME

echo "7. Architecture-specific check..."
CURRENT_ARCH=$(rustc --version --verbose | grep host | cut -d' ' -f2)
echo "Running checks for current architecture: $CURRENT_ARCH"
RUSTFLAGS="-D warnings -A non_snake_case -A clippy::upper_case_acronyms" cargo check --target $CURRENT_ARCH

echo "All essential best practices checks completed successfully!"
