#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/scanner.sh"
source "$(dirname "${BASH_SOURCE[0]}")/cleanup.sh"

scan_xcode() {
    local size1=$(get_directory_size "$HOME/Library/Developer/Xcode/DerivedData")
    local size2=$(get_directory_size "$HOME/Library/Developer/Xcode/Archives")
    local size3=$(get_directory_size "$HOME/Library/Developer/Xcode/iOS DeviceSupport")
    local size4=$(get_directory_size "$HOME/Library/Developer/CoreSimulator/Caches")
    
    echo $((size1 + size2 + size3 + size4))
}

clean_xcode() {
    print_section "XCODE CLEANUP"
    
    local size=$(scan_xcode)
    echo -e "Estimated size: ${BOLD}$(format_bytes $size)${RESET}\n"
    
    echo "This operation removes:"
    echo "  • DerivedData (rebuilt on next compilation)"
    echo "  • Archives (built apps, ensure you have exported them if needed)"
    echo "  • iOS DeviceSupport (symbols from connected devices)"
    echo "  • CoreSimulator Caches"
    echo ""
    
    if confirm "Continue?"; then
        delete_contents "$HOME/Library/Developer/Xcode/DerivedData"
        delete_contents "$HOME/Library/Developer/Xcode/Archives"
        delete_contents "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
        delete_contents "$HOME/Library/Developer/CoreSimulator/Caches"
        print_success "Xcode data cleaned."
    else
        echo "Cancelled."
    fi
}
