#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

export IS_DRY_RUN="${IS_DRY_RUN:-0}"

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
    
    local total_files
    total_files=$(find "$target" 2>/dev/null | wc -l | awk '{print $1}')
    if [[ -z "$total_files" ]]; then
        total_files=0
    fi

    tput civis 2>/dev/null || true
    find "$target" -delete -print 2>/dev/null | awk -v total="$total_files" '
    {
        count++
        if (total > 0 && (count % 50 == 0 || count == total)) {
            percent = int((count / total) * 100)
            printf "\r\033[0;36m[%-50s] %d%%\033[0m", substr("==================================================", 1, int(percent / 2)), percent > "/dev/stderr"
        }
    }
    END {
        printf "\n" > "/dev/stderr"
    }
    '
    tput cnorm 2>/dev/null || true
    
    if [[ -e "$target" || -L "$target" ]]; then
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
    if [[ "$target" == "/" || "$target" == "/System" || "$target" == "/Library" || "$target" == "$HOME" ]]; then
        print_error "Cowardly refusing to delete contents of protected system path: $target"
        return 1
    fi
    
    if [[ $IS_DRY_RUN -eq 1 ]]; then
        echo -e "${MAGENTA}DRY RUN: Would delete contents of ${target}${RESET}"
        return 0
    fi
    
    local total_files
    total_files=$(find "$target" -mindepth 1 2>/dev/null | wc -l | awk '{print $1}')
    if [[ -z "$total_files" ]]; then
        total_files=0
    fi

    tput civis 2>/dev/null || true
    find "$target" -mindepth 1 -delete -print 2>/dev/null | awk -v total="$total_files" '
    {
        count++
        if (total > 0 && (count % 50 == 0 || count == total)) {
            percent = int((count / total) * 100)
            printf "\r\033[0;36m[%-50s] %d%%\033[0m", substr("==================================================", 1, int(percent / 2)), percent > "/dev/stderr"
        }
    }
    END {
        printf "\n" > "/dev/stderr"
    }
    '
    tput cnorm 2>/dev/null || true
    
    log "Cleared contents of: $target"
    return 0
}
