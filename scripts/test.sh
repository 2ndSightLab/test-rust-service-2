#!/bin/bash

# Initialize test counters
TOTAL_TESTS=0
TOTAL_ERRORS=0
TOTAL_PASSED=0
TOTAL_FAILED=0

TOTAL_COMMON=0
TOTAL_LOCAL=0

TOTAL_INTEGRATION=0
TOTAL_SECURITY=0
TOTAL_UNIT=0

# Source all functions
SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"
for func in "$SCRIPTS_DIR/functions"/*.sh; do source "$func"; done

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

SCRIPT_DIR=$(get_script_directory)
if [ $choice -eq 1 ]; then
    "$SCRIPT_DIR/build.sh" --debug
    "$SCRIPT_DIR/install.sh" --debug
else
    "$SCRIPT_DIR/build.sh" --release
    "$SCRIPT_DIR/install.sh" --release
fi

for category_name in $(get_test_categories); do

    if [[ "$category_name" == *"common"* ]]; then test_type="common"; else test_type="local"; fi

    echo "================================"
    echo "Category_name: $category_name"
    echo "Test type: $test_type"
    echo "================================"


    CATEGORY_TESTS=$(cargo test --test "$category_name" -- --list 2>/dev/null | grep ": test$" | sed 's/: test$//'| grep -v "run_all_common")
    
    for TEST_NAME in $CATEGORY_TESTS; do
        echo "$TEST_NAME"
        if [[ "$TEST_NAME" == *"::common::"* ]]; then
            TOTAL_COMMON=$((TOTAL_COMMON + 1))
        else
            TOTAL_LOCAL=$((TOTAL_LOCAL + 1))
        fi
        cargo test --test "$category_name" "$TEST_NAME"
        exit_code=$?
          
        # Track test results based on return codes:
        # 0 = passed
        # 101 = failed (test failure)
        # other = error (compilation/runtime error)
        # cargo counts panics in code being tested as failures
	if [ $exit_code -eq 0 ]; then
            TOTAL_PASSED=$((TOTAL_PASSED + 1))
        elif [ $exit_code -eq 101 ]; then
            TOTAL_FAILED=$((TOTAL_FAILED + 1))
        else
            TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
        fi

        if [[ "$category_name" == security_checks* ]]; then
          TOTAL_SECURITY=$((TOTAL_SECURITY + 1))
        elif [[ "$category_name" == integration* ]]; then
          TOTAL_INTEGRATION=$((TOTAL_INTEGRATION + 1))
        elif [[ "$category_name" == uni* ]]; then
          TOTAL_UNIT=$((TOTAL_UNIT + 1))
        else
          TOTAL_OTHER=$((TOTAL_OTHER + 1))
        fi

        TOTAL_TESTS=$((TOTAL_TESTS + 1))

        echo "================================"
        
    done

    echo 
    echo "Done testing: $category_name"
    echo

done

echo "================================"
echo "Test Summary:"
echo "Total Tests: $TOTAL_TESTS"
echo
echo "Total Common: $TOTAL_COMMON"
echo "Total Local: $TOTAL_LOCAL"
echo
echo "Total Integration: $TOTAL_INTEGRATION"
echo "Total Security: $TOTAL_SECURITY"
echo "Total Unit Tests: $TOTAL_UNIT"
echo "Total Other: $TOTAL_OTHER"
echo
echo "Passed: $TOTAL_PASSED"
echo "Failed: $TOTAL_FAILED"
echo "Errors: $TOTAL_ERRORS"
echo "================================"
