# GitHub Account Switcher

> multi-account management for Git workflows with advanced features

[![Platform Support](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue)](https://github.com/calghar/gh-account-switcher#-requirements) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- **Multi-email support** - Multiple emails per profile for different contexts
- **Directory-based auto-switching** - Automatically switch profiles by location
- **Git name management** - Different names for different profiles
- **Profile import/export** - Share configurations across machines
- **Automation flags** - `--yes` flag for scripting
- **Enhanced platform support** - Better Windows, Linux, and macOS integration

## 🚀 Quick Start

### Installation

#### **Quick Install (Recommended)**

```bash
# One-liner for all platforms
curl -fsSL https://raw.githubusercontent.com/calghar/gh-account-switcher/main/install.sh | bash
```

#### **Manual Install**

```bash
# macOS
curl -o gh-switch https://raw.githubusercontent.com/calghar/gh-account-switcher/main/src/gh-switch-macos.sh
chmod +x gh-switch && mkdir -p ~/bin && mv gh-switch ~/bin/

# Linux  
curl -o gh-switch https://raw.githubusercontent.com/calghar/gh-account-switcher/main/src/gh-switch-linux.sh
chmod +x gh-switch && mkdir -p ~/bin && mv gh-switch ~/bin/

# Windows (Git Bash)
curl -o gh-switch.sh https://raw.githubusercontent.com/calghar/gh-account-switcher/main/src/gh-switch-windows.sh
chmod +x gh-switch.sh && mkdir -p ~/bin && mv gh-switch.sh ~/bin/gh-switch
```

> **Note**: The installer automatically adds `~/bin` to your PATH and handles updates properly.

### Basic Usage

```bash
# Add profiles
gh-switch add work john.doe@company.com "John Doe" ABC123DEF456
gh-switch add personal john@gmail.com "Johnny Smith"

# Switch profiles
gh-switch switch work
gh-switch switch personal

# List profiles
gh-switch list
```

## 🎯 Key Features

### Improved User Experience

Switch profiles get clean, actionable next steps instead of verbose explanations:

```bash
$ gh-switch switch personal
Switched to profile 'personal' with email 'john@gmail.com' and name 'Johnny Smith'

Next steps:
• Add SSH key to keychain: ssh-add --apple-use-keychain ~/.ssh/id_personal
• Update saved credentials in Keychain Access (search for 'github.com')
• View SSH config help: gh-switch help
```

### Multi-Email Support

```bash
# Add additional emails to a profile
gh-switch add-email work john.contractor@company.com
gh-switch add-email work j.doe@consulting.com

# Switch to specific email
gh-switch switch work john.contractor@company.com

# List all emails for a profile
gh-switch list-emails work
```

### Directory-Based Auto-Switching

```bash
# Set up automatic switching
gh-switch auto ~/projects/work work
gh-switch auto ~/projects/personal personal

# Now switching happens automatically
cd ~/projects/work && gh-switch     # Switches to 'work' profile
cd ~/projects/personal && gh-switch # Switches to 'personal' profile
```

### Profile Management

```bash
# Export profiles for backup/sharing
gh-switch export > my-profiles.json

# Import profiles on another machine
gh-switch import my-profiles.json

# Set git names per profile (updates immediately if profile is active)
gh-switch set-name work "John Doe (Work)"
gh-switch set-name personal "Johnny Smith"
```

## 📖 Documentation

- **[Installation Guide](docs/installation.md)** - Platform-specific installation instructions
- **[User Guide](docs/user-guide.md)** - Complete feature documentation
- **[Advanced Features](docs/advanced-features.md)** - Power user features and automation
- **[SSH Setup](docs/examples/ssh-config-example)** - Multi-account SSH configuration
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## Command Reference

### Core Commands

```bash
gh-switch add <name> <email> [git-name] [gpg-key]  # Add profile
gh-switch switch <name> [email]                    # Switch profile  
gh-switch list                                     # List profiles
gh-switch current                                  # Show current profile
gh-switch remove <name>                            # Remove profile
```

### Email Management

```bash
gh-switch add-email <profile> <email>         # Add email to profile
gh-switch remove-email <profile> <email>      # Remove email from profile
gh-switch list-emails <profile>               # List profile emails
```

### Advanced Features

```bash
gh-switch set-name <profile> <name>           # Set git name
gh-switch auto <directory> <profile>          # Add auto-switch rule
gh-switch auto-list                           # List auto-switch rules
gh-switch export [file]                       # Export profiles
gh-switch import <file>                       # Import profiles
```

### Global Options

```bash
--yes, -y          # Skip confirmation prompts (for automation)
--help, -h         # Show help message
--version, -v      # Show version information
```

## 🛠️ Requirements

### Essential

- **Git** 2.22.0+
- **Bash** 4.0+
- **jq** (JSON processor)

### Optional  

- **GPG** (for commit signing)
- **SSH** (for key-based authentication)

### Platform-Specific

- **macOS**: Homebrew recommended (`brew install git jq gnupg`)
- **Linux**: Package manager (`apt install git jq gnupg` or equivalent)  
- **Windows**: Git for Windows + package manager (Chocolatey/Scoop/Winget)

## Use Cases

### Development Teams

- **Consistent setup** across team members
- **Client separation** with different profiles per client
- **Compliance** with different signing requirements

### Individual Developers  

- **Work/personal separation** with automatic switching
- **Multiple email contexts** (employee, contractor, consultant)
- **Different SSH keys** per account

### Organizations

- **Standardized configurations** via profile templates
- **Audit trails** with profile usage logging
- **Security compliance** with mandatory GPG signing

## Security Features

- **GPG commit signing** with automatic key management
- **SSH key isolation** per profile
- **Secure credential storage** (Keychain, libsecret, Windows Credential Manager)
- **Profile validation** to prevent configuration errors

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
git clone https://github.com/calghar/gh-account-switcher
cd gh-account-switcher
./tests/run-tests.sh
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check our [comprehensive docs](docs/)
- **Issues**: [GitHub Issues](https://github.com/calghar/gh-account-switcher/issues)
- **Discussions**: [GitHub Discussions](https://github.com/calghar/gh-account-switcher/discussions)
