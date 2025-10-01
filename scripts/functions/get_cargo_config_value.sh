#!/bin/bash

get_cargo_config_value() {
    local SECTION="$1"
    local KEY="$2"

    local PROJECT_DIR=$(get_project_dir)
    
    cd "$PROJECT_DIR" || return 1
    
    case "$SECTION" in
        "dev-dependencies")
            cargo metadata --format-version 1 --no-deps | jq -r ".packages[0].dependencies[] | select(.name == \"${KEY}\" and .kind == \"dev\") | .path // .source // empty"
            ;;
        *)
            local path=".packages[0]"
            [[ "$SECTION" != "package" ]] && path="${path}.${SECTION}"
            cargo metadata --format-version 1 --no-deps | jq -r "${path}.${KEY} // empty"
            ;;
    esac
}
