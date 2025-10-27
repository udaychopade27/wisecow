#!/bin/bash

# Source directory where backup has to be taken
set -e
read -p "Enter the source directory for backup (default: $src_dir): " input_src_dir
if [ -n "$input_src_dir" ]; then        
    src_dir="$input_src_dir"
    fi          
echo "Source Directory: $src_dir"

# Target directory where backup files are to be stored

read -p "Enter the target directory for backup (default: $tgt_dir): " input_tgt_dir
if [ -n "$input_tgt_dir" ]; then
  tgt_dir="$input_tgt_dir"
fi
echo "Source Directory: $src_dir"
echo "Target Directory: $tgt_dir"   
# Current timestamp
curr_timestamp=$(date +"%Y-%m-%d-%H-%M")

echo "Backup Timestamp: $curr_timestamp"

# Backup filename
backup_file="$tgt_dir/backup_$curr_timestamp.tgz"

echo "Backup Filename: $backup_file"

# Create the backup
tar -czf "$backup_file" -C "$src_dir" .

echo "Backup Complete"
echo "Backup of '$src_dir' completed and stored at '$backup_file'"