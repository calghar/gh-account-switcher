# 🔄 GitHub Account Switcher

> Platform-specific tools for managing and quickly switching between multiple GitHub accounts

## 📋 Table of Contents

- [🔄 GitHub Account Switcher](#-github-account-switcher)
  - [📋 Table of Contents](#-table-of-contents)
  - [🚀 Overview](#-overview)
  - [✨ Features](#-features)
  - [🛠️ Prerequisites](#️-prerequisites)
    - [Essential Requirements for All Platforms](#essential-requirements-for-all-platforms)
    - [Platform-Specific Requirements](#platform-specific-requirements)
    - [System-Specific Requirements](#system-specific-requirements)
  - [📥 Installation](#-installation)
    - [Linux Installation](#linux-installation)
    - [macOS Installation](#macos-installation)
    - [Windows Installation](#windows-installation)
      - [Option 1: Using Git Bash](#option-1-using-git-bash)
      - [Option 2: Using PowerShell](#option-2-using-powershell)
  - [🧰 Usage Guide](#-usage-guide)
    - [Basic Commands](#basic-commands)
    - [Getting Started](#getting-started)
    - [Example Workflow](#example-workflow)
  - [🔑 Authentication with Multiple GitHub Accounts](#-authentication-with-multiple-github-accounts)
    - [Complete Setup Process](#complete-setup-process)
    - [Day-to-Day Usage](#day-to-day-usage)
    - [How It Works](#how-it-works)
    - [Common Issues](#common-issues)
  - [⚙️ Configuration](#️-configuration)
  - [💻 Platform-Specific Notes](#-platform-specific-notes)
    - [Linux](#linux)
    - [macOS](#macos)
    - [Windows](#windows)
  - [🔑 SSH Configuration](#-ssh-configuration)
    - [Setting Up Multiple SSH Keys](#setting-up-multiple-ssh-keys)
    - [Platform-Specific SSH Tips](#platform-specific-ssh-tips)
  - [🔐 GPG Keys and Signing](#-gpg-keys-and-signing)
    - [What Are GPG Keys Used For?](#what-are-gpg-keys-used-for)
    - [Setting Up GPG Keys](#setting-up-gpg-keys)
  - [🔍 Troubleshooting](#-troubleshooting)
  - [🎓 Advanced Usage](#-advanced-usage)
    - [Working with Multiple SSH Keys](#working-with-multiple-ssh-keys)
    - [Setting Different Git Configurations Per Directory](#setting-different-git-configurations-per-directory)
    - [Using with GitHub CLI](#using-with-github-cli)
    - [Script Customization](#script-customization)

## 🚀 Overview

GitHub Account Switcher is a set of platform-specific tools that allow developers to seamlessly switch between multiple GitHub accounts. It manages Git configurations, SSH keys, and credentials to ensure you're always using the correct identity for each project.

## ✨ Features

- 🧩 Switch between different GitHub accounts with a single command
- 🔑 Manage multiple email addresses, GPG keys, and SSH configurations
- 🖥️ Platform-specific scripts for Linux, macOS, and Windows
- 🛡️ Securely handles credential switching
- 📝 Remembers your last used profile
- 🔧 Easy to configure and customize

## 🛠️ Prerequisites

Each platform has its own specific requirements:

### Essential Requirements for All Platforms

1. **Git**:
   - Required version: 2.22.0 or newer
   - Verify with: `git --version`

2. **Bash**:
   - Required on all platforms
   - Included by default on macOS/Linux
   - Windows: Included with Git for Windows or available in WSL
   - Verify with: `bash --version`

3. **jq** (JSON processor):
   - Required for profile management
   - Verify with: `jq --version`

### Platform-Specific Requirements

| Platform | Required Packages | Installation Commands |
|----------|------------------|------------------------|
| Linux | • Git<br>• jq<br>• Optional: gpg, libsecret | **Debian/Ubuntu:**<br>`sudo apt install git jq gnupg2 libsecret-1-0`<br><br>**Fedora/RHEL:**<br>`sudo dnf install git jq gnupg2 libsecret`<br><br>**Arch Linux:**<br>`sudo pacman -S git jq gnupg libsecret` |
| macOS | • Git<br>• jq<br>• Optional: gnupg, pinentry-mac | **Via Homebrew:**<br>`brew install git jq gnupg pinentry-mac` |
| Windows | • Git for Windows<br>• jq<br>• Optional: Gpg4win | **Via chocolatey:**<br>`choco install git jq gpg4win`<br><br>**Via scoop:**<br>`scoop install git jq gpg4win`<br><br>**Via winget:**<br>`winget install Git.Git jqlang.jq GnuPG.Gpg4win` |

### System-Specific Requirements

- **Windows**: Git Bash or Windows Subsystem for Linux (WSL)
- **macOS**: Command Line Tools for Xcode (`xcode-select --install`)
- **Linux**: No additional requirements

## 📥 Installation

Choose the installation instructions for your operating system:

### Linux Installation

1. **Download the script**:

```bash
curl -o gh-switch.sh https://raw.githubusercontent.com/your-org/github-account-switcher/main/gh-switch-linux.sh
```

2. **Make executable**:

```bash
chmod +x gh-switch.sh
```

3. **Move to your PATH**:

```bash
sudo mv gh-switch.sh /usr/local/bin/gh-switch
```

4. **Verify installation**:

```bash
gh-switch help
```

### macOS Installation

1. **Download the script**:

```bash
curl -o gh-switch.sh https://raw.githubusercontent.com/your-org/github-account-switcher/main/gh-switch-macos.sh
```

2. **Make executable**:

```bash
chmod +x gh-switch.sh
```

3. **Move to your PATH**:

```bash
sudo mv gh-switch.sh /usr/local/bin/gh-switch
```

4. **Verify installation**:

```bash
gh-switch help
```

### Windows Installation

#### Option 1: Using Git Bash

1. **Download the script**:
   - Open Git Bash
   - Run:

   ```bash
   curl -o gh-switch.sh https://raw.githubusercontent.com/your-org/github-account-switcher/main/gh-switch-windows.sh
   ```

2. **Make executable and move to a directory in your PATH**:

   ```bash
   chmod +x gh-switch.sh
   mkdir -p ~/bin
   mv gh-switch.sh ~/bin/gh-switch
   ```

3. **Add to PATH** (if needed):
   - Edit your `~/.bashrc` file and add:

   ```bash
   export PATH="$HOME/bin:$PATH"
   ```

   - Then refresh your session:

   ```bash
   source ~/.bashrc
   ```

#### Option 2: Using PowerShell

1. **Download the script**:

   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/your-org/github-account-switcher/main/gh-switch-windows.sh" -OutFile "$env:USERPROFILE\gh-switch.sh"
   ```

2. **Create a PowerShell wrapper**:
   - Create a file named `gh-switch.ps1` with this content:

   ```powershell
   # PowerShell wrapper for gh-switch.sh
   $scriptPath = "$env:USERPROFILE\gh-switch.sh"
   & 'C:\Program Files\Git\bin\bash.exe' -c "exec '$scriptPath' $args"
   ```

3. **Save the PowerShell wrapper to a location in your PATH**:
   - Common location is `$env:USERPROFILE\Documents\WindowsPowerShell\Scripts`
   - Make sure this folder is in your PATH
   - Verify with: `$env:PATH -split ';'`

4. **Create a batch file for cmd.exe** (optional):
   - Create a file named `gh-switch.bat` with this content:

   ```batch
   @echo off
   "C:\Program Files\Git\bin\bash.exe" "%USERPROFILE%\gh-switch.sh" %*
   ```

   - Save to a location in your PATH, such as `%USERPROFILE%\bin`

## 🧰 Usage Guide

### Basic Commands

| Command | Description | Example |
|---------|-------------|---------|
| `gh-switch list` | List all profiles | `gh-switch list` |
| `gh-switch current` | Show current profile | `gh-switch current` |
| `gh-switch add <n> <email> [gpg]` | Add a new profile | `gh-switch add org john.doe@org.com` |
| `gh-switch switch <n>` | Switch to a profile | `gh-switch switch personal` |
| `gh-switch remove <n>` | Remove a profile | `gh-switch remove old-account` |
| `gh-switch help` | Show help message | `gh-switch help` |

### Getting Started

1. **Add your org profile**:

```bash
gh-switch add org john.doe@org.com ABC123DEF456
```

2. **Add your personal profile**:

```bash
gh-switch add personal john.personal@gmail.com
```

3. **Switch between profiles**:

```bash
gh-switch switch org    # Switch to org profile
gh-switch switch personal  # Switch to personal profile
```

4. **Check current profile**:

```bash
gh-switch current
```

### Example Workflow

```bash
# Start of the day, switch to org profile for company projects
gh-switch switch org

# Work on org repositories
cd ~/projects/org-repo
git commit -m "Fix production issue"
git push

# Switch to personal profile for open-source contributions
gh-switch switch personal

# Work on personal projects
cd ~/projects/personal-repo
git commit -m "Add new feature"
git push
```

## 🔑 Authentication with Multiple GitHub Accounts

Using the GitHub Account Switcher with multiple GitHub accounts requires both identity management (for commits) and authentication configuration (for repository access). Here's how to set it up:

### Complete Setup Process

1. **Generate SSH keys for each account**:

   ```bash
   # For org account
   ssh-keygen -t ed25519 -C "your.org.email@org.com" -f ~/.ssh/id_org
   
   # For personal account
   ssh-keygen -t ed25519 -C "your.personal.email@example.com" -f ~/.ssh/id_personal
   ```

2. **Add public keys to GitHub accounts**:

   ```bash
   # Copy org public key
   cat ~/.ssh/id_org.pub | pbcopy  # On macOS
   ```

   - Add this key to your org GitHub account (Settings > SSH and GPG keys)

   ```bash
   # Copy personal public key
   cat ~/.ssh/id_personal.pub | pbcopy  # On macOS
   ```

   - Add this key to your personal GitHub account (Settings > SSH and GPG keys)

3. **Configure SSH** (create or edit `~/.ssh/config`):

   ```
   # org GitHub account
   Host github-org
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_org
     IdentitiesOnly yes
     
   # Personal GitHub account
   Host github-personal
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_personal
     IdentitiesOnly yes
   ```

   Add platform-specific options:
   - macOS: Add `UseKeychain yes` and `AddKeysToAgent yes`
   - Windows: No additional options needed
   - Linux: Add `AddKeysToAgent yes` if using ssh-agent

4. **Add SSH keys to your agent**:

   ```bash
   # macOS
   ssh-add --apple-use-keychain ~/.ssh/id_org
   ssh-add --apple-use-keychain ~/.ssh/id_personal
   
   # Linux/Windows
   ssh-add ~/.ssh/id_org
   ssh-add ~/.ssh/id_personal
   ```

5. **Test SSH connections**:

   ```bash
   ssh -T git@github-org
   ssh -T git@github-personal
   ```

   Both should show successful authentication messages.

6. **Configure GitHub Account Switcher**:

   ```bash
   # Set up org profile
   gh-switch add org your.org.email@org.com
   
   # Set up personal profile
   gh-switch add personal your.personal.email@example.com
   ```

### Day-to-Day Usage

1. **Switch to org account**:

   ```bash
   gh-switch switch org
   ```

2. **Clone a org repository**:

   ```bash
   # Note the github-org host alias
   git clone git@github-org:org-organization/project.git
   ```

3. **For existing repositories, update remote URL**:

   ```bash
   # For org repositories
   git remote set-url origin git@github-org:org-organization/repo-name.git
   
   # For personal repositories
   git remote set-url origin git@github-personal:your-username/repo-name.git
   ```

4. **Verify current profile before committing**:

   ```bash
   gh-switch current
   ```

### How It Works

The GitHub Account Switcher manages your **commit identity** by configuring Git's user settings. SSH configuration handles your **repository access authentication**:

- `gh-switch` → Controls who commits appear from
- SSH config → Controls which key authenticates to GitHub

This two-part system allows you to maintain separate identities while authenticating to multiple GitHub accounts from a single machine.

### Common Issues

- **Push rejected**: Check if remote URL uses correct host alias (`github-org` or `github-personal`)
- **Wrong commit email**: Verify active profile with `gh-switch current`
- **Authentication prompts**: Add keys to SSH agent (`ssh-add`)
- **"Permission denied"**: Ensure public key is added to the correct GitHub account

For detailed troubleshooting, see the [Complete Guide to Multiple GitHub Account Authentication](docs/multiple-github-accounts.md).

## ⚙️ Configuration

The configuration is stored in `~/.github-switcher/` directory:

- `profiles.json`: Contains all your profiles with emails and GPG keys
- `current_profile`: Stores the name of the currently active profile

Example `profiles.json`:

```json
{
  "org": {
    "email": "john.doe@org.com",
    "gpg_key": "ABC123DEF456"
  },
  "personal": {
    "email": "john.personal@gmail.com",
    "gpg_key": null
  },
  "opensource": {
    "email": "john.dev@xyz.org",
    "gpg_key": "789GHI012JKL"
  }
}
```

## 💻 Platform-Specific Notes

### Linux

🐧 The Linux script includes specific features:

- Integration with libsecret for secure credential storage
- Support for different Linux distributions (Debian/Ubuntu, Fedora/RHEL, Arch)
- Manages GPG agent configuration

**Tips for Linux users**:

- For GNOME-based desktops, `libsecret` provides secure credential storage
- For KDE, consider configuring with KWallet
- Use `seahorse` (GUI) or `secret-tool` (CLI) to manage stored credentials

### macOS

🍎 The macOS script includes macOS-specific features:

- Integration with Keychain for secure credential storage
- Support for pinentry-mac for better GPG passphrase prompts
- SSH keys can be stored in Keychain with `--apple-use-keychain` flag

**Tips for macOS users**:

- Use Keychain Access to manage GitHub credentials
- Install packages via Homebrew for better integration
- Configure pinentry-mac for seamless GPG experience

### Windows

🪟 The Windows script includes Windows-specific features:

- Support for Git Bash, Cygwin, MSYS, and WSL environments
- Integration with Windows Credential Manager
- Special GPG configuration for Windows paths
- PowerShell profile suggestions for SSH agent

**Tips for Windows users**:

- Run in Git Bash for best experience
- If using WSL, be aware that configurations are separate between Windows and WSL
- Use Windows Credential Manager for managing stored credentials
- Configure proper paths for GPG in Windows

## 🔑 SSH Configuration

SSH keys allow you to connect to GitHub without using your username and password. The GitHub Account Switcher helps you manage multiple SSH keys for different accounts.

### Setting Up Multiple SSH Keys

1. **Generate a key for each profile**:

```bash
# For org profile
ssh-keygen -t ed25519 -C "org@example.com" -f ~/.ssh/id_org

# For personal profile
ssh-keygen -t ed25519 -C "personal@example.com" -f ~/.ssh/id_personal
```

2. **Create SSH config file** (`~/.ssh/config`):

```
# org GitHub account
Host github.com-org
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_org
  IdentitiesOnly yes

# Personal GitHub account
Host github.com-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_personal
  IdentitiesOnly yes
```

3. **Use custom host in repository URLs**:

```bash
# For org repositories
git remote set-url origin git@github.com-org:organization/repo.git

# For personal repositories
git remote set-url origin git@github.com-personal:username/repo.git
```

### Platform-Specific SSH Tips

| Platform | SSH Configuration Tips |
|----------|------------------------|
| Linux | • Add keys to agent: `ssh-add ~/.ssh/id_org` <br> • Start agent automatically in `~/.bashrc`:<br>```if [ -z "$SSH_AUTH_SOCK" ]; then``` <br>  ```eval "$(ssh-agent -s)" > /dev/null<br>  ssh-add ~/.ssh/id_org > /dev/null 2>&1<br>fi<br>``` |
| macOS | • Add keys to keychain: `ssh-add --apple-use-keychain ~/.ssh/id_org`<br>• Add to `~/.ssh/config`: <br> ```Host github.com-org``` <br>  ```UseKeychain yes``` <br>  ```AddKeysToAgent yes```<br> |
| Windows | • Start SSH agent in PowerShell profile:<br>```powershell``` <br> ```$sshAgentRunning = Get-Process -Name "ssh-agent" -ErrorAction SilentlyContinue``` <br> ```if (-not $sshAgentRunning) {``` <br>  ```Start-Service ssh-agent```<br>  ```ssh-add $env:USERPROFILE\.ssh\id_org```<br>```}```<br>• Path in Git Bash: `~/.ssh/id_org`<br>• Path in Windows: `%USERPROFILE%\.ssh\id_org` |

## 🔐 GPG Keys and Signing

GPG keys allow you to sign your commits, which adds a "Verified" badge to your commits on GitHub. The GitHub Account Switcher helps you use different GPG keys with different accounts.

### What Are GPG Keys Used For?

- **Signing commits**: Proves that commits actually came from you
- **Signing tags**: Ensures tags haven't been tampered with
- **Authentication**: Can be used for authentication with certain services

### Setting Up GPG Keys

1. **Install GPG**:
   - **Linux**: `sudo apt install gnupg2` or equivalent
   - **macOS**: `brew install gnupg`
   - **Windows**: Install Gpg4win from <https://gpg4win.org/>

2. **Generate a GPG key**:

   ```bash
   gpg --full-generate-key
   ```

   - Choose RSA and RSA
   - 4096 bits
   - Set an expiration date (recommended)
   - Enter your name and email (use the email for your GitHub account)

3. **List your keys to get the key ID**:

   ```bash
   gpg --list-secret-keys --keyid-format=long
   ```

   - Look for the ID after `sec`, e.g., `4096R/3AA5C34371567BD2`
   - Your key ID is the part after the `/` (`3AA5C34371567BD2`)

4. **Export your public key to add to GitHub**:

   ```bash
   gpg --armor --export YOUR_KEY_ID
   ```

   - Copy the output
   - Add to GitHub (Settings > SSH and GPG keys > New GPG key)

5. **Add to your GitHub Account Switcher profile**:

   ```bash
   gh-switch add profile-name your.email@example.com YOUR_KEY_ID
   ```

## 🔍 Troubleshooting

| Issue | Platform | Solution |
|-------|----------|----------|
| `jq: command not found` | All | Install jq using your package manager |
| `Permission denied` | All | Ensure the script is executable (`chmod +x`) |
| GPG signing fails | All | Check that the GPG key is correctly imported |
| SSH authentication fails | All | Verify SSH key is added to the agent |
| Git config changes not applying | All | Check your global git config with `git config --global --list` |
| WSL and Windows Git out of sync | Windows | Run the script in both environments |
| Keychain prompting repeatedly | macOS | Use `ssh-add --apple-use-keychain` instead of just `ssh-add` |
| GPG passphrase dialog not appearing | macOS | Install and configure pinentry-mac |
| GPG not found in Windows | Windows | Set correct path with `git config --global gpg.program "C:\Program Files (x86)\GnuPG\bin\gpg.exe"` |
| Credential helper issues | All | Check your credential helper configuration with `git config --global credential.helper` |

## 🎓 Advanced Usage

### Working with Multiple SSH Keys

Create a `.ssh/config` file to manage different SSH keys:

```txt
# ~/.ssh/config
Host github-org
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_org

Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_personal
```

Then use different remote URLs for different repositories:

```bash
# For org repositories
git remote set-url origin git@github-org:organization/repo.git

# For personal repositories
git remote set-url origin git@github-personal:username/repo.git
```

### Setting Different Git Configurations Per Directory

Use Git's conditional includes for different directories:

1. Add to your global `.gitconfig`:

```
[includeIf "gitdir:~/org/"]
  path = ~/.gitconfig-org

[includeIf "gitdir:~/personal/"]
  path = ~/.gitconfig-personal
```

2. Create specific configs:

```
# ~/.gitconfig-org
[user]
  email = john.doe@org.com
  name = John Doe
  signingkey = ABC123DEF456

# ~/.gitconfig-personal
[user]
  email = john.personal@gmail.com
  name = John Doe
  signingkey = 789GHI012JKL
```

### Using with GitHub CLI

If you use GitHub CLI (`gh`), you'll need to log in again after switching profiles:

```bash
gh auth login
```

### Script Customization

You can edit the script to add additional functionality:

- Modify the `switch_profile` function to handle additional configuration files
- Add organization-specific settings
- Integrate with additional tools in your workflow
