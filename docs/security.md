# Security

## SSH Key Isolation

### IdentitiesOnly Configuration

SSH config entries use `IdentitiesOnly yes` to prevent GitHub from trying all available keys:

```
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_work
    IdentitiesOnly yes
```

This ensures SSH only uses the specified key, avoiding authentication errors when multiple keys are loaded.

### Per-Profile Keys

Convention: `~/.ssh/id_{profile_name}`

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_work -C "work@company.com"
ssh-keygen -t ed25519 -f ~/.ssh/id_personal -C "personal@example.com"
```

### Platform Integration

- **macOS**: Keys added to Keychain with `ssh-add --apple-use-keychain`
- **Linux**: Standard SSH agent
- **Windows**: Windows SSH agent

## GPG Commit Signing

### Per-Profile Keys

```bash
gpg --full-generate-key
gpg --list-secret-keys --keyid-format LONG
gh-switch add work email@example.com "Name" YOUR_KEY_ID
```

### Automatic Configuration

Tool sets `user.signingkey` and `commit.gpgsign` per profile.

### Verification

```bash
git log --show-signature
```

## Configuration Storage

- **Location**: `~/.github-switcher/config.json`
- **Permissions**: `0600` (user read/write only)
- **Contents**: Profile metadata, directory rules (no secrets)

## Best Practices

1. Use Ed25519 SSH keys (stronger, smaller)
2. Protect private keys with passphrases
3. Rotate keys periodically
4. Use separate keys per profile
5. Enable GPG signing for verified commits
6. Export profiles for secure backup
