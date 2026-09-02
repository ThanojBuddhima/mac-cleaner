#!/usr/bin/env bash

# Text colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export BOLD='\033[1m'
export RESET='\033[0m'

export LOG_FILE="$HOME/Library/Logs/mac-cleaner.log"

# Initialization
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

log() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

print_header() {
    echo -e "${CYAN}${BOLD}╭────────────────────────────────────────────╮${RESET}"
    local padding=$(( (42 - ${#1}) / 2 ))
    local padded_title=$(printf "%${padding}s%s%${padding}s" "" "$1" "")
    # Adjust if odd length
    if [[ $(( (42 - ${#1}) % 2 )) -ne 0 ]]; then
        padded_title="${padded_title} "
    fi
    echo -e "${CYAN}${BOLD}│${RESET}${BOLD} $padded_title ${RESET}${CYAN}${BOLD}│${RESET}"
    echo -e "${CYAN}${BOLD}╰────────────────────────────────────────────╯${RESET}"
    echo ""
}

print_section() {
    echo -e "${BOLD}$1${RESET}"
    echo -e "${CYAN}────────────────────────────────────────────${RESET}"
}

print_error() {
    echo -e "${RED}Error: $1${RESET}"
    log "ERROR: $1"
}

print_success() {
    echo -e "${GREEN}$1${RESET}"
    log "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${RESET}"
    log "WARNING: $1"
}

confirm() {
    local prompt="$1"
    local default="${2:-N}" # default N
    
    if [[ "$default" == "Y" || "$default" == "y" ]]; then
        prompt="$prompt [Y/n]"
    else
        prompt="$prompt [y/N]"
    fi
    
    echo -e -n "${YELLOW}${prompt}: ${RESET}"
    read -r response
    
    if [[ -z "$response" ]]; then
        response="$default"
    fi
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

format_bytes() {
    local bytes=$1
    if [[ -z "$bytes" || ! "$bytes" =~ ^[0-9]+$ || "$bytes" -eq 0 ]]; then
        echo "0 B"
        return
    fi
    if [[ $bytes -ge 1073741824 ]]; then
        echo "$(awk -v b="$bytes" 'BEGIN {printf "%.2f GB", b/1073741824}')"
    elif [[ $bytes -ge 1048576 ]]; then
        echo "$(awk -v b="$bytes" 'BEGIN {printf "%.2f MB", b/1048576}')"
    elif [[ $bytes -ge 1024 ]]; then
        echo "$(awk -v b="$bytes" 'BEGIN {printf "%.2f KB", b/1024}')"
    else
        echo "${bytes} B"
    fi
}

require_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}This operation requires administrator privileges.${RESET}"
        if confirm "Request administrator permission?"; then
            sudo -v
            if [[ $? -ne 0 ]]; then
                print_error "Failed to obtain administrator privileges."
                return 1
            fi
            # Keep alive
            (while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) &
            return 0
        else
            print_error "Operation cancelled."
            return 1
        fi
    fi
    return 0
}
