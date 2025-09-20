# GitHub Account Switcher

> Multi-account management for Git workflows with advanced features

[![Platform Support](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue)](https://github.com/calghar/gh-account-switcher#-requirements) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- **Multi-email support** - Multiple emails per profile for different contexts
- **Auto SSH key management** - Automatically add SSH keys when switching profiles
- **Directory-based auto-switching** - Automatically switch profiles by location
- **Profile import/export** - Share configurations across machines
- **GPG commit signing** - Automatic GPG key management per profile
- **Cross-platform** - Works on macOS, Linux, and Windows

## 🚀 Quick Start

### Installation

```bash
# One-liner for all platforms
curl -fsSL https://raw.githubusercontent.com/calghar/gh-account-switcher/main/install.sh | bash
```

### Basic Usage

```bash
# Add profiles
gh-switch add work john.doe@company.com "John Doe" ABC123DEF456
gh-switch add personal john@gmail.com "Johnny Smith"

# Switch profiles (with auto SSH key loading)
gh-switch --auto-ssh switch work
gh-switch switch personal

# List profiles
gh-switch list

# Update to latest version
gh-switch update
```

## 📋 Core Commands

| Command | Description |
|---------|-------------|
| `gh-switch add <name> <email> [git-name] [gpg-key]` | Add a new profile |
| `gh-switch switch <name> [email]` | Switch to a profile |
| `gh-switch --auto-ssh switch <name>` | Switch and auto-add SSH key |
| `gh-switch list` | List all profiles |
| `gh-switch current` | Show current profile |
| `gh-switch auto <dir> <profile>` | Set up auto-switching for directory |
| `gh-switch update` | Update to latest version |

### Key Features Demo

```bash
# Auto SSH key management (NEW!)
$ gh-switch --auto-ssh switch work
Switched to profile 'work' with email 'john@company.com' and name 'John Doe'

Adding SSH key to macOS keychain...
Successfully added SSH key for profile 'work' to keychain

Next steps:
• Update saved credentials in Keychain Access (search for 'github.com')
```

## 🛠️ Requirements

**Essential:**

- Git 2.22.0+
- Bash 4.0+
- jq (JSON processor)
- curl (for updates)

**Optional:**

- GPG (for commit signing)
- SSH (for key-based authentication)

## 📖 Documentation

- **[Complete Command Reference](docs/commands.md)** - All commands and examples
- **[Use Cases](docs/use-cases.md)** - Team setups, freelancing, organizations
- **[Security Features](docs/security.md)** - GPG signing, SSH keys, best practices
- **[Installation Guide](docs/installation.md)** - Platform-specific instructions
- **[Advanced Features](docs/advanced-features.md)** - Directory rules, automation
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## 🤝 Contributing

Please see the [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/calghar/gh-account-switcher/issues)
- **Discussions**: [GitHub Discussions](https://github.com/calghar/gh-account-switcher/discussions)
- **Documentation**: [Complete Docs](docs/)
