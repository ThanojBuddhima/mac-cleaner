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
export SUDO_KEEPALIVE_PID="${SUDO_KEEPALIVE_PID:-}"

# Initialization
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

mac_cleaner_on_exit() {
    tput cnorm 2>/dev/null || true
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
        SUDO_KEEPALIVE_PID=""
    fi
    if [[ ${#MAC_CLEANER_TEMPS[@]} -gt 0 ]]; then
        rm -f "${MAC_CLEANER_TEMPS[@]}" 2>/dev/null || true
    fi
}

register_temp() {
    MAC_CLEANER_TEMPS+=("$1")
}

if [[ -z "${MAC_CLEANER_COMMON_LOADED:-}" ]]; then
    MAC_CLEANER_COMMON_LOADED=1
    MAC_CLEANER_TEMPS=()
    trap 'mac_cleaner_on_exit' EXIT
    trap 'mac_cleaner_on_exit; exit 130' INT TERM
fi

log() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

print_header() {
    local title="$1"
    local width=42
    local len=${#title}
    local padded_title=""

    echo -e "${CYAN}${BOLD}╭────────────────────────────────────────────╮${RESET}"
    if [[ $len -ge $width ]]; then
        padded_title="${title:0:width}"
    else
        local padding=$(( (width - len) / 2 ))
        padded_title=$(printf "%${padding}s%s%${padding}s" "" "$title" "")
        if [[ $(( (width - len) % 2 )) -ne 0 ]]; then
            padded_title="${padded_title} "
        fi
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

print_dry_run_banner() {
    if [[ ${IS_DRY_RUN:-0} -eq 1 ]]; then
        echo -e "${MAGENTA}${BOLD}DRY RUN — nothing will be deleted${RESET}"
        echo ""
    fi
}

pause() {
    echo ""
    echo -e -n "${CYAN}Press Enter to continue...${RESET}"
    read -r || exit 0
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
    if ! read -r response; then
        echo
        return 1
    fi
    
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
    # macOS uses Base-10 for storage sizes (1000 bytes = 1 KB)
    if [[ $bytes -ge 1000000000 ]]; then
        echo "$(awk -v b="$bytes" 'BEGIN {printf "%.2f GB", b/1000000000}')"
    elif [[ $bytes -ge 1000000 ]]; then
        echo "$(awk -v b="$bytes" 'BEGIN {printf "%.2f MB", b/1000000}')"
    elif [[ $bytes -ge 1000 ]]; then
        echo "$(awk -v b="$bytes" 'BEGIN {printf "%.2f KB", b/1000}')"
    else
        echo "${bytes} B"
    fi
}

require_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}This operation requires administrator privileges.${RESET}"
        if confirm "Request administrator permission?"; then
            if ! sudo -v; then
                print_error "Failed to obtain administrator privileges."
                return 1
            fi
            if [[ -z "${SUDO_KEEPALIVE_PID:-}" ]] || ! kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
                (while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) &
                SUDO_KEEPALIVE_PID=$!
                export SUDO_KEEPALIVE_PID
            fi
            return 0
        else
            print_error "Operation cancelled."
            return 1
        fi
    fi
    return 0
}

# Move a file to Trash without overwriting an existing trashed file.
move_to_trash() {
    local src="$1"
    if [[ ! -e "$src" && ! -L "$src" ]]; then
        return 1
    fi

    mkdir -p "$HOME/.Trash" || return 1

    local base dest i name ext
    base=$(basename "$src")
    dest="$HOME/.Trash/$base"

    if [[ -e "$dest" || -L "$dest" ]]; then
        i=2
        if [[ "$base" == *.* && "$base" != .* ]]; then
            name="${base%.*}"
            ext="${base##*.}"
            dest="$HOME/.Trash/${name} ${i}.${ext}"
            while [[ -e "$dest" || -L "$dest" ]]; do
                i=$((i + 1))
                dest="$HOME/.Trash/${name} ${i}.${ext}"
            done
        else
            dest="$HOME/.Trash/${base} ${i}"
            while [[ -e "$dest" || -L "$dest" ]]; do
                i=$((i + 1))
                dest="$HOME/.Trash/${base} ${i}"
            done
        fi
    fi

    mv "$src" "$dest"
}
