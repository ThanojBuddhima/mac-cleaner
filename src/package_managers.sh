#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/scanner.sh"

scan_homebrew() {
    if ! command -v brew &> /dev/null; then
        echo 0
        return
    fi
    # Getting size of brew cache
    local cache_dir
    cache_dir=$(brew --cache 2>/dev/null)
    if [[ -n "$cache_dir" ]]; then
        get_directory_size "$cache_dir"
    else
        echo 0
    fi
}

clean_homebrew() {
    print_section "HOMEBREW CLEANUP"
    
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed."
        return
    fi
    
    local size=$(scan_homebrew)
    echo -e "Estimated size: ${BOLD}$(format_bytes $size)${RESET}\n"
    
    echo "This operation runs 'brew cleanup'."
    echo "It removes old versions of installed formulae and clears old downloads."
    echo ""
    
    if confirm "Continue?"; then
        if [[ $IS_DRY_RUN -eq 1 ]]; then
            echo -e "${MAGENTA}DRY RUN: Would run 'brew cleanup'${RESET}"
            brew cleanup --dry-run
        else
            brew cleanup
            print_success "Homebrew cache cleaned."
        fi
    else
        echo "Cancelled."
    fi
}

scan_npm() {
    if ! command -v npm &> /dev/null; then
        echo 0
        return
    fi
    local cache_dir
    cache_dir=$(npm config get cache 2>/dev/null)
    if [[ -n "$cache_dir" ]]; then
        get_directory_size "$cache_dir"
    else
        echo 0
    fi
}

clean_npm() {
    print_section "NPM CACHE CLEANUP"
    
    if ! command -v npm &> /dev/null; then
        echo "npm is not installed."
        return
    fi
    
    local size=$(scan_npm)
    echo -e "Estimated size: ${BOLD}$(format_bytes $size)${RESET}\n"
    
    echo "This operation runs 'npm cache clean --force' and clears npx cache and logs."
    echo ""
    
    if confirm "Continue?"; then
        local cache_dir
        cache_dir=$(npm config get cache 2>/dev/null)
        if [[ $IS_DRY_RUN -eq 1 ]]; then
            echo -e "${MAGENTA}DRY RUN: Would run 'npm cache clean --force'${RESET}"
            if [[ -n "$cache_dir" ]]; then
                echo -e "${MAGENTA}DRY RUN: Would delete '$cache_dir/_npx'${RESET}"
                echo -e "${MAGENTA}DRY RUN: Would delete '$cache_dir/_logs'${RESET}"
                echo -e "${MAGENTA}DRY RUN: Would delete '$cache_dir/_libvips'${RESET}"
                echo -e "${MAGENTA}DRY RUN: Would delete '$cache_dir/_prebuilds'${RESET}"
            fi
        else
            npm cache clean --force
            if [[ -n "$cache_dir" ]]; then
                rm -rf "$cache_dir/_npx" "$cache_dir/_logs" "$cache_dir/_libvips" "$cache_dir/_prebuilds" 2>/dev/null
            fi
            print_success "npm cache cleaned."
        fi
    else
        echo "Cancelled."
    fi
}
