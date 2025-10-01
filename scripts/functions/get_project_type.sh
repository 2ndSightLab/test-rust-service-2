#!/bin/bash

# Function to get project type from Cargo.toml
get_project_type() {
    # Get project root directory using cargo
    local PROJECT_DIR=$(cargo locate-project --workspace --message-format=plain | xargs dirname)
    local CARGO_TOML="$PROJECT_DIR/Cargo.toml"
    
    # Check project type
    local HAS_BIN=$(grep -q "^\[\[bin\]\]" "$CARGO_TOML" && echo "true" || echo "false")
    local HAS_LIB=$(grep -q "^\[lib\]" "$CARGO_TOML" && echo "true" || echo "false")
    
    # Error if neither bin nor lib exists
    if [[ "$HAS_BIN" == "false" && "$HAS_LIB" == "false" ]]; then
        echo "ERROR: Cargo.toml has neither [[bin]] nor [lib] section." >&2
        echo "Add one of the following to your Cargo.toml:" >&2
        echo "For binary: [[bin]]" >&2
        echo "           name = \"your-app-name\"" >&2
        echo "           path = \"src/main.rs\"" >&2
        echo "For library: [lib]" >&2
        echo "            name = \"your_lib_name\"" >&2
        echo "            path = \"src/lib.rs\"" >&2
        return 1
    fi
    
    # Return project type
    if [[ "$HAS_BIN" == "true" ]]; then
        echo "service"
    elif [[ "$HAS_LIB" == "true" ]]; then
        echo "lib"
    fi
}

# Export function for use in other scripts
export -f get_project_type
