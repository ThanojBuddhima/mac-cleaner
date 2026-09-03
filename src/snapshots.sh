#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

scan_snapshots() {
    # tmutil listlocalsnapshots / gives something like:
    # Snapshots for volume group containing disk /:
    # com.apple.TimeMachine.2023-10-24-123456.local
    local count
    count=$(tmutil listlocalsnapshots / 2>/dev/null | grep "com.apple.TimeMachine" | wc -l | tr -d ' ')
    count="${count:-0}"
    
    # We can't easily get the size of snapshots without root, 
    # and even then it's complex because APFS shares space.
    # We will just return the count.
    echo "$count"
}

manage_snapshots() {
    print_section "TIME MACHINE SNAPSHOTS"
    
    echo "Local snapshots:"
    tmutil listlocalsnapshots / | grep "com.apple.TimeMachine" | sed 's/^/  /'
    
    local count=$(scan_snapshots)
    if [[ "$count" -eq 0 ]]; then
        echo -e "\nNo local snapshots found."
        return
    fi
    
    echo -e "\nmacOS controls when snapshots are actually reclaimable."
    echo "Options:"
    echo "  1. Ask macOS to reclaim up to 10 GB"
    echo "  2. Ask macOS to reclaim up to 25 GB"
    echo "  3. Ask macOS to reclaim up to 50 GB"
    echo "  0. Back"
    echo ""
    echo -e -n "${CYAN}Select an option:${RESET} "
    read -r opt || return
    
    local target_bytes=0
    case "$opt" in
        1) target_bytes=10737418240 ;;
        2) target_bytes=26843545600 ;;
        3) target_bytes=53687091200 ;;
        0) return ;;
        *) echo "Invalid option." ; return ;;
    esac
    
    require_sudo || return
    
    if [[ $IS_DRY_RUN -eq 1 ]]; then
        echo -e "${MAGENTA}DRY RUN: Would run 'tmutil thinlocalsnapshots / $target_bytes 4'${RESET}"
    else
        echo "Thinning snapshots (this may take a while)..."
        if sudo tmutil thinlocalsnapshots / "$target_bytes" 4; then
            print_success "Snapshot thinning complete."
        else
            print_error "Snapshot thinning failed."
        fi
    fi
}
