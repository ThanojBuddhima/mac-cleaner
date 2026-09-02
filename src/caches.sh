#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/scanner.sh"
source "$(dirname "${BASH_SOURCE[0]}")/cleanup.sh"

scan_user_caches() {
    local size1=$(get_directory_size "$HOME/Library/Caches")
    local size2=$(get_directory_size "$HOME/Library/Logs")
    echo $((size1 + size2))
}

clean_user_caches() {
    print_section "USER CACHE CLEANUP"
    
    local size=$(scan_user_caches)
    echo -e "Estimated size: ${BOLD}$(format_bytes $size)${RESET}\n"
    
    echo "This operation removes:"
    echo "  • ~/Library/Caches/*"
    echo "  • ~/Library/Logs/*"
    echo ""
    echo "Applications can recreate these files."
    echo ""
    
    if confirm "Continue?"; then
        delete_contents "$HOME/Library/Caches"
        delete_contents "$HOME/Library/Logs"
        print_success "User caches cleaned."
    else
        echo "Cancelled."
    fi
}

scan_system_caches() {
    local size1=$(get_directory_size "/Library/Caches")
    local size2=$(get_directory_size "/Library/Logs")
    echo $((size1 + size2))
}

clean_system_caches() {
    print_section "SYSTEM CACHE CLEANUP"
    
    local size=$(scan_system_caches)
    echo -e "Estimated size: ${BOLD}$(format_bytes $size)${RESET}\n"
    
    echo "This operation removes:"
    echo "  • /Library/Caches/*"
    echo "  • /Library/Logs/*"
    echo ""
    echo "Applications can recreate these files."
    echo ""
    
    require_sudo || return
    
    if confirm "Continue?"; then
        if [[ $IS_DRY_RUN -eq 1 ]]; then
            echo -e "${MAGENTA}DRY RUN: Would delete contents of /Library/Caches and /Library/Logs as root${RESET}"
        else
            sudo find /Library/Caches -mindepth 1 -delete 2>/dev/null
            sudo find /Library/Logs -mindepth 1 -delete 2>/dev/null
            print_success "System caches cleaned."
        fi
    else
        echo "Cancelled."
    fi
}
