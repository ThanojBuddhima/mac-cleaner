#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/scanner.sh"
source "$(dirname "${BASH_SOURCE[0]}")/cleanup.sh"

scan_backups() {
    # On newer macOS, backups are in ~/Library/Application Support/MobileSync/Backup
    local backup_dir="$HOME/Library/Application Support/MobileSync/Backup"
    get_directory_size "$backup_dir"
}

clean_backups() {
    print_section "IOS BACKUPS CLEANUP"
    
    local backup_dir="$HOME/Library/Application Support/MobileSync/Backup"
    local size=$(scan_backups)
    
    if [[ "$size" -eq 0 ]]; then
        echo "No iOS/iPadOS backups found."
        return
    fi
    
    echo -e "Estimated size: ${BOLD}$(format_bytes $size)${RESET}\n"
    
    echo "This operation removes:"
    echo "  • All backups in $backup_dir"
    echo ""
    echo -e "${YELLOW}Warning: This deletes local iPhone/iPad backups.${RESET}"
    echo ""
    
    if confirm "Continue?"; then
        delete_contents "$backup_dir"
        print_success "Backups cleaned."
    else
        echo "Cancelled."
    fi
}
