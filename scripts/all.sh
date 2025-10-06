#!/bin/bash -e

# Set standard directory variables and source all functions
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
fi
for FUNC in "$SCRIPT_DIR/functions"/*.sh; do source "$FUNC"; done

echo "Running complete build, install, test, and run sequence..."

echo "1. Building..."
echo "Select build type:"
echo "1) Debug"
echo "2) Release"
read -p "Enter choice (1 or 2): " CHOICE

echo "$CHOICE" | "$SCRIPT_DIR/build.sh"

echo "2. Installing..."
echo "$CHOICE" | "$SCRIPT_DIR/install.sh"

echo "3. Testing..."
echo "$CHOICE" | "$SCRIPT_DIR/test.sh"

echo "4. Running service..."
echo "$CHOICE" | "$SCRIPT_DIR/run.sh"
