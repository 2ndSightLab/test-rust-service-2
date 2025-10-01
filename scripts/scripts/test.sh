#!/bin/bash

# Clean up any leftover cargo install temp directories
rm -rf /tmp/cargo-install* 2>/dev/null

# Colors
GREEN='\033[0;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Function to format test output with colors
format_test_output() {
    while read -r line; do
        if [[ "$line" == *"... ok" ]]; then
            echo -e "${line% ok} ${GREEN}ok${NC}"
        elif [[ "$line" == *"... FAILED" ]]; then
            echo -e "${line% FAILED} ${RED}FAILED${NC}"
        else
            echo "$line"
        fi
    done
}

# Function to run a test and format output
run_test() {
    local test_file="$1"
    local is_local="${2:-local}"
    local test_category="${3:-unit_tests}"

    echo "Executing test file: $test_file"
    echo "Location: $is_local"
    echo "Category: $test_category"
    
    local test_output
    if [[ "$test_file" == "integration" ]]; then
        test_output=$(timeout 60s cargo test --test "$test_file" -- --test-threads=1 2>&1 | format_test_output)
    else
        test_output=$(cargo test --test "$test_file" 2>&1 | format_test_output)
    fi
    
    echo "$test_output"
    count_test_result "$test_output" "$is_local" "$test_category"
}

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Source config reading functions
source "$SCRIPT_DIR/functions/read_config.sh"
source "$SCRIPT_DIR/functions/find_config.sh"
source "$SCRIPT_DIR/functions/test_counter.sh"

# Function to check for required dependencies
check_dependencies() {
    local missing_deps=()
    local tarpaulin_missing=false
    local miri_missing=false
    
    # Check for cargo subcommands required by best-practices.sh
    if ! cargo --list | grep -q "license"; then
        missing_deps+=("cargo-license")
    fi
    
    if ! cargo --list | grep -q "tarpaulin"; then
        tarpaulin_missing=true
    fi
    
    # Check for miri component (check both stable and nightly)
    if ! rustup component list | grep -q "miri.*installed" && ! rustup component list --toolchain nightly 2>/dev/null | grep -q "miri.*installed"; then
        miri_missing=true
    fi
    
    # Show warning for tarpaulin if missing
    if [[ "$tarpaulin_missing" == true ]]; then
        echo -e "${RED}⚠️  WARNING: cargo-tarpaulin is not installed!${NC}"
        echo -e "${RED}   Code coverage analysis will be SKIPPED${NC}"
        echo -e "${RED}   Install with: cargo install cargo-tarpaulin${NC}"
        echo ""
    fi
    
    # Show warning for miri if missing
    if [[ "$miri_missing" == true ]]; then
        echo -e "${RED}⚠️  WARNING: miri is not installed!${NC}"
        echo -e "${RED}   Memory safety checks will be SKIPPED${NC}"
        echo -e "${RED}   Install with: rustup component add miri${NC}"
        echo ""
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required dependencies for full test suite:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "  - $dep"
        done
        echo ""
        echo "To install missing dependencies:"
        if [[ " ${missing_deps[@]} " =~ " cargo-license " ]]; then
            echo "  cargo install cargo-license"
        fi
        echo ""
        exit 1
    fi
}

echo "Running Rust Service Test Suite"
echo "==============================="

# Check dependencies first
check_dependencies

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

#q start here

#the following code works for any rust project not just this
#specific project. It checks the values below to determine the 
#path of the configuration file to use in subsequent code
#do not hard code any variables. Write the code to derive them
#based on the comment.

# derive the base directory from the project root
BASE_DIRECTORY=$(cargo locate-project --workspace --message-format=plain | xargs dirname)

# config directory has the local config
CONFIG_DIRECTORY="$BASE_DIRECTORY/config"

#if [lib] exists in the project Cargo.toml set HAS_LIB = true
CARGO_TOML="$BASE_DIRECTORY/Cargo.toml"
HAS_LIB=$(grep -q "^\[lib\]" "$CARGO_TOML" && echo "true" || echo "false")

#if [bin] exists in the project Cargo.toml set HAS_BIN = true
HAS_BIN=$(grep -q "^\[\[bin\]\]" "$CARGO_TOML" && echo "true" || echo "false")

#If the Cargo file has neither a binary or an executable file in the config throw an error that
#tells the user the section of code they need to add to the Cargo file to indicate binary or lib.
if [[ "$HAS_BIN" == "false" && "$HAS_LIB" == "false" ]]; then
    echo "ERROR: Cargo.toml has neither [[bin]] nor [lib] section."
    echo "Add one of the following to your Cargo.toml:"
    echo "For binary: [[bin]]"
    echo "           name = \"your-app-name\""
    echo "           path = \"src/main.rs\""
    echo "For library: [lib]"
    echo "            name = \"your_lib_name\""
    echo "            path = \"src/lib.rs\""
    exit 1
