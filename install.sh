#!/usr/bin/env bash

echo -e "\033[1mInstalling Mac Cleaner CLI...\033[0m"

INSTALL_DIR="$HOME/.mac-cleaner"
USER_BIN="$HOME/.local/bin"
BREW_BIN="/opt/homebrew/bin"
LOCAL_BIN="/usr/local/bin"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install git and try again."
    exit 1
fi

if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing installation in $INSTALL_DIR..."
    if ! git -C "$INSTALL_DIR" pull origin main; then
        echo -e "\033[0;33mWarning: git pull failed. Using the existing files.\033[0m"
    fi
elif [ -d "$INSTALL_DIR" ]; then
    echo -e "\033[0;33mWarning: $INSTALL_DIR exists but is not a git repository. Leaving it as-is.\033[0m"
else
    echo "Cloning repository to $INSTALL_DIR..."
    if ! git clone https://github.com/ThanojBuddhima/mac-cleaner.git "$INSTALL_DIR"; then
        echo -e "\n\033[0;31mError: Failed to clone repository.\033[0m"
        echo "Please check your internet connection or git configuration and try again."
        exit 1
    fi
fi

if [ ! -f "$INSTALL_DIR/mac-cleaner" ]; then
    echo -e "\033[0;31mError: $INSTALL_DIR/mac-cleaner was not found.\033[0m"
    exit 1
fi

echo "Setting execute permissions..."
chmod +x "$INSTALL_DIR/mac-cleaner"

mkdir -p "$USER_BIN"

BIN_DIR=""
USED_SUDO=0

if [ -d "$BREW_BIN" ] && [ -w "$BREW_BIN" ]; then
    BIN_DIR="$BREW_BIN"
elif [ -w "$USER_BIN" ]; then
    BIN_DIR="$USER_BIN"
elif [ -d "$LOCAL_BIN" ] && [ -w "$LOCAL_BIN" ]; then
    BIN_DIR="$LOCAL_BIN"
else
    BIN_DIR="$LOCAL_BIN"
    USED_SUDO=1
fi

echo "Creating symlink in $BIN_DIR..."
if [ "$USED_SUDO" -eq 1 ]; then
    echo "(may require administrator password)"
    if [ ! -d "$BIN_DIR" ]; then
        sudo mkdir -p "$BIN_DIR"
    fi
    sudo ln -sf "$INSTALL_DIR/mac-cleaner" "$BIN_DIR/mac-cleaner"
    LINK_STATUS=$?
else
    ln -sf "$INSTALL_DIR/mac-cleaner" "$BIN_DIR/mac-cleaner"
    LINK_STATUS=$?
fi

if [ "$LINK_STATUS" -eq 0 ]; then
    echo -e "\n\033[0;32mInstallation complete!\033[0m"
    echo -e "You can now run the tool by typing: \033[1mmac-cleaner\033[0m"
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *)
            echo -e "\n\033[0;33mNote: $BIN_DIR is not in your PATH.\033[0m"
            echo "Add this to your shell profile, then open a new terminal:"
            echo "  export PATH=\"$BIN_DIR:\$PATH\""
            ;;
    esac
else
    echo -e "\n\033[0;31mFailed to create symlink.\033[0m"
    echo "You can still run it manually using: $INSTALL_DIR/mac-cleaner"
fi
