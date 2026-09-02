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
    
    # Delete with a progress bar
    local total_files=$(find "$target" 2>/dev/null | wc -l | awk '{print $1}')
    
    if [[ -z "$total_files" || "$total_files" -eq 0 ]]; then
        # fallback to rm -rf if find fails for some reason
        rm -rf "$target"
        log "Deleted: $target"
        return 0
    fi

    # Suppress cursor and show progress
    tput civis
    find "$target" -delete -print 2>/dev/null | awk -v total="$total_files" '
    {
        count++
        if (count % 50 == 0 || count == total) {
            percent = int((count / total) * 100)
            printf "\r\033[0;36m[%-50s] %d%%\033[0m", substr("==================================================", 1, int(percent / 2)), percent > "/dev/stderr"
        }
    }
    END {
        printf "\n" > "/dev/stderr"
    }
    '
    tput cnorm
    
    # Just in case the directory itself couldn't be deleted by find -delete due to permissions
    if [[ -e "$target" ]]; then
        rm -rf "$target" 2>/dev/null
    fi
    
    log "Deleted: $target"
    return 0
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
    
    # Delete contents but keep the directory, with a progress bar
    local total_files=$(find "$target" -mindepth 1 2>/dev/null | wc -l | awk '{print $1}')
    
    if [[ -z "$total_files" || "$total_files" -eq 0 ]]; then
        log "Cleared contents of: $target (already empty)"
        return 0
    fi

    # Suppress cursor and show progress
    tput civis
    find "$target" -mindepth 1 -delete -print 2>/dev/null | awk -v total="$total_files" '
    {
        count++
        if (count % 50 == 0 || count == total) {
            percent = int((count / total) * 100)
            printf "\r\033[0;36m[%-50s] %d%%\033[0m", substr("==================================================", 1, int(percent / 2)), percent > "/dev/stderr"
        }
    }
    END {
        printf "\n" > "/dev/stderr"
    }
    '
    tput cnorm
    
    log "Cleared contents of: $target"
    return 0
}
