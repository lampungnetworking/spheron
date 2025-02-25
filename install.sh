#!/bin/bash

DESTINATION_DIR="/usr/local/bin"
BINARY_NAME="sphnctl"
VERSION="latest"

check_ubuntu_version() {
    if ! command -v lsb_release >/dev/null 2>&1; then
        return 1
    fi
    local ubuntu_version
    ubuntu_version=$(lsb_release -rs 2>/dev/null)
    if [[ -n "$ubuntu_version" ]] && awk 'BEGIN{exit !('$ubuntu_version' < 20)}'; then
        return 0
    fi
    return 1
}

install_glibc() {
    echo "==================================="
    echo "     Installing/upgrading glibc"
    echo "==================================="

    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -qq && sudo apt-get install -y libc6
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y glibc
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y glibc
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper --non-interactive install glibc
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm glibc
    elif command -v brew >/dev/null 2>&1; then
        brew install gcc
    else
        echo "Unsupported package manager. Please install/upgrade glibc manually."
        return 1
    fi

    echo "==================================="
}

clear
echo "===================================="
echo "          SPHNCTL INSTALLER         "
echo "===================================="
echo ""
echo "$BINARY_NAME $VERSION"

# Check if the destination directory exists
if [ ! -d "$DESTINATION_DIR" ]; then
    echo "Creating directory $DESTINATION_DIR..."
    sudo mkdir -p "$DESTINATION_DIR"
    echo "Directory $DESTINATION_DIR created."
fi

# Detect the operating system and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"
URL=""

echo "Detecting system configuration..."
echo "Operating System: $OS"
echo "Architecture: $ARCH"

case "$OS" in
    Darwin)
        echo "System detected: macOS"
        if [ "$ARCH" == "arm64" ]; then
            URL="https://d2zwrgjg4c7ndl.cloudfront.net/bins/darwin/spheron"
        else
            echo "Unsupported architecture $ARCH for macOS."
            exit 1
        fi
        ;;
    Linux)
        echo "System detected: Linux"
        if command -v apt-get >/dev/null 2>&1; then
            if check_ubuntu_version; then
                echo "Detected Ubuntu version older than 20. Using bundled binary."
                if [ "$ARCH" == "x86_64" ]; then
                    URL="https://d2zwrgjg4c7ndl.cloudfront.net/bins/amd64-bundle/spheron"
                elif [ "$ARCH" == "arm64" ]; then
                    URL="https://d2zwrgjg4c7ndl.cloudfront.net/bins/arm64-bundle/spheron"
                fi
            else
                echo "Detected Ubuntu greater than 18.04. Installing glibc."
                install_glibc
                if [ "$ARCH" == "x86_64" ]; then
                    URL="https://d2zwrgjg4c7ndl.cloudfront.net/bins/amd64/spheron"
                elif [ "$ARCH" == "arm64" ]; then
                    URL="https://d2zwrgjg4c7ndl.cloudfront.net/bins/arm64/spheron"
                fi
            fi
        else
            # Non-Ubuntu Linux
            install_glibc
            if [ "$ARCH" == "x86_64" ]; then
                URL="https://d2zwrgjg4c7ndl.cloudfront.net/bins/amd64/spheron"
            elif [ "$ARCH" == "arm64" ]; then
                URL="https://d2zwrgjg4c7ndl.cloudfront.net/bins/arm64/spheron"
            fi
        fi

        if [ -z "$URL" ]; then
            echo "Unsupported architecture $ARCH for Linux."
            exit 1
        fi
        ;;
    *)
        echo "Unsupported Operating System: $OS."
        exit 1
        ;;
esac

echo "Fetching binary..."
if command -v curl >/dev/null 2>&1; then
    echo "Using curl to download the binary..."
    curl -sLO $URL
    mv spheron "$BINARY_NAME"
elif command -v wget >/dev/null 2>&1; then
    echo "Using wget to download the binary..."
    wget -O "$BINARY_NAME" $URL
else
    echo "Neither curl nor wget are available. Please install one of these and try again."
    exit 1
fi

echo "Installing $BINARY_NAME to $DESTINATION_DIR..."
sudo mv "$BINARY_NAME" "$DESTINATION_DIR"
sudo chmod +x "$DESTINATION_DIR/$BINARY_NAME"

echo "========================================"
echo "   SPHNCTL CLI SUCCESSFULLY INSTALLED   "
echo "========================================"

echo "Following $BINARY_NAME version: "
$BINARY_NAME version
echo "To get started, run:"
echo "  $BINARY_NAME -h"
echo "to see all available commands."
