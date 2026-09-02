#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

run_duplicate_finder() {
    clear
    print_header "DUPLICATE FINDER"
    
    echo -e "Where should we search for duplicates (>1MB)?\n"
    echo "  1. Entire Home Folder (Skips Library and hidden files)"
    echo "  2. Downloads"
    echo "  3. Documents"
    echo "  4. Desktop"
    echo "  5. Pictures"
    echo "  6. Movies"
    echo "  7. Custom location"
    echo ""
    echo "  0. Back"
    echo ""
    
    echo -e -n "${CYAN}Select a location:${RESET} "
    read -r loc_opt
    
    local target_dir=""
    local skip_sys=0
    
    case "$loc_opt" in
        1) target_dir="$HOME"; skip_sys=1 ;;
        2) target_dir="$HOME/Downloads" ;;
        3) target_dir="$HOME/Documents" ;;
        4) target_dir="$HOME/Desktop" ;;
        5) target_dir="$HOME/Pictures" ;;
        6) target_dir="$HOME/Movies" ;;
        7)
            echo -e -n "\nEnter full path (e.g., /Users/name/Projects): "
            read -r custom_dir
            target_dir=$(eval echo "$custom_dir") # expand ~ if provided
            ;;
        0) return ;;
        *) echo "Invalid option."; sleep 1; return ;;
    esac
    
    if [ ! -d "$target_dir" ]; then
        echo -e "\n${RED}Directory not found: $target_dir${RESET}"
        sleep 2
        return
    fi
    
    echo -e "\n${YELLOW}Scanning $target_dir for duplicate files...${RESET}"
    echo "This may take a minute."
    
    local tmp_sizes=$(mktemp)
    local tmp_files_to_hash=$(mktemp)
    local tmp_hashes=$(mktemp)
    local tmp_groups=$(mktemp)
    
    # 1. Find files > 1MB, get size|filepath
    if [ "$skip_sys" -eq 1 ]; then
        find "$target_dir" -type f -not -path '*/\.*' -not -path "$HOME/Library/*" -size +1M -print0 2>/dev/null | \
            xargs -0 stat -f "%z|%N" 2>/dev/null > "$tmp_sizes"
    else
        find "$target_dir" -type f -size +1M -print0 2>/dev/null | \
            xargs -0 stat -f "%z|%N" 2>/dev/null > "$tmp_sizes"
    fi

    if [ ! -s "$tmp_sizes" ]; then
        echo -e "\nNo large files found to compare."
        rm -f "$tmp_sizes" "$tmp_files_to_hash" "$tmp_hashes" "$tmp_groups"
        echo -e -n "Press Enter to continue..."
        read -r
        return
    fi
    
    echo "Filtering files by size..."
    
    # 2. Extract files that share the same size
    awk -F'|' '
    {
        size = $1
        file = substr($0, length(size) + 2)
        count[size]++
        files[size] = (size in files) ? files[size] "|" file : file
    }
    END {
        for (s in count) {
            if (count[s] > 1) {
                # split and print each file
                split(files[s], arr, "|")
                for (i in arr) {
                    print arr[i]
                }
            }
        }
    }' "$tmp_sizes" > "$tmp_files_to_hash"
    
    if [ ! -s "$tmp_files_to_hash" ]; then
        echo -e "\nNo duplicate sizes found."
        rm -f "$tmp_sizes" "$tmp_files_to_hash" "$tmp_hashes" "$tmp_groups"
        echo -e -n "Press Enter to continue..."
        read -r
        return
    fi
    
    echo "Hashing potential duplicates (this may take a bit)..."
    
    # 3. Hash files that share sizes
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        # Hash and output hash|size|filepath
        # (We need size to calculate recoverable space later)
        local hash
        hash=$(shasum -a 256 "$file" 2>/dev/null | awk '{print $1}')
        if [ -n "$hash" ]; then
            local size
            size=$(stat -f%z "$file" 2>/dev/null)
            echo "${hash}|${size}|${file}" >> "$tmp_hashes"
        fi
    done < "$tmp_files_to_hash"
    
    # 4. Group by hash and calculate recovery space
    # Output format: GroupID|FileIdx|FilePath|RecoverableSize
    awk -F'|' '
    {
        hash = $1
        size = $2
        file = substr($0, length(hash) + length(size) + 3)
        
        count[hash]++
        files[hash] = (hash in files) ? files[hash] "|" file : file
        sizes[hash] = size
    }
    END {
        group_id = 1
        for (h in count) {
            if (count[h] > 1) {
                n = split(files[h], arr, "|")
                recoverable = sizes[h] * (n - 1)
                
                for (i=1; i<=n; i++) {
                    print group_id "|" i "|" arr[i] "|" recoverable
                }
                group_id++
            }
        }
    }' "$tmp_hashes" > "$tmp_groups"
    
    if [ ! -s "$tmp_groups" ]; then
        echo -e "\nNo actual duplicates found!"
        rm -f "$tmp_sizes" "$tmp_files_to_hash" "$tmp_hashes" "$tmp_groups"
        echo -e -n "Press Enter to continue..."
        read -r
        return
    fi
    
    local num_groups=$(tail -1 "$tmp_groups" | awk -F'|' '{print $1}')
    local total_recoverable=$(awk -F'|' '$2 == 1 {sum += $4} END {print sum}' "$tmp_groups")
    
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
                    done < "$tmp_groups"
                    
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
                rm -f "$tmp_sizes" "$tmp_files_to_hash" "$tmp_hashes" "$tmp_groups"
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
                    done < "$tmp_groups"
                    echo -e "\n${GREEN}Cleanup complete! Moved $deleted_count files to Trash.${RESET}"
                else
                    echo "Cancelled."
                fi
                rm -f "$tmp_sizes" "$tmp_files_to_hash" "$tmp_hashes" "$tmp_groups"
                echo -e -n "Press Enter to return..."
                read -r
                return
                ;;
            0)
                rm -f "$tmp_sizes" "$tmp_files_to_hash" "$tmp_hashes" "$tmp_groups"
                return
                ;;
            *)
                echo "Invalid option."
                sleep 1
                ;;
        esac
    done
}
