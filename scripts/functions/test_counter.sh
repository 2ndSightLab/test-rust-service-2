#!/bin/bash

# Global test counters
LOCAL_PASSED=0
LOCAL_FAILED=0
COMMON_PASSED=0
COMMON_FAILED=0
TOTAL_PASSED=0
TOTAL_FAILED=0
INTEGRATION_TESTS=0
SECURITY_TESTS=0
UNIT_TESTS=0
TOTAL_TESTS=0

# Function to count and categorize test results
# Usage: count_test_result <test_output> <is_local> <test_category>
# is_local: "local" or "common"
# test_category: "integration", "security", "unit"
count_test_result() {
    local test_output="$1"
    local is_local="$2"
    local test_category="$3"
    
    local passed=$(echo "$test_output" | grep "test result:" | grep -o '[0-9]\+ passed' | grep -o '[0-9]\+' || echo "0")
    local failed=$(echo "$test_output" | grep "test result:" | grep -o '[0-9]\+ failed' | grep -o '[0-9]\+' || echo "0")
    
    # Update appropriate counters
    if [[ "$is_local" == "local" ]]; then
        LOCAL_PASSED=$((LOCAL_PASSED + passed))
        LOCAL_FAILED=$((LOCAL_FAILED + failed))
    else
        COMMON_PASSED=$((COMMON_PASSED + passed))
        COMMON_FAILED=$((COMMON_FAILED + failed))
    fi
    
    # Update category counters
    case "$test_category" in
        "integration")
            INTEGRATION_TESTS=$((INTEGRATION_TESTS + passed + failed))
            ;;
        "security")
            SECURITY_TESTS=$((SECURITY_TESTS + passed + failed))
            ;;
        "unit")
            UNIT_TESTS=$((UNIT_TESTS + passed + failed))
            ;;
    esac
    
    # Update totals
    TOTAL_TESTS=$((TOTAL_TESTS + passed + failed))
    TOTAL_PASSED=$((TOTAL_PASSED + passed))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
}
