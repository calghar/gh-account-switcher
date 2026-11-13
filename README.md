# gh-switch

Manage several Git identities (work, personal, client) and switch them by directory.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Install

Download a pre-built binary from the [latest release](https://github.com/calghar/gh-account-switcher/releases/latest):

```bash
# macOS (Apple Silicon)
curl -L https://github.com/calghar/gh-account-switcher/releases/latest/download/gh-switch-darwin-arm64 -o gh-switch

# macOS (Intel)
curl -L https://github.com/calghar/gh-account-switcher/releases/latest/download/gh-switch-darwin-amd64 -o gh-switch

# Linux (amd64)
curl -L https://github.com/calghar/gh-account-switcher/releases/latest/download/gh-switch-linux-amd64 -o gh-switch

chmod +x gh-switch
sudo mv gh-switch /usr/local/bin/
```

Or install with Go 1.24.4 or later:

```bash
go install github.com/calghar/gh-account-switcher@latest
```

Or build from source:

```bash
git clone https://github.com/calghar/gh-account-switcher.git
cd gh-account-switcher
make install   # builds ./gh-switch and copies it to ~/bin
```

## Quick start

```bash
# 1. Add profiles
gh-switch add work john.doe@company.com "John Doe" ABC123DEF456
gh-switch add personal john@gmail.com "Johnny Smith"

# 2. Map directories to profiles
gh-switch auto ~/projects/work work
gh-switch auto ~/projects/personal personal

# 3. Check the result
gh-switch current
```

Git now loads the right identity for each repository. No further switching is needed.

## Commands

| Command | Purpose |
|---------|---------|
| `add <name> <email> [git-name] [gpg-key]` | Create a profile |
| `add-email <profile> <email>` | Add an email to a profile |
| `remove-email <profile> <email>` | Remove an email from a profile |
| `list-emails <profile>` | List a profile's emails |
| `auto <directory> <profile>` | Map a directory to a profile |
| `auto-list` | List directory mappings |
| `auto-remove <directory>` | Remove a directory mapping |
| `switch <profile> [email]` | Set the global Git identity |
| `list` | List profiles |
| `current` | Show the active Git identity |
| `remove <profile>` | Delete a profile |
| `export [file]` | Export profiles to JSON |
| `import <file>` | Import profiles from JSON |

Global flags: `-s, --auto-ssh` loads the SSH key into the agent or keychain. `-y, --yes` skips prompts.

## How it works

- `auto` writes `~/.gitconfig-<profile>` and adds an `includeIf "gitdir:<dir>/"` entry to `~/.gitconfig`.
- Git reads that entry for any repository under the directory.
- `switch` changes only the global identity. It does not change remote URLs.

## SSH setup for multiple accounts

Git identity and SSH authentication are separate. Each profile needs its own SSH key and host alias.

With `--auto-ssh`, the tool:

1. Adds a `Host github.com-<profile>` entry to `~/.ssh/config`, with its own `IdentityFile` and `IdentitiesOnly yes`.
2. Adds the profile's key to the SSH agent or keychain.

Clone or set remotes with the alias:

```bash
git clone git@github.com-work:company/repo.git
git remote set-url origin git@github.com-personal:user/repo.git
```

HTTPS remotes use the credential helper's login, not the profile. Use the SSH alias for each profile's repositories.

## Requirements

- Git 2.23 or later (for `includeIf`)
- SSH client
- GPG, optional, for commit signing

## Documentation

- [Command reference](docs/commands.md)
- [User guide](docs/user-guide.md)
- [Use cases](docs/use-cases.md)
- [Installation](docs/installation.md)
- [Security](docs/security.md)

## Development

```bash
make build    # build ./gh-switch
make test     # run tests with the race detector
make lint     # run golangci-lint
make fmt      # format
make help     # list targets
```

See [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

MIT. See [LICENSE](LICENSE).
