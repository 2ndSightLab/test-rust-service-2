#!/bin/bash

print_test_status_value() {
    local status="$1"
    local RED='\033[1;91m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'
    
    case "$status" in
        "passed")
            echo -e "${GREEN}PASSED${NC}"
            ;;
        "failed")
            echo -e "${RED}FAILED${NC}"
            ;;
        *)
            echo "$status"
            ;;
    esac
}

export -f print_test_status_value
