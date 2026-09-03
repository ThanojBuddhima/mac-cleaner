#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/scanner.sh"

parse_docker_bytes() {
    awk '{
        gsub(/\(.*/, "")
        gsub(/[[:space:]]/, "")
        if ($0 ~ /GB/) { sum += $0 * 1073741824 }
        else if ($0 ~ /MB/) { sum += $0 * 1048576 }
        else if ($0 ~ /KB/) { sum += $0 * 1024 }
        else if ($0 ~ /B/) { sum += $0 }
    } END { printf "%.0f\n", sum }'
}

scan_docker() {
    if ! command -v docker &> /dev/null; then
        echo 0
        return
    fi

    # Reclaimable space only — matches what `docker system prune` can free
    local size_str
    size_str=$(docker system df --format '{{.Reclaimable}}' 2>/dev/null | parse_docker_bytes)

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
    echo -e "Estimated reclaimable size: ${BOLD}$(format_bytes "$size")${RESET}\n"
    
    echo "This operation runs 'docker system prune'."
    echo "It removes stopped containers, unused networks, dangling images, and dangling build cache."
    echo "It does not remove unused volumes or non-dangling images."
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
