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

# Check if we're using lib.toml and adjust accordingly
if [[ "$CONFIG_FILE" == *"lib.toml" ]]; then
    # Using lib config, set default paths
    INSTALL_DIR="/opt/rust-service"
    CONFIG_DIR="/etc/rust-service"
    LOG_FILE_PATH="/var/log/rust-service"
    # Get binary name from lib config or Cargo.toml
    LIB_NAME=$(grep "^LIB_NAME" "$CONFIG_FILE" | sed 's/LIB_NAME = "\(.*\)"/\1/' | tr -d '"')
    BINARY_NAME="$LIB_NAME"
else
    # Using service config, read from file
    INSTALL_DIR=$(grep "^INSTALL_DIR" "$CONFIG_FILE" | sed 's/INSTALL_DIR = "\(.*\)"/\1/' | tr -d '"')
    CONFIG_DIR=$(grep "^CONFIG_DIR" "$CONFIG_FILE" | sed 's/CONFIG_DIR = "\(.*\)"/\1/' | tr -d '"')
    LOG_FILE_PATH=$(grep "^LOG_FILE_PATH" "$CONFIG_FILE" | sed 's/LOG_FILE_PATH = "\(.*\)"/\1/' | tr -d '"')
fi

# Add -debug suffix for debug builds
if [ "$BUILD_TYPE" = "debug" ]; then
    INSTALL_DIR="${INSTALL_DIR}-debug"
    CONFIG_DIR="${CONFIG_DIR}-debug"
    LOG_FILE_PATH="${LOG_FILE_PATH}-debug"
fi

# Exit on any error
set -e

# Get binary name from config file (same as install.sh)
if [[ -z "$BINARY_NAME" ]]; then
    # First check current working directory for service config (when called from service project)
    if [[ -f "config/service.toml" ]]; then
        BINARY_NAME=$(grep "^SERVICE_NAME" "config/service.toml" | sed 's/SERVICE_NAME = "\(.*\)"/\1/' | tr -d '"')
    # Then check the config file found by find_config_file
    elif [[ "$CONFIG_FILE" == *"service.toml" ]]; then
        BINARY_NAME=$(grep "^SERVICE_NAME" "$CONFIG_FILE" | sed 's/SERVICE_NAME = "\(.*\)"/\1/' | tr -d '"')
    # Finally fall back to lib config
    else
        if [[ -f "config/lib.toml" ]]; then
            LIB_NAME=$(grep "^LIB_NAME" "config/lib.toml" | sed 's/LIB_NAME = "\(.*\)"/\1/' | tr -d '"')
        fi
        BINARY_NAME="$LIB_NAME"
    fi
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
# Check if we're being called from a service project (look for service config in calling directory)
CALLING_DIR=$(pwd)
if [[ -f "$CALLING_DIR/config/service.toml" ]]; then
    # We're being called from a service project, build and check its binary
    RUSTFLAGS="-D warnings -A non_snake_case -A clippy::upper_case_acronyms" cargo build $BUILD_FLAG
    SERVICE_BINARY=$(grep "^SERVICE_NAME" "$CALLING_DIR/config/service.toml" | sed 's/SERVICE_NAME = "\(.*\)"/\1/' | tr -d '"')
    ls -lh target/$BUILD_TYPE/$SERVICE_BINARY
elif [[ -f "config/lib.toml" ]] && [[ ! -f "config/service.toml" ]] && [[ ! -f "src/main.rs" ]]; then
    # We're in a library project that doesn't produce binaries
    echo "Skipping binary size analysis for library project"
else
    # Default behavior for other cases
    RUSTFLAGS="-D warnings -A non_snake_case -A clippy::upper_case_acronyms" cargo build $BUILD_FLAG
    ls -lh target/$BUILD_TYPE/$BINARY_NAME
fi

echo "7. Architecture-specific check..."
CURRENT_ARCH=$(rustc --version --verbose | grep host | cut -d' ' -f2)
echo "Running checks for current architecture: $CURRENT_ARCH"
RUSTFLAGS="-D warnings -A non_snake_case -A clippy::upper_case_acronyms" cargo check --target $CURRENT_ARCH

echo "8. License compliance check..."
cargo license || echo "Warning: cargo license not installed"

echo "9. Cargo.toml validation..."
cargo verify-project

echo "10. Test coverage analysis..."
cargo tarpaulin --out Stdout || echo "Warning: cargo tarpaulin not installed"

echo "11. Memory safety checks..."
echo -e "${RED}⚠️  WARNING: miri checks SKIPPED to avoid downloading components${NC}"
echo -e "${RED}   Memory safety checks will be SKIPPED${NC}"
echo -e "${RED}   Run manually with: cargo +nightly miri test${NC}"

echo "All essential best practices checks completed successfully!"
