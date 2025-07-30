#!/usr/bin/env bash
set -e

VERSION="1.0.0"
REPO_URL="https://raw.githubusercontent.com/calghar/gh-account-switcher/main"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="gh-switch"

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Figure out what OS we're running on
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

# Make sure we have the tools we need
check_prerequisites() {
    local missing_deps=()
    
    # We need curl/wget, git, and jq
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

# Helper to download files with curl or wget
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

# Do the actual installation
install_gh_switch() {
    local platform=$(detect_platform)
    local script_url
    local temp_file="/tmp/gh-switch-installer"
    
    echo -e "${BLUE}GitHub Account Switcher v${VERSION} Installer${NC}"
    echo "================================================"
    echo
    
    # Pick the right script for this OS
    case "$platform" in
        macos)
            script_url="${REPO_URL}/src/gh-switch-macos.sh"
            echo -e "${GREEN}Detected platform: macOS${NC}"
            ;;
        linux)
            script_url="${REPO_URL}/src/gh-switch-linux.sh"
            echo -e "${GREEN}Detected platform: Linux${NC}"
            ;;
        windows)
            script_url="${REPO_URL}/src/gh-switch-windows.sh"
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
    
    # Grab the shared core functionality too
    local core_url="${REPO_URL}/src/gh-switch-core.sh"
    local core_temp="/tmp/gh-switch-core"
    if ! download_file "$core_url" "$core_temp"; then
        echo -e "${RED}Error: Failed to download core script${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Download completed${NC}"
    
    # Set execute permissions
    chmod +x "$temp_file"
    chmod +x "$core_temp"
    
    # Windows needs ~/bin created
    if [ "$platform" = "windows" ]; then
        mkdir -p "$INSTALL_DIR"
    fi
    
    # Move everything into place
    if [ "$platform" = "windows" ]; then
        # Windows goes to ~/bin
        cp -f "$temp_file" "$INSTALL_DIR/$SCRIPT_NAME"
        cp -f "$core_temp" "$INSTALL_DIR/gh-switch-core.sh"
        chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
        
        # Clean up temp files
        rm -f "$temp_file" "$core_temp"
        
        echo -e "${GREEN}✓ Installed to $INSTALL_DIR/$SCRIPT_NAME${NC}"
        
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
            # Detect shell and add to appropriate config file
            current_shell=$(basename "$SHELL")
            if [ "$current_shell" = "zsh" ]; then
                shell_config="$HOME/.zshrc"
            elif [ "$current_shell" = "bash" ]; then
                if [ -f "$HOME/.bash_profile" ]; then
                    shell_config="$HOME/.bash_profile"
                else
                    shell_config="$HOME/.bashrc"
                fi
            else
                # Default to .bashrc for unknown shells
                shell_config="$HOME/.bashrc"
            fi
            
            # Check if PATH addition already exists to avoid duplicates
            if ! grep -q "# Added by gh-switch installer" "$shell_config" 2>/dev/null; then
                echo "" >> "$shell_config"
                echo "# Added by gh-switch installer" >> "$shell_config"
                echo "export PATH=\"\$HOME/bin:\$PATH\"" >> "$shell_config"
                
                echo -e "${GREEN}✓ Added $HOME/bin to PATH in $shell_config${NC}"
                echo -e "${YELLOW}Note: Restart your terminal or run 'source $shell_config' to use gh-switch${NC}"
            else
                echo -e "${YELLOW}Note: PATH already configured in $shell_config${NC}"
            fi
        fi
    else
        # Install to user directory to allow easy updates
        mkdir -p "$HOME/bin"
        
        # Force overwrite existing files
        cp -f "$temp_file" "$HOME/bin/$SCRIPT_NAME"
        cp -f "$core_temp" "$HOME/bin/gh-switch-core.sh"
        chmod +x "$HOME/bin/$SCRIPT_NAME"
        
        # Clean up temp files
        rm -f "$temp_file" "$core_temp"
        
        echo -e "${GREEN}✓ Installed to $HOME/bin/$SCRIPT_NAME${NC}"
        
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
            # Detect shell and add to appropriate config file
            current_shell=$(basename "$SHELL")
            if [ "$current_shell" = "zsh" ]; then
                shell_config="$HOME/.zshrc"
            elif [ "$current_shell" = "bash" ]; then
                if [ -f "$HOME/.bash_profile" ]; then
                    shell_config="$HOME/.bash_profile"
                else
                    shell_config="$HOME/.bashrc"
                fi
            else
                # Default to .bashrc for unknown shells
                shell_config="$HOME/.bashrc"
            fi
            
            # Check if PATH addition already exists to avoid duplicates
            if ! grep -q "# Added by gh-switch installer" "$shell_config" 2>/dev/null; then
                echo "" >> "$shell_config"
                echo "# Added by gh-switch installer" >> "$shell_config"
                echo "export PATH=\"\$HOME/bin:\$PATH\"" >> "$shell_config"
                
                echo -e "${GREEN}✓ Added $HOME/bin to PATH in $shell_config${NC}"
                echo -e "${YELLOW}Note: Restart your terminal or run 'source $shell_config' to use gh-switch${NC}"
            else
                echo -e "${YELLOW}Note: PATH already configured in $shell_config${NC}"
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

# Parse command line options
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