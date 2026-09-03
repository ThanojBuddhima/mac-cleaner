#!/usr/bin/env bash

# Advanced / More options

scan_trash() {
    local trash_size=0
    if [ -d "$HOME/.Trash" ]; then
        trash_size=$(du -sk "$HOME/.Trash" 2>/dev/null | awk '{printf "%.0f\n", $1 * 1024}')
    fi
    echo "${trash_size:-0}"
}

clean_trash() {
    print_section "EMPTY TRASH"

    local size
    size=$(scan_trash)
    echo -e "Estimated size: ${BOLD}$(format_bytes "$size")${RESET}\n"

    if [[ "$size" -eq 0 ]]; then
        echo "Trash is already empty."
        return
    fi

    if ! confirm "Permanently delete all items in Trash?"; then
        echo "Cancelled."
        return
    fi

    echo -e "${YELLOW}Emptying Trash...${RESET}"
    if [[ $IS_DRY_RUN -eq 1 ]]; then
        echo -e "${MAGENTA}[DRY RUN] Would delete contents of $HOME/.Trash${RESET}"
    else
        find "$HOME/.Trash" -mindepth 1 -delete 2>/dev/null
        echo -e "${GREEN}Trash emptied.${RESET}"
    fi
}

scan_logs() {
    local logs_size=0
    
    if [ -d "$HOME/Library/Logs" ]; then
        local user_logs
        user_logs=$(du -sk "$HOME/Library/Logs" 2>/dev/null | awk '{printf "%.0f\n", $1 * 1024}')
        logs_size=$((logs_size + user_logs))
    fi
    
    if [ -d "/Library/Logs" ]; then
        local sys_logs
        sys_logs=$(du -sk "/Library/Logs" 2>/dev/null | awk '{printf "%.0f\n", $1 * 1024}')
        logs_size=$((logs_size + sys_logs))
    fi
    
    echo "${logs_size:-0}"
}

clean_logs() {
    print_section "LOG CLEANUP"

    local size
    size=$(scan_logs)
    echo -e "Estimated size: ${BOLD}$(format_bytes "$size")${RESET}\n"
    echo "This operation removes:"
    echo "  • ~/Library/Logs/*"
    echo "  • /Library/Logs/* (requires administrator permission)"
    echo ""

    if ! confirm "Continue?"; then
        echo "Cancelled."
        return
    fi
    
    echo -e "${YELLOW}Cleaning Application and System Logs...${RESET}"
    
    if [[ $IS_DRY_RUN -eq 1 ]]; then
        echo -e "${MAGENTA}[DRY RUN] Would delete contents of $HOME/Library/Logs${RESET}"
        echo -e "${MAGENTA}[DRY RUN] Would delete contents of /Library/Logs (requires sudo)${RESET}"
        return
    fi

    echo "Cleaning User Logs..."
    find "$HOME/Library/Logs" -mindepth 1 -delete 2>/dev/null

    local sys_ok=1
    if [ -d "/Library/Logs" ]; then
        if require_sudo; then
            echo "Cleaning System Logs..."
            sudo find "/Library/Logs" -mindepth 1 -delete 2>/dev/null
        else
            print_warning "Skipped system logs."
            sys_ok=0
        fi
    fi

    if [[ $sys_ok -eq 1 ]]; then
        echo -e "${GREEN}Logs cleaned.${RESET}"
    else
        print_warning "User logs cleaned; system logs were not fully removed."
    fi
}