fi

#set the project name to the name of the bin or lib in the Cargo.toml file
if [[ "$HAS_BIN" == "true" ]]; then
    PROJECT_TYPE="service"
    PROJECT_NAME=$(grep -A2 "^\[\[bin\]\]" "$CARGO_TOML" | grep "^name" | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/')
elif [[ "$HAS_LIB" == "true" ]]; then
    PROJECT_TYPE="lib"
    PROJECT_NAME=$(grep -A2 "^\[lib\]" "$CARGO_TOML" | grep "^name" | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/')
fi

#if bin or lib exists but the name or path value is not set print an error that
#tells the user the section of code they need to add to the Cargo file to indicate binary or lib.
if [[ -z "$PROJECT_NAME" ]]; then
    echo "ERROR: No name found in Cargo.toml for the configured section."
    if [[ "$HAS_BIN" == "true" ]]; then
        echo "Add name to your [[bin]] section:"
        echo "[[bin]]"
        echo "name = \"your-app-name\""
        echo "path = \"src/main.rs\""
    elif [[ "$HAS_LIB" == "true" ]]; then
        echo "Add name to your [lib] section:"
        echo "[lib]"
        echo "name = \"your_lib_name\""
        echo "path = \"src/lib.rs\""
    fi
    exit 1
fi

#If the Cargo file has both a binary and a library configured as the user which one they want to test
if [[ "$HAS_BIN" == "true" && "$HAS_LIB" == "true" ]]; then
    echo "Both binary and library found in Cargo.toml"
    echo "1) Test as service (binary)"
    echo "2) Test as library"
    read -p "Enter choice (1 or 2): " project_choice
    case $project_choice in
        1) PROJECT_TYPE="service" ;;
        2) PROJECT_TYPE="lib" ;;
        *) echo "Invalid choice. Defaulting to service."; PROJECT_TYPE="service" ;;
    esac
fi

#q stop here

#Set the config file name to service.toml for an exe or lib.toml for a library
CONFIG_FILE_NAME="${PROJECT_TYPE}.toml"

#the local config file is CONFIG_DIRECTORY/CONFIG_FILE_NAME
LOCAL_CONFIG_FILE="$CONFIG_DIRECTORY/$CONFIG_FILE_NAME"

#set the CONFIG_FILE value based on release or debug mode
#if BUILD_TYPE="release" the config file is INSTALL_DIRECTORY/PROJECT_NAME/CONFIG_FILE_NAME
#if BUILD_TYPE="debug" the config file is in INSTALL_DIRECTORY/PROJECT_NAME-debug/CONFIG_FILE_NAME
INSTALL_DIRECTORY=$(read_config_value "INSTALL_DIR" "$LOCAL_CONFIG_FILE")
if [[ "$BUILD_TYPE" == "release" ]]; then
    CONFIG_FILE="$INSTALL_DIRECTORY/$PROJECT_NAME/$CONFIG_FILE_NAME"
else
    CONFIG_FILE="$INSTALL_DIRECTORY/$PROJECT_NAME-debug/$CONFIG_FILE_NAME"
fi

#print a message explaing what the CONFIG_FILE file used for these tests is
echo "Using config file: $CONFIG_FILE"

#the function that finds the config file should work the same way
#call the function here and verify that it produces the same result as the 
#code above
FUNCTION_CONFIG_FILE=$(find_config_file "$PROJECT_NAME" "$BUILD_TYPE")
if [[ "$CONFIG_FILE" != "$FUNCTION_CONFIG_FILE" ]]; then
    echo "ERROR: Config file mismatch - expected: $CONFIG_FILE, found: $FUNCTION_CONFIG_FILE"
    exit 1
fi

exit 

# Read service name from config
SERVICE_NAME=$(read_config_value "SERVICE_NAME" "$CONFIG_FILE")

echo "Building $BUILD_TYPE binaries..."

echo "Formatting code..."
cargo fmt
cd ../rust-common-tests && cargo fmt && cd - > /dev/null

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
        # Determine test category
        if [[ "$TEST_FILE" == *"integration"* ]]; then
            run_test "$TEST_FILE" "local" "integration"
        elif [[ "$TEST_FILE" == *"security"* ]]; then
            run_test "$TEST_FILE" "local" "security"
        else
            run_test "$TEST_FILE" "local" "unit_tests"
        fi
    fi
done

# Run common tests and show individual results
echo ""
echo "Running common tests from rust-common-tests..."
cd ../rust-common-tests
run_test "integration" "common" "integration"
run_test "security_checks" "common" "security"
run_test "unit_tests" "common" "unit_tests"
cd - > /dev/null

echo ""
echo "Tests By Category:"
echo "=================="

