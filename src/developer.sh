#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/scanner.sh"
source "$(dirname "${BASH_SOURCE[0]}")/cleanup.sh"

# Main-menu Xcode option only reports/cleans DerivedData.
# Archives and DeviceSupport are handled in the Developer wizard.
scan_xcode() {
    get_directory_size "$HOME/Library/Developer/Xcode/DerivedData"
}

clean_xcode() {
    print_section "XCODE DERIVEDDATA CLEANUP"
    
    local size=$(scan_xcode)
    echo -e "Estimated size: ${BOLD}$(format_bytes "$size")${RESET}\n"
    
    echo "This operation removes:"
    echo "  • DerivedData (rebuilt on next compilation)"
    echo ""
    echo "Archives, DeviceSupport, and Simulator caches are not touched."
    echo "Use More options → Developer Cleanup Wizard for those."
    echo ""
    
    if confirm "Continue?"; then
        delete_contents "$HOME/Library/Developer/Xcode/DerivedData"
        print_success "Xcode DerivedData cleaned."
    else
        echo "Cancelled."
    fi
}
