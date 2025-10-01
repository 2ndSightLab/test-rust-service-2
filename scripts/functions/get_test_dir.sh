#!/bin/bash

get_test_dir() {
    local test_type="$1"
    
    case "$test_type" in
        "local")
            echo "$(get_project_dir)/tests"
            ;;
        "common")
            local common_path=$(get_cargo_config_value "dev-dependencies" "rust-common-tests")
            if [[ -z "$common_path" ]]; then
                echo "Error: rust-common-tests not found in [dev-dependencies]" >&2
                return 1
            fi
            echo "$common_path/tests"
            ;;
        *)
            echo "Error: test_type must be 'local' or 'common'" >&2
            return 1
            ;;
    esac
}

export -f get_test_dir
