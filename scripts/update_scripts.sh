#!/bin/bash

# Set standard directory variables and source all functions
SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"
for func in "$SCRIPTS_DIR/functions"/*.sh; do source "$func"; done
PROJECT_DIR=$(get_project_dir)

# Get rust_service_path from Cargo.toml
RUST_SERVICE_PATH=$(get_cargo_config_value "metadata" "rust_service_path")

if [[ -z "$RUST_SERVICE_PATH" ]]; then
    echo "Error: rust_service_path not found in Cargo.toml"
    exit 1
fi

RUST_SERVICE_FULL_PATH="$PROJECT_DIR/$RUST_SERVICE_PATH"

if [[ ! -d "$RUST_SERVICE_FULL_PATH" ]]; then
    echo "Error: rust-service directory not found at $RUST_SERVICE_FULL_PATH"
    exit 1
fi

# Copy scripts from rust-service to PROJECT_DIR
echo "Copying scripts from $RUST_SERVICE_FULL_PATH to $PROJECT_DIR..."
cp -r "$RUST_SERVICE_FULL_PATH/scripts" "$PROJECT_DIR/"

echo "Scripts copied successfully!"
