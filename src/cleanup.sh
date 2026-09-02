#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

export IS_DRY_RUN=0

set_dry_run() {
    export IS_DRY_RUN=1
}

delete_path() {
    local target="$1"
    
    if [[ ! -e "$target" && ! -L "$target" ]]; then
        return 0
    fi
    
    # Safety checks
    if [[ "$target" == "/" || "$target" == "/System" || "$target" == "/Library" || "$target" == "/private/var" || "$target" == "$HOME" || "$target" == "$HOME/Library" ]]; then
        print_error "Cowardly refusing to delete protected system path: $target"
        return 1
    fi
    
    if [[ $IS_DRY_RUN -eq 1 ]]; then
        echo -e "${MAGENTA}DRY RUN: Would delete ${target}${RESET}"
        return 0
    fi
    
    # Move to trash if possible, otherwise rm
    # Actually for CLI cleaner, rm is usually fine for caches, but let's just rm -rf
    rm -rf "$target"
    if [[ $? -eq 0 ]]; then
        log "Deleted: $target"
        return 0
    else
        log "Failed to delete: $target"
        return 1
    fi
}

delete_contents() {
    local target="$1"
    
    if [[ ! -d "$target" ]]; then
        return 0
    fi
    
    # Safety checks
    if [[ "$target" == "/" || "$target" == "/System" || "$target" == "$HOME" ]]; then
        print_error "Cowardly refusing to delete contents of protected system path: $target"
        return 1
    fi
    
    if [[ $IS_DRY_RUN -eq 1 ]]; then
        echo -e "${MAGENTA}DRY RUN: Would delete contents of ${target}${RESET}"
        return 0
    fi
    
    # Delete contents but keep the directory
    find "$target" -mindepth 1 -delete 2>/dev/null
    if [[ $? -eq 0 ]]; then
        log "Cleared contents of: $target"
        return 0
    else
        log "Errors while clearing contents of: $target (Some files might be in use)"
        return 0 # We consider partial success OK for caches
    fi
}
