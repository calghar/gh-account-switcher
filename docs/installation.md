# Installation

## Requirements

- Git 2.23+ (for includeIf support)
- SSH (for key-based authentication)
- GPG (optional, for commit signing)

## Binary Installation

### macOS

```bash
# Apple Silicon
curl -L https://github.com/calghar/gh-account-switcher/releases/latest/download/gh-switch-darwin-arm64 -o gh-switch
chmod +x gh-switch
sudo mv gh-switch /usr/local/bin/

# Intel
curl -L https://github.com/calghar/gh-account-switcher/releases/latest/download/gh-switch-darwin-amd64 -o gh-switch
chmod +x gh-switch
sudo mv gh-switch /usr/local/bin/
```

### Linux

```bash
curl -L https://github.com/calghar/gh-account-switcher/releases/latest/download/gh-switch-linux-amd64 -o gh-switch
chmod +x gh-switch
sudo mv gh-switch /usr/local/bin/
```

### Windows

Download from [releases page](https://github.com/calghar/gh-account-switcher/releases).

## Build from Source

```bash
git clone https://github.com/calghar/gh-account-switcher.git
cd gh-account-switcher
make build
make install  # Installs to ~/bin
```

## Install with Go

```bash
go install github.com/calghar/gh-account-switcher@latest
```

## Verify Installation

```bash
gh-switch --version
gh-switch --help
```
