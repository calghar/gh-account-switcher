# GitHub Account Switcher

> Modern CLI tool for managing multiple Git identities with automatic switching

[![Platform Support](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue)](https://github.com/calghar/gh-account-switcher#-requirements) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?logo=go)](https://golang.org/)

## 🆕 Version 2.0 - Complete Rewrite in Go

Version 2.0 is a ground-up rewrite in Go, delivering:
- **80% less code** (~1000 LOC vs ~2500 LOC bash)
- **Single binary** distribution (4.3MB)
- **Git includeIf** for automatic directory-based switching
- **Type-safe** with comprehensive error handling
- **10x faster** execution
- **Professional-grade** maintainability

## ✨ Features

- **Git includeIf automation** - Set up once, switches automatically by directory
- **SSH config with IdentitiesOnly** - Proper multi-account SSH key isolation
- **Multi-email support** - Multiple emails per profile for different contexts
- **Auto SSH key management** - Platform-specific keychain integration
- **Profile import/export** - Share configurations across machines
- **GPG commit signing** - Automatic GPG key management per profile
- **Cross-platform** - Single binary for macOS, Linux, and Windows

## 🚀 Quick Start

### Installation

#### Option 1: Download Pre-built Binary (Recommended)

```bash
# macOS (Apple Silicon)
curl -L https://github.com/calghar/gh-account-switcher/releases/latest/download/gh-switch-darwin-arm64 -o gh-switch
chmod +x gh-switch
sudo mv gh-switch /usr/local/bin/

# macOS (Intel)
curl -L https://github.com/calghar/gh-account-switcher/releases/latest/download/gh-switch-darwin-amd64 -o gh-switch
chmod +x gh-switch
sudo mv gh-switch /usr/local/bin/

# Linux
curl -L https://github.com/calghar/gh-account-switcher/releases/latest/download/gh-switch-linux-amd64 -o gh-switch
chmod +x gh-switch
sudo mv gh-switch /usr/local/bin/

# Windows (PowerShell)
# Download from https://github.com/calghar/gh-account-switcher/releases
```

#### Option 2: Build from Source

```bash
git clone https://github.com/calghar/gh-account-switcher.git
cd gh-account-switcher
make build
make install  # Installs to ~/bin
```

#### Option 3: Install with Go

```bash
go install github.com/calghar/gh-account-switcher@latest
```

### Basic Usage

```bash
# Add profiles
gh-switch add work john.doe@company.com "John Doe" ABC123DEF456
gh-switch add personal john@gmail.com "Johnny Smith"

# Setup automatic directory-based switching (recommended!)
gh-switch auto ~/projects/work work
gh-switch auto ~/projects/personal personal
# Now Git automatically uses the right profile in each directory!

# Or switch manually (affects global git config)
gh-switch switch work
gh-switch --auto-ssh switch personal  # Also adds SSH key

# List profiles and directory rules
gh-switch list
gh-switch auto-list

# View current configuration
gh-switch current
```

## 📋 Core Commands

| Command | Description |
|---------|-------------|
| `gh-switch add <name> <email> [git-name] [gpg-key]` | Add a new profile |
| `gh-switch auto <dir> <profile>` | Setup automatic switching (uses Git includeIf) |
| `gh-switch switch <name> [email]` | Manually switch profile globally |
| `gh-switch --auto-ssh switch <name>` | Switch and auto-add SSH key to keychain |
| `gh-switch list` | List all profiles with details |
| `gh-switch current` | Show current Git configuration |
| `gh-switch auto-list` | List directory rules |
| `gh-switch remove <name>` | Remove a profile |
| `gh-switch export [file]` | Export profiles to JSON |
| `gh-switch import <file>` | Import profiles from JSON |

### 🎯 Git IncludeIf: The Better Way

Instead of manually switching profiles, set up automatic directory-based switching:

```bash
# One-time setup
gh-switch auto ~/work work-profile
gh-switch auto ~/personal personal-profile

# That's it! Git now automatically uses the right profile.
# No need to run gh-switch switch ever again in these directories.
```

**How it works:** Creates `.gitconfig-{profile}` files and adds `includeIf` directives to your global `.gitconfig`. Git automatically loads the correct configuration based on your repository location.

### Key Features Demo

```bash
# Auto SSH key management with SSH config
$ gh-switch --auto-ssh switch work
Switched to profile 'work' with email 'john@company.com' and name 'John Doe'

Added SSH config entry for profile 'work'
Use this host in git URLs: git@github.com-work:user/repo.git
Adding SSH key to macOS keychain...
Successfully added SSH key for profile 'work' to keychain
```

### How SSH Multi-Account Support Works

When using `--auto-ssh`, the tool automatically:

1. **Creates SSH config entries** in `~/.ssh/config` with unique host aliases
2. **Adds SSH keys to the agent** (without removing other keys)
3. **Uses `IdentitiesOnly yes`** to ensure GitHub uses the correct key per profile

**Example SSH config entries created:**
```ssh
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_work
    IdentitiesOnly yes

Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_personal
    IdentitiesOnly yes
```

**Using the host aliases in your git repos:**
```bash
# Clone using profile-specific host
git clone git@github.com-work:company/repo.git

# Update existing repo's remote
git remote set-url origin git@github.com-personal:user/repo.git
```

This approach allows multiple GitHub SSH keys to coexist peacefully, with SSH automatically selecting the correct key based on the host alias you use.

## 🛠️ Requirements

**Runtime Requirements:**

- Git 2.23.0+ (for includeIf support)
- SSH (for key-based authentication)
- GPG (optional, for commit signing)

**Build Requirements (if building from source):**

- Go 1.21+
- Make (optional, but recommended)

## 📖 Documentation

- **[Complete Command Reference](docs/commands.md)** - All commands and examples
- **[Use Cases](docs/use-cases.md)** - Team setups, freelancing, organizations
- **[Security Features](docs/security.md)** - GPG signing, SSH keys, best practices
- **[Installation Guide](docs/installation.md)** - Platform-specific instructions
- **[Advanced Features](docs/advanced-features.md)** - Directory rules, automation
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## 🏗️ Development

### Building

```bash
# Build for current platform
make build

# Build for all platforms
make build-all

# Run tests
make test

# Format code
make fmt

# Show all available commands
make help
```

### Project Structure

```
gh-switch/
├── cmd/              # CLI commands (Cobra)
├── internal/         # Internal packages
│   ├── config/      # Profile management
│   ├── git/         # Git configuration
│   ├── ssh/         # SSH config management
│   ├── platform/    # Platform-specific code
│   └── utils/       # Utilities
├── main.go          # Entry point
├── Makefile         # Build automation
└── .goreleaser.yml  # Release configuration
```

### Technology Stack

- **Language**: Go 1.21+
- **CLI Framework**: Cobra
- **Config Management**: Viper
- **Build Tool**: Make
- **Release Tool**: GoReleaser

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

```bash
git clone https://github.com/calghar/gh-account-switcher.git
cd gh-account-switcher
make deps
make build
./gh-switch --help
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/calghar/gh-account-switcher/issues)
- **Discussions**: [GitHub Discussions](https://github.com/calghar/gh-account-switcher/discussions)
- **Documentation**: [Complete Docs](docs/)
