# User Guide

## Workflow

### 1. Add Profiles

```bash
gh-switch add work john@company.com "John Doe" ABC123GPG
gh-switch add personal john@personal.com "John Smith"
```

### 2. Setup Directory Rules (Recommended)

```bash
gh-switch auto ~/work work
gh-switch auto ~/personal personal
```

Git now automatically uses the correct profile based on repository location. No manual switching needed.

### 3. Alternative: Manual Switching

```bash
gh-switch switch work
gh-switch --auto-ssh switch personal  # Also loads SSH key
```

## Git includeIf Workflow

The tool creates profile-specific gitconfig files and uses Git's `includeIf` directive:

**~/.gitconfig:**
```ini
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work
```

**~/.gitconfig-work:**
```ini
[user]
    email = john@company.com
    name = John Doe
    signingkey = ABC123GPG
[commit]
    gpgsign = true
```

Navigate to `~/work/any-repo` and Git automatically uses work profile.

## SSH Multi-Account

SSH config entries use `IdentitiesOnly yes` to prevent key conflicts:

```bash
# Clone with profile-specific host
git clone git@github.com-work:company/repo.git

# Update existing repo
git remote set-url origin git@github.com-personal:user/repo.git
```

## Multi-Email Profiles

```bash
gh-switch add-email work john.contractor@company.com
gh-switch switch work john.contractor@company.com  # Use specific email
gh-switch list-emails work
```

## Import/Export

```bash
# Backup
gh-switch export > backup.json

# Restore on new machine
gh-switch import backup.json
```

## GPG Signing

Automatically configured per profile. Ensure GPG key exists:

```bash
gpg --list-secret-keys --keyid-format LONG
```

## Platform-Specific Notes

**macOS:** SSH keys added to keychain with `--apple-use-keychain`
**Linux:** Standard SSH agent
**Windows:** Windows SSH agent
