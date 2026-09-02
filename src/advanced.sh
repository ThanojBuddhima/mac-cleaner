#!/usr/bin/env bash

# Advanced / More options

scan_trash() {
    local trash_size=0
    if [ -d "$HOME/.Trash" ]; then
        trash_size=$(du -sk "$HOME/.Trash" 2>/dev/null | awk '{print $1 * 1024}')
    fi
    echo "${trash_size:-0}"
}

clean_trash() {
    echo -e "${YELLOW}Emptying Trash...${RESET}"
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would delete contents of $HOME/.Trash"
    else
        rm -rf "$HOME/.Trash/"* 2>/dev/null
        echo -e "${GREEN}Trash emptied.${RESET}"
    fi
}

scan_logs() {
    local logs_size=0
    
    if [ -d "$HOME/Library/Logs" ]; then
        local user_logs=$(du -sk "$HOME/Library/Logs" 2>/dev/null | awk '{print $1 * 1024}')
        logs_size=$((logs_size + user_logs))
    fi
    
    if [ -d "/Library/Logs" ]; then
        local sys_logs=$(du -sk "/Library/Logs" 2>/dev/null | awk '{print $1 * 1024}')
        logs_size=$((logs_size + sys_logs))
    fi
    
    echo "${logs_size:-0}"
}

clean_logs() {
    echo -e "${YELLOW}Cleaning Application and System Logs...${RESET}"
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would delete contents of $HOME/Library/Logs"
        echo "[DRY RUN] Would delete contents of /Library/Logs (requires sudo)"
    else
        echo "Cleaning User Logs..."
        rm -rf "$HOME/Library/Logs/"* 2>/dev/null
        
        echo "Cleaning System Logs (Requires administrator password)..."
        sudo rm -rf "/Library/Logs/"* 2>/dev/null
        
        echo -e "${GREEN}Logs cleaned.${RESET}"
    fi
}

# The Developer Wizard
run_developer_wizard() {
    while true; do
        clear
        print_header "DEVELOPER CLEANUP WIZARD"
        
        local derived_data=0
        local archives=0
        local device_support=0
        
        if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
            derived_data=$(du -sk "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null | awk '{print $1 * 1024}')
        fi
        if [ -d "$HOME/Library/Developer/Xcode/Archives" ]; then
            archives=$(du -sk "$HOME/Library/Developer/Xcode/Archives" 2>/dev/null | awk '{print $1 * 1024}')
        fi
        if [ -d "$HOME/Library/Developer/Xcode/iOS DeviceSupport" ]; then
            device_support=$(du -sk "$HOME/Library/Developer/Xcode/iOS DeviceSupport" 2>/dev/null | awk '{print $1 * 1024}')
        fi
        
        echo -e "Xcode Data:"
        printf "  1. %-30s %s\n" "DerivedData" "$(format_bytes $derived_data)"
        printf "  2. %-30s %s\n" "Archives" "$(format_bytes $archives)"
        printf "  3. %-30s %s\n" "iOS DeviceSupport" "$(format_bytes $device_support)"
        echo ""
        printf "  0. %-30s\n" "Back"
        echo ""
        
        echo -e -n "${CYAN}Select items to clean (e.g. '1 3' or '1 2 3'):${RESET} "
        read -r selected
        
        if [[ "$selected" == "0" ]]; then
            return
        fi
        
        echo ""
        
        for opt in $selected; do
            case "$opt" in
                1)
                    if [ "$DRY_RUN" = true ]; then
                        echo "[DRY RUN] Would delete Xcode DerivedData"
                    else
                        echo "Deleting DerivedData..."
                        rm -rf "$HOME/Library/Developer/Xcode/DerivedData/"* 2>/dev/null
                    fi
                    ;;
                2)
                    if [ "$DRY_RUN" = true ]; then
                        echo "[DRY RUN] Would delete Xcode Archives"
                    else
                        echo "Deleting Archives..."
                        rm -rf "$HOME/Library/Developer/Xcode/Archives/"* 2>/dev/null
                    fi
                    ;;
                3)
                    if [ "$DRY_RUN" = true ]; then
                        echo "[DRY RUN] Would delete Xcode iOS DeviceSupport"
                    else
                        echo "Deleting iOS DeviceSupport..."
                        rm -rf "$HOME/Library/Developer/Xcode/iOS DeviceSupport/"* 2>/dev/null
                    fi
                    ;;
            esac
        done
        
        echo -e "${GREEN}Developer cleanup complete.${RESET}"
        echo -e -n "${CYAN}Press Enter to continue...${RESET}"
        read -r
    done
}

run_more_menu() {
    while true; do
        clear
        print_header "MORE OPTIONS"
        
        local trash_size=$(scan_trash)
        local logs_size=$(scan_logs)
        
        printf "  1. %-35s %s\n" "Clean Application & System Logs" "$(format_bytes $logs_size)"
        printf "  2. %-35s %s\n" "Empty Trash" "$(format_bytes $trash_size)"
        printf "  3. %-35s\n" "Developer Cleanup Wizard (Xcode)"
        echo ""
        printf "  0. %-35s\n" "Back to Main Menu"
        echo ""
        
        echo -e -n "${CYAN}Select an option:${RESET} "
        
        read -r option
        
        echo ""
        case "$option" in
            1) clean_logs ;;
            2) clean_trash ;;
            3) run_developer_wizard ;;
            0) return ;;
            *) echo "Invalid option." ;;
        esac
        
        echo ""
        echo -e -n "${CYAN}Press Enter to continue...${RESET}"
        read -r
    done
}
