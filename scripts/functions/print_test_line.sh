#!/bin/bash

print_test_line() {
    local PASSED_COUNT="$1"
    local FAILED_COUNT="$2"
    local ERROR_COUNT="$3"
    local LINE_TEXT="$4"
    
    if [[ $FAILED_COUNT -eq 0 && $ERROR_COUNT -eq 0 ]]; then
        STATUS="passed"
    else
        STATUS="failed"
    fi
    
    echo -e "$(get_status_icon $STATUS) $LINE_TEXT: $(print_test_status_value $STATUS) ($PASSED_COUNT passed, $FAILED_COUNT failed, $ERROR_COUNT errors)"
}

export -f print_test_line
