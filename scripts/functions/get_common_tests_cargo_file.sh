#!/bin/bash

get_common_tests_cargo_file() {
    local common_tests_path=$(get_cargo_config_value "[dev-dependencies]" "rust-common-tests")
    
    if [[ -z "$common_tests_path" ]]; then
        echo "Error: rust-common-tests not found in [dev-dependencies]" >&2
        return 1
    fi
    
    # Parse path from git URL or local path
    if [[ "$common_tests_path" =~ path[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
        local path="${BASH_REMATCH[1]}"
        echo "$path/Cargo.toml"
    else
        echo "Error: Could not parse path from rust-common-tests dependency" >&2
        return 1
    fi
}
