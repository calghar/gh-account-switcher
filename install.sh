#!/usr/bin/env bash
set -e

VERSION="1.0.0"
REPO_URL="https://raw.githubusercontent.com/calghar/gh-account-switcher/main"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="gh-switch"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            echo "linux"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    local missing_deps=()
    
    # Check for required tools
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        missing_deps+=("curl or wget")
    fi
    
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required dependencies:${NC}"
        printf '  - %s\n' "${missing_deps[@]}"
        echo
        echo "Please install the missing dependencies and try again."
        echo "See https://github.com/calghar/gh-account-switcher#requirements for installation instructions."
        exit 1
    fi
}

# Download file
download_file() {
    local url="$1"
    local output="$2"
    
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$output"
    else
        echo -e "${RED}Error: Neither curl nor wget is available${NC}"
        exit 1
    fi
}

# Main installation function
install_gh_switch() {
    local platform=$(detect_platform)
    local script_url
    local temp_file="/tmp/gh-switch-installer"
    
    echo -e "${BLUE}GitHub Account Switcher v${VERSION} Installer${NC}"
    echo "================================================"
    echo
    
    # Determine script URL based on platform
    case "$platform" in
        macos)
            script_url="${REPO_URL}/src/gh-switch-macos-v2.sh"
            echo -e "${GREEN}Detected platform: macOS${NC}"
            ;;
        linux)
            script_url="${REPO_URL}/src/gh-switch-linux.sh"
            echo -e "${GREEN}Detected platform: Linux${NC}"
            ;;
        windows)
            script_url="${REPO_URL}/src/gh-switch-windows-v2.sh"
            echo -e "${GREEN}Detected platform: Windows${NC}"
            INSTALL_DIR="$HOME/bin"
            ;;
        *)
            echo -e "${RED}Error: Unsupported platform${NC}"
            echo "Supported platforms: macOS, Linux, Windows (Git Bash/WSL)"
            exit 1
            ;;
    esac
    
    echo "Checking prerequisites..."
    check_prerequisites
    echo -e "${GREEN}✓ All prerequisites satisfied${NC}"
    echo
    
    echo "Downloading GitHub Account Switcher..."
    if ! download_file "$script_url" "$temp_file"; then
        echo -e "${RED}Error: Failed to download script${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Download completed${NC}"
    
    # Make script executable
    chmod +x "$temp_file"
    
    # Create install directory if it doesn't exist
    if [ "$platform" = "windows" ]; then
        mkdir -p "$INSTALL_DIR"
    fi
    
    # Install script
    if [ "$platform" = "windows" ]; then
        # Windows: Install to user directory
        mv "$temp_file" "$INSTALL_DIR/$SCRIPT_NAME"
        echo -e "${GREEN}✓ Installed to $INSTALL_DIR/$SCRIPT_NAME${NC}"
        
        # Check if directory is in PATH
        if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
            echo -e "${YELLOW}Warning: $INSTALL_DIR is not in your PATH${NC}"
            echo "Add this line to your ~/.bashrc or ~/.bash_profile:"
            echo "  export PATH=\"\$HOME/bin:\$PATH\""
        fi
    else
        # macOS/Linux: Install system-wide
        if sudo mv "$temp_file" "$INSTALL_DIR/$SCRIPT_NAME"; then
            echo -e "${GREEN}✓ Installed to $INSTALL_DIR/$SCRIPT_NAME${NC}"
        else
            echo -e "${YELLOW}Warning: Could not install system-wide, installing to user directory${NC}"
            mkdir -p "$HOME/bin"
            mv "$temp_file" "$HOME/bin/$SCRIPT_NAME"
            echo -e "${GREEN}✓ Installed to $HOME/bin/$SCRIPT_NAME${NC}"
            
            if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
                echo -e "${YELLOW}Warning: $HOME/bin is not in your PATH${NC}"
                echo "Add this line to your ~/.bashrc or ~/.bash_profile:"
                echo "  export PATH=\"\$HOME/bin:\$PATH\""
            fi
        fi
    fi
    
    echo
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo
    echo "Next steps:"
    echo "1. Verify installation: $SCRIPT_NAME --version"
    echo "2. View help: $SCRIPT_NAME help"
    echo "3. Add your first profile: $SCRIPT_NAME add work your.email@company.com"
    echo
    echo "Documentation: https://github.com/calghar/gh-account-switcher/docs"
    echo
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "GitHub Account Switcher v${VERSION} Installer"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --help, -h      Show this help message"
        echo "  --version, -v   Show version information"
        echo
        echo "This script will automatically detect your platform and install"
        echo "the appropriate version of GitHub Account Switcher."
        exit 0
        ;;
    --version|-v)
        echo "GitHub Account Switcher Installer v${VERSION}"
        exit 0
        ;;
    "")
        install_gh_switch
        ;;
    *)
        echo -e "${RED}Error: Unknown option: $1${NC}"
        echo "Use --help for usage information"
        exit 1
        ;;
esac