# The Developer Wizard
run_developer_wizard() {
    while true; do
        clear
        print_header "DEVELOPER CLEANUP WIZARD"
        print_dry_run_banner
        
        local derived_data=0
        local archives=0
        local device_support=0
        
        if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
            derived_data=$(du -sk "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null | awk '{printf "%.0f\n", $1 * 1024}')
        fi
        if [ -d "$HOME/Library/Developer/Xcode/Archives" ]; then
            archives=$(du -sk "$HOME/Library/Developer/Xcode/Archives" 2>/dev/null | awk '{printf "%.0f\n", $1 * 1024}')
        fi
        if [ -d "$HOME/Library/Developer/Xcode/iOS DeviceSupport" ]; then
            device_support=$(du -sk "$HOME/Library/Developer/Xcode/iOS DeviceSupport" 2>/dev/null | awk '{printf "%.0f\n", $1 * 1024}')
        fi
        
        echo -e "Xcode Data:"
        printf "  1. %-30s %s\n" "DerivedData" "$(format_bytes "$derived_data")"
        printf "  2. %-30s %s\n" "Archives" "$(format_bytes "$archives")"
        printf "  3. %-30s %s\n" "iOS DeviceSupport" "$(format_bytes "$device_support")"
        echo ""
        printf "  0. %-30s\n" "Back"
        echo ""
        
        echo -e -n "${CYAN}Select items to clean (e.g. '1 3' or '1 2 3'):${RESET} "
        read -r selected || exit 0
        
        if [[ -z "$selected" ]]; then
            continue
        fi

        if [[ "$selected" == "0" ]]; then
            return
        fi
        
        echo ""

        local did_work=0
        for opt in $selected; do
            case "$opt" in
                1|2|3) did_work=1 ;;
            esac
        done

        if [[ $did_work -eq 0 ]]; then
            echo "Invalid option."
            sleep 1
            continue
        fi

        if ! confirm "Delete the selected Xcode data?"; then
            echo "Cancelled."
            pause
            continue
        fi
        
        for opt in $selected; do
            case "$opt" in
                1)
                    if [[ $IS_DRY_RUN -eq 1 ]]; then
                        echo -e "${MAGENTA}[DRY RUN] Would delete Xcode DerivedData${RESET}"
                    else
                        echo "Deleting DerivedData..."
                        find "$HOME/Library/Developer/Xcode/DerivedData" -mindepth 1 -delete 2>/dev/null
                    fi
                    ;;
                2)
                    if [[ $IS_DRY_RUN -eq 1 ]]; then
                        echo -e "${MAGENTA}[DRY RUN] Would delete Xcode Archives${RESET}"
                    else
                        echo "Deleting Archives..."
                        find "$HOME/Library/Developer/Xcode/Archives" -mindepth 1 -delete 2>/dev/null
                    fi
                    ;;
                3)
                    if [[ $IS_DRY_RUN -eq 1 ]]; then
                        echo -e "${MAGENTA}[DRY RUN] Would delete Xcode iOS DeviceSupport${RESET}"
                    else
                        echo "Deleting iOS DeviceSupport..."
                        find "$HOME/Library/Developer/Xcode/iOS DeviceSupport" -mindepth 1 -delete 2>/dev/null
                    fi
                    ;;
            esac
        done
        
        echo -e "${GREEN}Developer cleanup complete.${RESET}"
        pause
    done
}

run_more_menu() {
    while true; do
        clear
        print_header "MORE OPTIONS"
        print_dry_run_banner
        
        local trash_size=$(scan_trash)
        local logs_size=$(scan_logs)
        
        printf "  1. %-35s %s\n" "Clean Application & System Logs" "$(format_bytes "$logs_size")"
        printf "  2. %-35s %s\n" "Empty Trash" "$(format_bytes "$trash_size")"
        printf "  3. %-35s\n" "Developer Cleanup Wizard (Xcode)"
        printf "  4. %-35s\n" "Find & Delete Duplicate Files"
        echo ""
        printf "  0. %-35s\n" "Back to Main Menu"
        echo ""
        
        echo -e -n "${CYAN}Select an option:${RESET} "
        read -r option || exit 0
        
        echo ""
        case "$option" in
            1) clean_logs ;;
            2) clean_trash ;;
            3) run_developer_wizard; continue ;;
            4) run_duplicate_finder ;;
            0) return ;;
            *) echo "Invalid option."; sleep 1; continue ;;
        esac
        
        pause
    done
}
