#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

get_directory_size() {
    local target="$1"
    if [[ ! -e "$target" ]]; then
        echo 0
        return
    fi

    # du -sk is 1024-byte blocks regardless of BLOCKSIZE / GNU vs BSD du
    local size
    size=$(du -sk "$target" 2>/dev/null | awk '{printf "%.0f\n", $1 * 1024}')
    if [[ -z "$size" ]]; then
        echo 0
    else
        echo "$size"
    fi
}

get_system_data_size() {
    local used_disk
    used_disk=$(df -k / | tail -1 | awk '{printf "%.0f\n", $3 * 1024}')
    echo "$used_disk"
}

load_disk_info() {
    MC_DISK_TOTAL=0
    MC_DISK_FREE=0
    MC_DISK_USED=0

    local disk_info=""
    # Only call Swift if developer tools are already installed — otherwise macOS
    # may hang on the Command Line Tools dialog.
    if xcode-select -p >/dev/null 2>&1 && [[ -x /usr/bin/swift ]]; then
        disk_info=$(/usr/bin/swift -e 'import Foundation; let v = try! URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]); print("\(v.volumeTotalCapacity!) \(v.volumeAvailableCapacityForImportantUsage!)")' 2>/dev/null)
    fi

    if [[ -n "$disk_info" ]]; then
        MC_DISK_TOTAL=$(echo "$disk_info" | awk '{printf "%.0f\n", $1}')
        MC_DISK_FREE=$(echo "$disk_info" | awk '{printf "%.0f\n", $2}')
        MC_DISK_USED=$((MC_DISK_TOTAL - MC_DISK_FREE))
    else
        MC_DISK_TOTAL=$(df -k / | tail -1 | awk '{printf "%.0f\n", $2 * 1024}')
        MC_DISK_USED=$(df -k / | tail -1 | awk '{printf "%.0f\n", $3 * 1024}')
        MC_DISK_FREE=$(df -k / | tail -1 | awk '{printf "%.0f\n", $4 * 1024}')
    fi
}
