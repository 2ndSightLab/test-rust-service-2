#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Source config reading functions
source "$SCRIPT_DIR/functions/read_config.sh"
source "$SCRIPT_DIR/functions/find_config.sh"

echo "Running Rust Service Test Suite"
echo "==============================="

# Check for command line arguments or non-interactive mode
if [[ "$1" == "--debug" ]] || [[ -n "$CI" ]] || [[ ! -t 0 ]]; then
    choice=1
elif [[ "$1" == "--release" ]]; then
    choice=2
else
    echo "Select build type:"
    echo "1) Debug"
    echo "2) Release"
    read -p "Enter choice (1 or 2): " choice
fi

case $choice in
    1)
        BUILD_TYPE="debug"
        DIR_SUFFIX="-debug"
        ;;
    2)
        BUILD_TYPE="release"
        DIR_SUFFIX=""
        ;;
    *)
        echo "Invalid choice. Please enter 1 or 2."
        exit 1
        ;;
esac

# Find config file based on build type
if [[ "$BUILD_TYPE" == "debug" ]]; then
    CONFIG_FILE=$(find_config_file "service.toml" "/etc/rust-service-debug" "/opt/rust-service-debug")
else
    CONFIG_FILE=$(find_config_file "service.toml")
fi

# If no installed config found, use local config
if [[ $? -ne 0 ]] || [[ ! -f "$CONFIG_FILE" ]]; then
    PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
    CONFIG_FILE="$PROJECT_ROOT/config/service.toml"
fi

# Read service name from config
SERVICE_NAME=$(read_config_value "SERVICE_NAME" "$CONFIG_FILE")

echo "Building $BUILD_TYPE binaries..."

echo "Building $BUILD_TYPE binaries..."
./scripts/build.sh --debug

echo "Installing $BUILD_TYPE binaries..."
./scripts/install.sh --debug

echo "Running all tests..."

# Dynamically discover and run all test files (top-level only)
TEST_FILES=($(find tests -maxdepth 1 -name "*.rs" -type f 2>/dev/null | sed 's|tests/||' | sed 's|\.rs$||' | sort))

for TEST_FILE in "${TEST_FILES[@]}"; do
    if [[ -n "$TEST_FILE" ]]; then
        echo "Running ${TEST_FILE} tests..."
        if [[ "$TEST_FILE" == "integration" ]]; then
            timeout 60s cargo test --test "$TEST_FILE" -- --test-threads=1 2>&1 | while read -r line; do
                if [[ "$line" == *"... ok" ]]; then
                    echo -e "${line% ok} ${GREEN}ok${NC}"
                elif [[ "$line" == *"... FAILED" ]]; then
                    echo -e "${line% FAILED} ${RED}FAILED${NC}"
                else
                    echo "$line"
                fi
            done
        else
            cargo test --test "$TEST_FILE" 2>&1 | while read -r line; do
                if [[ "$line" == *"... ok" ]]; then
                    echo -e "${line% ok} ${GREEN}ok${NC}"
                elif [[ "$line" == *"... FAILED" ]]; then
                    echo -e "${line% FAILED} ${RED}FAILED${NC}"
                else
                    echo "$line"
                fi
            done
        fi
    fi
done

# Calculate totals dynamically
TOTAL_PASSED=0
TOTAL_FAILED=0

echo ""
echo "Test Results Summary:"
echo "===================="

# Calculate results for each test file
for TEST_FILE in "${TEST_FILES[@]}"; do
    if [[ -n "$TEST_FILE" ]]; then
        if [[ "$TEST_FILE" == "integration" ]]; then
            TEST_OUTPUT=$(timeout 60s cargo test --test "$TEST_FILE" -- --test-threads=1 2>&1)
        else
            TEST_OUTPUT=$(cargo test --test "$TEST_FILE" 2>&1)
        fi
        TEST_PASSED=$(echo "$TEST_OUTPUT" | grep -o '[0-9]\+ passed' | head -1 | grep -o '[0-9]\+' || echo "0")
        TEST_FAILED=$(echo "$TEST_OUTPUT" | grep -o '[0-9]\+ failed' | head -1 | grep -o '[0-9]\+' || echo "0")
        
        TOTAL_PASSED=$((TOTAL_PASSED + TEST_PASSED))
        TOTAL_FAILED=$((TOTAL_FAILED + TEST_FAILED))
        
        # Display result for this test file
        TEST_NAME=$(echo "${TEST_FILE}" | sed 's/_/ /g' | sed 's/\b\w/\U&/g')
        if [[ $TEST_FAILED -eq 0 ]]; then
            echo -e "✅ ${TEST_NAME}: ${GREEN}PASSED${NC} ($TEST_PASSED passed, $TEST_FAILED failed)"
        else
            echo -e "❌ ${TEST_NAME}: ${RED}FAILED${NC} ($TEST_PASSED passed, $TEST_FAILED failed)"
        fi
    fi
done

echo ""

# Overall result
if [ $TOTAL_FAILED -eq 0 ]; then
    echo -e "✅ All Tests: ${GREEN}PASSED${NC} ($TOTAL_PASSED passed, $TOTAL_FAILED failed)"
    exit 0
else
    echo -e "❌ All Tests: ${RED}FAILED${NC} ($TOTAL_PASSED passed, $TOTAL_FAILED failed)"
    exit 1
fi
