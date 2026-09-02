#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

run_duplicate_finder() {
    clear
    print_header "DUPLICATE FINDER"
    
    echo -e "${YELLOW}Scanning your Home folder for duplicate files...${RESET}"
    echo "This may take a minute. Skipping system files and hidden folders."
    
    # We scan $HOME, exclude hidden directories and Library to protect system/app data
    # We also filter size > 1MB by default so the script doesn't take hours finding identical 2KB text files.
    declare -A size_groups
    local count_scanned=0
    
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            local size
            size=$(stat -f%z "$file" 2>/dev/null)
            if [ -n "$size" ]; then
                size_groups["$size"]+="$file"$'\n'
                count_scanned=$((count_scanned + 1))
            fi
        fi
    done < <(find "$HOME" -type f -not -path '*/\.*' -not -path "$HOME/Library/*" -size +1M -print0 2>/dev/null)
    
    if [ "$count_scanned" -eq 0 ]; then
        echo -e "\nNo large files found to compare."
        echo -e -n "Press Enter to continue..."
        read -r
        return
    fi
    
    echo "Hashing potential duplicates..."
    
    local tmp_file=$(mktemp)
    local group_id=1
    local total_recoverable=0
    
    for size in "${!size_groups[@]}"; do
        local files="${size_groups[$size]}"
        local num_files=$(printf "%s" "$files" | grep -c .)
        
        if [ "$num_files" -lt 2 ]; then
            continue
        fi
        
        declare -A hash_groups
        
        while IFS= read -r file; do
            [ -z "$file" ] && continue
            local file_hash=$(shasum -a 256 "$file" 2>/dev/null | awk '{print $1}')
            if [ -n "$file_hash" ]; then
                hash_groups["$file_hash"]+="$file"$'\n'
            fi
        done <<< "$files"
        
        for h in "${!hash_groups[@]}"; do
            local h_files="${hash_groups[$h]}"
            local h_count=$(printf "%s" "$h_files" | grep -c .)
            
            if [ "$h_count" -ge 2 ]; then
                local recoverable_size=$((size * (h_count - 1)))
                total_recoverable=$((total_recoverable + recoverable_size))
                
                local file_idx=1
                while IFS= read -r f; do
                    [ -z "$f" ] && continue
                    # Save mapping to temp file: GroupID|FileIdx|FilePath|RecoverableSize
                    echo "$group_id|$file_idx|$f|$recoverable_size" >> "$tmp_file"
                    file_idx=$((file_idx + 1))
                done <<< "$h_files"
                
                group_id=$((group_id + 1))
            fi
        done
    done
    
    if [ ! -s "$tmp_file" ]; then
        echo -e "\nNo actual duplicates found!"
        rm -f "$tmp_file"
        echo -e -n "Press Enter to continue..."
        read -r
        return
    fi
    
    local num_groups=$((group_id - 1))
    
    while true; do
        clear
        print_header "DUPLICATES FOUND"
        
        echo -e "${YELLOW}Found $num_groups duplicate groups. Potential recovery: $(format_bytes $total_recoverable)${RESET}\n"
        
        echo "What would you like to do?"
        echo "  1. Delete duplicates one by one (Interactive)"
        echo "  2. Delete ALL duplicates (Keeps the first file of each group)"
        echo ""
        echo "  0. Cancel & go back"
        echo ""
        
        echo -e -n "${CYAN}Select an option:${RESET} "
        read -r opt
        
        echo ""
        
        case "$opt" in
            1)
                local deleted_count=0
                
                for (( g=1; g<=num_groups; g++ )); do
                    clear
                    print_header "GROUP $g OF $num_groups"
                    
                    local files_in_group=()
                    local idx=1
                    
                    while IFS='|' read -r gid fid filepath rsize; do
                        if [ "$gid" -eq "$g" ]; then
                            echo "$idx. $filepath"
                            files_in_group[$idx]="$filepath"
                            idx=$((idx + 1))
                        fi
                    done < "$tmp_file"
                    
                    echo ""
                    echo -e -n "${CYAN}Enter numbers to move to Trash (space separated) or press Enter to skip:${RESET} "
                    read -r to_delete
                    
                    if [ -n "$to_delete" ]; then
                        for del_idx in $to_delete; do
                            local f_del="${files_in_group[$del_idx]}"
                            if [ -n "$f_del" ]; then
                                if [ "$DRY_RUN" = true ]; then
                                    echo "[DRY RUN] Would trash: $f_del"
                                else
                                    mkdir -p "$HOME/.Trash"
                                    mv "$f_del" "$HOME/.Trash/" 2>/dev/null
                                    echo "Trashed: $f_del"
                                    deleted_count=$((deleted_count + 1))
                                fi
                            fi
                        done
                    fi
                    echo -e -n "\nPress Enter for next group..."
                    read -r
                done
                
                echo -e "\n${GREEN}Cleanup complete! Moved $deleted_count files to Trash.${RESET}"
                rm -f "$tmp_file"
                echo -e -n "Press Enter to return..."
                read -r
                return
                ;;
            2)
                echo -e -n "${RED}Are you sure you want to move all duplicate copies to Trash? [y/N]:${RESET} "
                read -r confirm
                
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    local deleted_count=0
                    while IFS='|' read -r gid fid filepath rsize; do
                        if [ "$fid" -ne 1 ]; then
                            if [ "$DRY_RUN" = true ]; then
                                echo "[DRY RUN] Would trash: $filepath"
                            else
                                mkdir -p "$HOME/.Trash"
                                mv "$filepath" "$HOME/.Trash/" 2>/dev/null
                                echo "Trashed: $filepath"
                                deleted_count=$((deleted_count + 1))
                            fi
                        fi
                    done < "$tmp_file"
                    echo -e "\n${GREEN}Cleanup complete! Moved $deleted_count files to Trash.${RESET}"
                else
                    echo "Cancelled."
                fi
                rm -f "$tmp_file"
                echo -e -n "Press Enter to return..."
                read -r
                return
                ;;
            0)
                rm -f "$tmp_file"
                return
                ;;
            *)
                echo "Invalid option."
                sleep 1
                ;;
        esac
    done
}
