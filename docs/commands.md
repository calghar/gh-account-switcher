# Command Reference

## Profile Management

```bash
gh-switch add <name> <email> [git-name] [gpg-key]
gh-switch list
gh-switch current
gh-switch remove <name>
```

## Directory-Based Switching (Git includeIf)

```bash
# Primary workflow - set up once, automatic thereafter
gh-switch auto <directory> <profile>
gh-switch auto-list
gh-switch auto-remove <directory>
```

Creates `.gitconfig-{profile}` files and adds `includeIf` directives. Git automatically loads the correct config based on repository location.

## Manual Switching

```bash
gh-switch switch <profile> [email]
gh-switch --auto-ssh switch <profile>  # Also adds SSH key to keychain
```

Modifies global git config. Use `auto` for directory-based switching instead.

## Email Management

```bash
gh-switch add-email <profile> <email>
gh-switch remove-email <profile> <email>
gh-switch list-emails <profile>
```

## Import/Export

```bash
gh-switch export [file]     # Prints to stdout if no file
gh-switch import <file>
```

## Global Flags

- `--auto-ssh, -s`: Add SSH key to platform keychain
- `--yes, -y`: Skip confirmations
- `--help, -h`: Command help
- `--version, -v`: Show version

## SSH Configuration

Automatically creates entries in `~/.ssh/config`:

```
Host github.com-{profile}
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_{profile}
    IdentitiesOnly yes
```

Use in git URLs: `git@github.com-work:user/repo.git`
