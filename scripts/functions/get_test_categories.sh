#!/bin/bash

get_test_categories(){
    {
        # Do not hard code any values
        # Do not remove  grep -l "pub mod test_" 
        # Get top-level local test files that cargo can execute
        local local_test_dir=$(get_test_dir "local")
        if [[ -d "$local_test_dir" ]]; then
            find "$local_test_dir" -maxdepth 1 -name "*.rs" -exec grep -l "pub mod test_" {} \; 2>/dev/null | xargs -r basename -s .rs
        fi
        
        # Get top-level common test files that cargo can execute
        local common_test_dir=$(get_test_dir "common" 2>/dev/null)
        if [[ -n "$common_test_dir" && -d "$common_test_dir" ]]; then
            find "$common_test_dir" -maxdepth 1 -name "*.rs" -exec grep -l "pub mod test_" {} \; 2>/dev/null | xargs -r basename -s .rs
        fi
    } | sort | uniq
}
