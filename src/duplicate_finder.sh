#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

run_duplicate_finder() {
    while true; do
        clear
        print_header "DUPLICATE FINDER"
        
        echo -e "Where should we search?\n"
        echo "  1. Downloads"
        echo "  2. Documents"
        echo "  3. Desktop"
        echo "  4. Pictures"
        echo "  5. Movies"
        echo "  6. Custom location"
        echo ""
        echo "  0. Back"
        echo ""
        
        echo -e -n "${CYAN}Select a location:${RESET} "
        read -r loc_opt
        
        local target_dir=""
        case "$loc_opt" in
            1) target_dir="$HOME/Downloads" ;;
            2) target_dir="$HOME/Documents" ;;
            3) target_dir="$HOME/Desktop" ;;
            4) target_dir="$HOME/Pictures" ;;
            5) target_dir="$HOME/Movies" ;;
            6)
                echo -e -n "\nEnter full path (e.g., /Users/name/Projects): "
                read -r custom_dir
                target_dir=$(eval echo "$custom_dir") # expand ~ if provided
                ;;
            0) return ;;
            *) echo "Invalid option."; sleep 1; continue ;;
        esac
        
        if [ ! -d "$target_dir" ]; then
            echo -e "\n${RED}Directory not found: $target_dir${RESET}"
            sleep 2
            continue
        fi
        
        clear
        print_header "MINIMUM FILE SIZE"
        
        echo -e "Only scan files larger than:\n"
        echo "  1. 1 MB"
        echo "  2. 10 MB"
        echo "  3. 50 MB"
        echo "  4. 100 MB"
        echo "  5. 500 MB"
        echo "  6. Custom (in bytes)"
        echo ""
        echo "  0. Back"
        echo ""
        
        echo -e -n "${CYAN}Select minimum size:${RESET} "
        read -r size_opt
        
        local min_bytes=0
        case "$size_opt" in
            1) min_bytes=$((1 * 1024 * 1024)) ;;
            2) min_bytes=$((10 * 1024 * 1024)) ;;
            3) min_bytes=$((50 * 1024 * 1024)) ;;
            4) min_bytes=$((100 * 1024 * 1024)) ;;
            5) min_bytes=$((500 * 1024 * 1024)) ;;
            6)
                echo -e -n "\nEnter size in bytes (e.g., 1048576 for 1MB): "
                read -r min_bytes
                if ! [[ "$min_bytes" =~ ^[0-9]+$ ]]; then
                    echo "Invalid number."
                    sleep 1; continue
                fi
                ;;
            0) continue ;;
            *) echo "Invalid option."; sleep 1; continue ;;
        esac
        
        echo -e "\n${YELLOW}Scanning $target_dir for files > $(format_bytes $min_bytes)...${RESET}"
        
        # Step 1: Collect files by size
        # MacOS stat: stat -f%z returns size in bytes
        declare -A size_groups
        local count_scanned=0
        
        while IFS= read -r -d '' file; do
            if [ -f "$file" ]; then
                local size
                size=$(stat -f%z "$file" 2>/dev/null)
                if [ -n "$size" ] && [ "$size" -ge "$min_bytes" ]; then
                    size_groups["$size"]+="$file"$'\n'
                    count_scanned=$((count_scanned + 1))
                fi
            fi
        done < <(find "$target_dir" -type f -print0 2>/dev/null)
        
        if [ "$count_scanned" -eq 0 ]; then
            echo -e "\nNo files found matching criteria."
            echo -e -n "Press Enter to continue..."
            read -r
            continue
        fi
        
        # Step 2: Hash files that share exact byte sizes
        echo "Hashing potential duplicates..."
        
        # Create a temp file to store duplicate groups
        local tmp_file=$(mktemp)
        local group_id=1
        local total_recoverable=0
        
        for size in "${!size_groups[@]}"; do
            local files="${size_groups[$size]}"
            local num_files=$(printf "%s" "$files" | grep -c .)
            
            if [ "$num_files" -lt 2 ]; then
                continue
            fi
            
            # They have the same size, hash them
            declare -A hash_groups
            
            while IFS= read -r file; do
                [ -z "$file" ] && continue
                local file_hash=$(shasum -a 256 "$file" 2>/dev/null | awk '{print $1}')
                if [ -n "$file_hash" ]; then
                    hash_groups["$file_hash"]+="$file"$'\n'
                fi
            done <<< "$files"
            
            # Check for actual duplicates based on hash
            for h in "${!hash_groups[@]}"; do
                local h_files="${hash_groups[$h]}"
                local h_count=$(printf "%s" "$h_files" | grep -c .)
                
                if [ "$h_count" -ge 2 ]; then
                    local recoverable_size=$((size * (h_count - 1)))
                    total_recoverable=$((total_recoverable + recoverable_size))
                    
                    echo -e "\n${BOLD}Group $group_id — $(format_bytes $recoverable_size) recoverable${RESET}"
                    echo "────────────────────────────────"
                    
                    local file_idx=1
                    while IFS= read -r f; do
                        [ -z "$f" ] && continue
                        echo "$file_idx. $f"
                        # Save mapping to temp file
                        echo "$group_id|$file_idx|$f" >> "$tmp_file"
                        file_idx=$((file_idx + 1))
                    done <<< "$h_files"
                    
                    group_id=$((group_id + 1))
                fi
            done
        done
        
        if [ "$group_id" -eq 1 ]; then
            echo -e "\nNo actual duplicates found!"
            rm -f "$tmp_file"
            echo -e -n "Press Enter to continue..."
            read -r
            continue
        fi
        
        echo -e "\n${YELLOW}Summary: Found $((group_id - 1)) duplicate groups. Potential recovery: $(format_bytes $total_recoverable)${RESET}"
        
        echo -e "\nFor each group, we will keep file #1 and move the rest to Trash."
        echo "If you want to keep a DIFFERENT file, or skip a group, this simple MVP will just use the default (keep #1)."
        
        echo -e -n "\n${CYAN}Move all duplicates (except #1 in each group) to Trash? [y/N]:${RESET} "
        read -r confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            local deleted_count=0
            local saved_bytes=0
            
            while IFS='|' read -r gid fid filepath; do
                if [ "$fid" -ne 1 ]; then
                    if [ "$DRY_RUN" = true ]; then
                        echo "[DRY RUN] Would move to trash: $filepath"
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
        echo -e -n "\nPress Enter to return..."
        read -r
    done
}
