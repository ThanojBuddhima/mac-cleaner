#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Unit separator — valid in theory as a filename char, vanishingly rare in practice
US=$'\037'

is_icloud_dataless() {
    local flags_hex
    flags_hex=$(stat -f %f "$1" 2>/dev/null) || return 1
    flags_hex=${flags_hex#0x}
    [[ -z "$flags_hex" ]] && return 1
    local flags_dec=$((16#$flags_hex))
    # UF_DATALESS = 0x40000000
    (( flags_dec & 1073741824 ))
}

run_duplicate_finder() {
    clear
    print_header "DUPLICATE FINDER"
    print_dry_run_banner
    
    echo -e "Where should we search for duplicates?\n"
    echo "  1. Entire Home Folder (Skips Library and hidden files)"
    echo "  2. Downloads"
    echo "  3. Documents"
    echo "  4. Desktop"
    echo "  5. Pictures"
    echo "  6. Movies"
    echo ""
    echo "  0. Back"
    echo ""
    
    echo -e -n "${CYAN}Select a location:${RESET} "
    read -r loc_opt || exit 0
    
    local target_dir=""
    local skip_sys=0
    
    case "$loc_opt" in
        1) target_dir="$HOME"; skip_sys=1 ;;
        2) target_dir="$HOME/Downloads" ;;
        3) target_dir="$HOME/Documents" ;;
        4) target_dir="$HOME/Desktop" ;;
        5) target_dir="$HOME/Pictures" ;;
        6) target_dir="$HOME/Movies" ;;
        0) return ;;
        *) echo "Invalid option."; sleep 1; return ;;
    esac
    
    if [ ! -d "$target_dir" ]; then
        echo -e "\n${RED}Directory not found: $target_dir${RESET}"
        sleep 2
        return
    fi
    
    echo -e "\n${YELLOW}Scanning $target_dir for duplicate files...${RESET}"
    echo "This may take a minute. iCloud placeholder files are skipped."
    
    local tmp_sizes tmp_files_to_hash tmp_hashes tmp_groups
    tmp_sizes=$(mktemp)
    tmp_files_to_hash=$(mktemp)
    tmp_hashes=$(mktemp)
    tmp_groups=$(mktemp)
    register_temp "$tmp_sizes"
    register_temp "$tmp_files_to_hash"
    register_temp "$tmp_hashes"
    register_temp "$tmp_groups"
    
    # 1. Find non-empty files, get size<US>filepath
    if [ "$skip_sys" -eq 1 ]; then
        find "$target_dir" -type f -not -path '*/\.*' -not -path "$HOME/Library/*" -size +0 -print0 2>/dev/null | \
            xargs -0 stat -f "%z${US}%N" 2>/dev/null > "$tmp_sizes"
    else
        find "$target_dir" -type f -size +0 -print0 2>/dev/null | \
            xargs -0 stat -f "%z${US}%N" 2>/dev/null > "$tmp_sizes"
    fi

    if [ ! -s "$tmp_sizes" ]; then
        echo -e "\nNo files found to compare."
        rm -f "$tmp_sizes" "$tmp_files_to_hash" "$tmp_hashes" "$tmp_groups"
        return
    fi
    
    echo "Filtering files by size..."
    
    awk -F "$US" '
    {
        size = $1
        file = $2
        for (i = 3; i <= NF; i++) file = file FS $i
        count[size]++
        nfiles[size] = (size in nfiles) ? nfiles[size] + 1 : 1
        paths[size, nfiles[size]] = file
    }
    END {
        for (s in count) {
            if (count[s] > 1) {
                for (i = 1; i <= nfiles[s]; i++) {
                    print paths[s, i]
                }
            }
        }
    }' "$tmp_sizes" > "$tmp_files_to_hash"
    
    if [ ! -s "$tmp_files_to_hash" ]; then
        echo -e "\nNo duplicate sizes found."
        rm -f "$tmp_sizes" "$tmp_files_to_hash" "$tmp_hashes" "$tmp_groups"
        return
    fi
    
    echo "Hashing potential duplicates (this may take a bit)..."
    
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        if is_icloud_dataless "$file"; then
            continue
        fi
        local hash size
        hash=$(shasum -a 256 "$file" 2>/dev/null | awk '{print $1}')
        if [ -n "$hash" ]; then
            size=$(stat -f%z "$file" 2>/dev/null)
            printf '%s\037%s\037%s\n' "$hash" "$size" "$file" >> "$tmp_hashes"
        fi
    done < "$tmp_files_to_hash"
    
    awk -F '\037' '
    {
        hash = $1
        size = $2
        file = $3
        for (i = 4; i <= NF; i++) file = file FS $i
        
        count[hash]++
        sizes[hash] = size
        nfiles[hash]++
        paths[hash, nfiles[hash]] = file
    }
    END {
        group_id = 1
        for (h in count) {
            if (count[h] > 1) {
                recoverable = sizes[h] * (count[h] - 1)
                for (i = 1; i <= nfiles[h]; i++) {
                    print group_id "\037" i "\037" paths[h, i] "\037" recoverable
                }
                group_id++
            }
        }
    }' "$tmp_hashes" > "$tmp_groups"
    
    if [ ! -s "$tmp_groups" ]; then
        echo -e "\nNo actual duplicates found!"
        rm -f "$tmp_sizes" "$tmp_files_to_hash" "$tmp_hashes" "$tmp_groups"
        return
    fi
    
    local num_groups total_recoverable
    num_groups=$(awk -F '\037' '{ if ($1+0 > max) max=$1+0 } END { print max+0 }' "$tmp_groups")
    total_recoverable=$(awk -F '\037' '$2 == 1 {sum += $4} END { if (sum == "") print 0; else print sum }' "$tmp_groups")
    
    while true; do
        clear
        print_header "DUPLICATES FOUND"
        print_dry_run_banner
        
        echo -e "${YELLOW}Found $num_groups duplicate groups. Potential recovery: $(format_bytes "$total_recoverable")${RESET}\n"
        
        echo "What would you like to do?"
        echo "  1. Delete duplicates one by one (Interactive)"
        echo "  2. Delete ALL duplicates (Keeps the first file of each group)"
        echo ""
        echo "  0. Cancel & go back"
        echo ""
        
        echo -e -n "${CYAN}Select an option:${RESET} "
        read -r opt || exit 0
        
        echo ""
        
        case "$opt" in
            1)
                local deleted_count=0
                local g
                
                for (( g=1; g<=num_groups; g++ )); do
                    clear
                    print_header "GROUP $g OF $num_groups"
                    print_dry_run_banner
                    
                    local files_in_group=()
                    local idx=1
                    
                    while IFS=$'\037' read -r gid fid filepath rsize; do
                        if [ "$gid" -eq "$g" ]; then
                            echo "$idx. $filepath"
                            files_in_group[$idx]="$filepath"
                            idx=$((idx + 1))
                        fi
                    done < "$tmp_groups"
                    
                    echo ""
                    echo -e -n "${CYAN}Enter numbers to Trash (e.g., '2 3' or '2,3') or press Enter to keep all:${RESET} "
                    read -r to_delete || exit 0
                    
                    if [ -n "$to_delete" ]; then
                        to_delete="${to_delete//,/ }"
                        local del_idx f_del
                        for del_idx in $to_delete; do
                            f_del="${files_in_group[$del_idx]}"
                            if [ -n "$f_del" ]; then
                                if [[ $IS_DRY_RUN -eq 1 ]]; then
                                    echo "[DRY RUN] Would trash: $f_del"
                                else
                                    if move_to_trash "$f_del"; then
                                        echo "Trashed: $f_del"
                                        deleted_count=$((deleted_count + 1))
                                    else
                                        echo "Failed to trash: $f_del"
                                    fi
                                fi
                            fi
                        done
                    fi
                    echo -e -n "\nPress Enter for next group..."
                    read -r || exit 0
                done
                
                echo -e "\n${GREEN}Cleanup complete! Moved $deleted_count files to Trash.${RESET}"
                rm -f "$tmp_sizes" "$tmp_files_to_hash" "$tmp_hashes" "$tmp_groups"
                return
                ;;
            2)
                echo -e -n "${RED}Are you sure you want to move all duplicate copies to Trash? [y/N]:${RESET} "
                read -r confirm || exit 0
                
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    local deleted_count=0
                    while IFS=$'\037' read -r gid fid filepath rsize; do
                        if [ "$fid" -ne 1 ]; then
                            if [[ $IS_DRY_RUN -eq 1 ]]; then
                                echo "[DRY RUN] Would trash: $filepath"
                            else
                                if move_to_trash "$filepath"; then
                                    echo "Trashed: $filepath"
                                    deleted_count=$((deleted_count + 1))
                                else
                                    echo "Failed to trash: $filepath"
                                fi
                            fi
                        fi
                    done < "$tmp_groups"
                    echo -e "\n${GREEN}Cleanup complete! Moved $deleted_count files to Trash.${RESET}"
                else
                    echo "Cancelled."
                fi
                rm -f "$tmp_sizes" "$tmp_files_to_hash" "$tmp_hashes" "$tmp_groups"
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
