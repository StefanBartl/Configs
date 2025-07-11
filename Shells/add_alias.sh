#!/bin/bash

# Check if alias string is provided
if [ -z "$1" ]; then
    echo "Usage: $0 'alias yourAlias=\"command\"'"
    exit 1
fi

# Alias string to be added
alias_string="$1"

# List of target files
files=(
    ~/.bash_aliases
    ~/MyGithub/Configs/Shells/bash/.bash_aliases
    ~/MyGithub/Configs/Shells/bash/.bashrc
    ~/.zshrc
    ~/MyGithub/Configs/Shells/oh-my-zsh/.zshrc
)

# Function to add alias to a file if not already present
add_alias_to_file() {
    local file="$1"
    if grep -qxF "$alias_string" "$file"; then
        echo "Alias already exists in $file"
    else
        echo "$alias_string" >> "$file"
        echo "Alias added to $file"
    fi
}

# Loop through each file and add alias
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        add_alias_to_file "$file"
    else
        echo "File $file does not exist. Skipping."
    fi
done

