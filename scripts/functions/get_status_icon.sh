#!/bin/bash

get_status_icon() {
    local status="$1"
    
    case "$status" in
        "passed")
            echo "✅"
            ;;
        "failed")
            echo "❌"
            ;;
        "warn")
            echo "⚠️"
            ;;
        *)
            echo "❓"
            ;;
    esac
}

export -f get_status_icon