# Calculate results for each test file (these run external tests, so don't count them as local)
for TEST_FILE in "${TEST_FILES[@]}"; do
    if [[ -n "$TEST_FILE" ]]; then
        TEST_OUTPUT=$(run_test "$TEST_FILE" 2>&1)
        TEST_PASSED=$(echo "$TEST_OUTPUT" | grep -o '[0-9]\+ passed' | head -1 | grep -o '[0-9]\+' || echo "0")
        TEST_FAILED=$(echo "$TEST_OUTPUT" | grep -o '[0-9]\+ failed' | head -1 | grep -o '[0-9]\+' || echo "0")
        
        # Only display result if there are actual tests (passed + failed > 0)
        TOTAL_TESTS=$((TEST_PASSED + TEST_FAILED))
        if [[ $TOTAL_TESTS -gt 0 ]]; then
            TEST_NAME=$(echo "${TEST_FILE}" | sed 's/_/ /g' | sed 's/\b\w/\U&/g')
            if [[ $TEST_FAILED -eq 0 ]]; then
                echo -e "✅ ${TEST_NAME}: ${GREEN}PASSED${NC} ($TEST_PASSED passed, $TEST_FAILED failed)"
            else
                echo -e "❌ ${TEST_NAME}: ${RED}FAILED${NC} ($TEST_PASSED passed, $TEST_FAILED failed)"
            fi
            
            # Add specific lines after Unit Tests
            if [[ "$TEST_FILE" == "unit_tests" ]]; then
                echo ""
                if [ $TOTAL_FAILED -eq 0 ]; then
                    echo -e "✅ All Tests: ${GREEN}PASSED${NC} ($TOTAL_PASSED passed, $TOTAL_FAILED failed)"
                else
                    echo -e "❌ All Tests: ${RED}FAILED${NC} ($TOTAL_PASSED passed, $TOTAL_FAILED failed)"
                fi
                echo ""
            fi
        fi
    fi
done

# Calculate rust-common-tests results (run only the separate test binaries, not lib)
COMMON_OUTPUT=$(cd ../rust-common-tests && cargo test --test integration --test security_checks --test unit_tests 2>&1)
COMMON_PASSED=$(echo "$COMMON_OUTPUT" | grep "test result:" | grep -o '[0-9]\+ passed' | awk '{sum += $1} END {print sum+0}')
COMMON_FAILED=$(echo "$COMMON_OUTPUT" | grep "test result:" | grep -o '[0-9]\+ failed' | awk '{sum += $1} END {print sum+0}')

# Count actual local tests (only the 2 real local tests)
LOCAL_PASSED=2  # test_service_binary_exists and test_time_action
LOCAL_FAILED=0
# Check if local tests failed by looking for specific test failures
for TEST_FILE in "${TEST_FILES[@]}"; do
    if [[ -n "$TEST_FILE" ]]; then
        TEST_OUTPUT=$(run_test "$TEST_FILE" 2>&1)
        # Check for actual local test failures (not external test failures)
        if echo "$TEST_OUTPUT" | grep -q "test_service_binary_exists.*FAILED"; then
            LOCAL_FAILED=$((LOCAL_FAILED + 1))
            LOCAL_PASSED=$((LOCAL_PASSED - 1))
        fi
        if echo "$TEST_OUTPUT" | grep -q "test_time_action.*FAILED"; then
            LOCAL_FAILED=$((LOCAL_FAILED + 1))
            LOCAL_PASSED=$((LOCAL_PASSED - 1))
        fi
    fi
done

echo "Tests by Local or Common:"
echo "========================="
echo ""

# Show common and local test summaries
if [[ $COMMON_FAILED -eq 0 ]] && [[ $COMMON_PASSED -gt 0 ]]; then
    echo -e "✅ Common Tests: ${GREEN}PASSED${NC} ($COMMON_PASSED passed, $COMMON_FAILED failed)"
elif [[ $COMMON_PASSED -eq 0 ]]; then
    echo -e "❌ Common Tests: ${RED}ALL COMMON TESTS FAILED${NC}"
else
    echo -e "❌ Common Tests: ${RED}FAILED${NC} ($COMMON_PASSED passed, $COMMON_FAILED failed)"
fi

if [[ $LOCAL_FAILED -eq 0 ]]; then
    echo -e "✅ Local Tests: ${GREEN}PASSED${NC} ($LOCAL_PASSED passed, $LOCAL_FAILED failed)"
else
    echo -e "❌ Local Tests: ${RED}FAILED${NC} ($LOCAL_PASSED passed, $LOCAL_FAILED failed)"
fi

echo ""

# Overall result
if [ $TOTAL_FAILED -eq 0 ]; then
    echo -e "✅ All Tests: ${GREEN}PASSED${NC} ($TOTAL_PASSED passed, $TOTAL_FAILED failed)"
    exit 0
else
    echo -e "❌ All Tests: ${RED}FAILED${NC} ($TOTAL_PASSED passed, $TOTAL_FAILED failed)"
    exit 1
fi
