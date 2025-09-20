<!-- markdownlint-disable MD024 -->
# Installation Guide

This guide covers installation of GitHub Account Switcher on all supported platforms.

## Requirements

### Essential Requirements (All Platforms)

- **Git**: Version 2.22.0 or newer
- **Bash**: Version 4.0 or newer
- **jq**: JSON processor for profile management

### Optional Requirements

- **GPG**: For commit signing (recommended)
- **SSH**: For key-based authentication

## Installation Methods

### Quick Install (Recommended)

**One-liner for all platforms:**

```bash
curl -fsSL https://raw.githubusercontent.com/calghar/gh-account-switcher/main/install.sh | bash
```

This installer will:

- Detect your platform automatically
- Install to `~/bin` (allows easy updates without sudo)
- Add `~/bin` to your PATH automatically
- Handle shell configuration (bash/zsh)

### Manual Installation

#### macOS

**Prerequisites:**

```bash
# Install via Homebrew (recommended)
brew install git jq gnupg pinentry-mac

# Or via MacPorts
sudo port install git jq gnupg2 pinentry-mac
```

**Installation:**

```bash
# Download and install to user directory
curl -o gh-switch.sh https://raw.githubusercontent.com/calghar/gh-account-switcher/main/src/gh-switch-macos.sh
chmod +x gh-switch.sh
mkdir -p ~/bin
mv gh-switch.sh ~/bin/gh-switch

# Add to PATH if not already there
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc  # or ~/.bash_profile
source ~/.zshrc  # or ~/.bash_profile

# Verify installation
gh-switch --version
```

#### Linux

**Prerequisites:**

**Debian/Ubuntu:**

```bash
sudo apt-get update
sudo apt-get install git jq gnupg2 libsecret-1-0
```

**RHEL/CentOS/Fedora:**

```bash
sudo dnf install git jq gnupg2 libsecret
```

**Arch Linux:**

```bash
sudo pacman -S git jq gnupg libsecret
```

**Installation:**

```bash
# Download and install to user directory
curl -o gh-switch.sh https://raw.githubusercontent.com/calghar/gh-account-switcher/main/src/gh-switch-linux.sh
chmod +x gh-switch.sh
mkdir -p ~/bin
mv gh-switch.sh ~/bin/gh-switch

# Add to PATH if not already there
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
gh-switch --version
```

### Windows

#### Prerequisites

**Via Chocolatey:**

```powershell
choco install git jq gpg4win
```

**Via Scoop:**

```powershell
scoop install git jq gpg4win
```

**Via Winget:**

```powershell
winget install Git.Git jqlang.jq GnuPG.Gpg4win
```

#### Installation Options

##### **Option 1: Git Bash**

```bash
# In Git Bash
curl -o gh-switch.sh https://raw.githubusercontent.com/calghar/gh-account-switcher/main/src/gh-switch-windows.sh
chmod +x gh-switch.sh
mkdir -p ~/bin
mv gh-switch.sh ~/bin/gh-switch

# Add to PATH in ~/.bashrc
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

##### **Option 2: WSL**

Follow the Linux installation instructions within your WSL environment.

## Verification

After installation, verify everything works:

```bash
# Check version
gh-switch --version

# Check help
gh-switch help

# Test basic functionality
gh-switch list
```

## Post-Installation Setup

### 1. Configure Git (if not already done)

```bash
git config --global init.defaultBranch main
git config --global pull.rebase false
```

### 2. Set up credential helper

**macOS:**

```bash
git config --global credential.helper osxkeychain
```

**Linux:**

```bash
git config --global credential.helper libsecret
# or
git config --global credential.helper store
```

**Windows:**

```bash
git config --global credential.helper manager
```

### 3. Configure SSH (optional but recommended)

See [SSH Configuration Guide](ssh-setup.md) for detailed setup.

### 4. Set up GPG (optional)

See [GPG Setup Guide](gpg-setup.md) for commit signing setup.

## Troubleshooting

### Common Issues

**Command not found:**

- Ensure the script is in your PATH
- Check file permissions (`chmod +x`)
- Verify the shebang line points to bash

**jq not found:**

- Install jq using your package manager
- Verify installation with `jq --version`

**Permission denied:**

- Check script has execute permissions
- Ensure you have write access to config directory

**GPG issues:**

- Install GPG for your platform
- Configure pinentry program
- Import your GPG keys

### Getting Help

If you encounter issues:

1. Check the [Troubleshooting Guide](troubleshooting.md)
2. Review platform-specific notes in this guide
3. Open an issue on GitHub with:
   - Your operating system and version
   - Command output and error messages
   - Steps to reproduce the issue

## Uninstallation

To remove GitHub Account Switcher:

```bash
# Remove the script
rm ~/bin/gh-switch

# Remove configuration (optional)
rm -rf ~/.github-switcher

# Remove git global config changes (optional)
git config --global --unset user.email
git config --global --unset user.name
git config --global --unset user.signingkey
git config --global --unset commit.gpgsign

# Remove PATH addition from shell config (optional)
# Edit ~/.bashrc, ~/.zshrc, or ~/.bash_profile and remove:
# export PATH="$HOME/bin:$PATH"
```
