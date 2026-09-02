#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/scanner.sh"

scan_docker() {
    if ! command -v docker &> /dev/null; then
        echo 0
        return
    fi
    # Getting size of docker is complex without docker system df
    # We can try to parse docker system df
    local size_str
    size_str=$(docker system df --format "{{.Size}}" 2>/dev/null | awk '{
        if ($0 ~ /GB/) { sum += $1 * 1073741824 }
        else if ($0 ~ /MB/) { sum += $1 * 1048576 }
        else if ($0 ~ /KB/) { sum += $1 * 1024 }
        else if ($0 ~ /B/) { sum += $1 }
    } END { printf "%.0f\n", sum }')
    
    if [[ -z "$size_str" ]]; then
        echo 0
    else
        echo "$size_str"
    fi
}

clean_docker() {
    print_section "DOCKER CLEANUP"
    
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed."
        return
    fi
    
    if ! docker info &> /dev/null; then
        echo "Docker daemon is not running."
        return
    fi
    
    local size=$(scan_docker)
    echo -e "Estimated total Docker size: ${BOLD}$(format_bytes $size)${RESET}\n"
    
    echo "This operation runs 'docker system prune'."
    echo "It removes all stopped containers, all networks not used by at least one container, all dangling images, and all dangling build cache."
    echo ""
    
    if confirm "Continue?"; then
        if [[ $IS_DRY_RUN -eq 1 ]]; then
            echo -e "${MAGENTA}DRY RUN: Would run 'docker system prune -f'${RESET}"
        else
            docker system prune -f
            print_success "Docker cleaned."
        fi
    else
        echo "Cancelled."
    fi
}
