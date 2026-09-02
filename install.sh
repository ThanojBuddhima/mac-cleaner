#!/usr/bin/env bash

echo -e "\033[1mInstalling Mac Cleaner CLI...\033[0m"

INSTALL_DIR="$HOME/.mac-cleaner"
BIN_DIR="/usr/local/bin"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install git and try again."
    exit 1
fi

if [ -d "$INSTALL_DIR" ]; then
    echo "Updating existing installation in $INSTALL_DIR..."
    cd "$INSTALL_DIR" || exit
    git pull origin main
else
    echo "Cloning repository to $INSTALL_DIR..."
    git clone https://github.com/ThanojBuddhima/SystemDataCleaner.git "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        echo -e "\n\033[0;31mError: Failed to clone repository.\033[0m"
        echo "Please check your internet connection or git configuration and try again."
        exit 1
    fi
fi

echo "Setting execute permissions..."
chmod +x "$INSTALL_DIR/mac-cleaner"

echo "Creating symlink in $BIN_DIR (may require administrator password)..."
if [ ! -d "$BIN_DIR" ]; then
    sudo mkdir -p "$BIN_DIR"
fi
sudo ln -sf "$INSTALL_DIR/mac-cleaner" "$BIN_DIR/mac-cleaner"

if [ $? -eq 0 ]; then
    echo -e "\n\033[0;32mInstallation complete!\033[0m"
    echo -e "You can now run the tool from anywhere in your terminal by typing: \033[1mmac-cleaner\033[0m"
else
    echo -e "\n\033[0;31mFailed to create symlink.\033[0m"
    echo "You can still run it manually using: $INSTALL_DIR/mac-cleaner"
fi
