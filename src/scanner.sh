#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

get_directory_size() {
    local target="$1"
    if [[ ! -e "$target" ]]; then
        echo 0
        return
    fi
    
    # Use du to get size in bytes
    local size
    size=$(du -s "$target" 2>/dev/null | awk '{print $1 * 512}')
    if [[ -z "$size" ]]; then
        echo 0
    else
        echo "$size"
    fi
}

get_system_data_size() {
    # This is a highly simplified estimation of macOS System Data
    # Actual System Data is calculated by tmutil and diskutil
    
    local total_disk
    local used_disk
    
    total_disk=$(df -k / | tail -1 | awk '{print $2 * 1024}')
    used_disk=$(df -k / | tail -1 | awk '{print $3 * 1024}')
    
    echo "$used_disk"
}
