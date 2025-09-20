# Security Features

## GPG Commit Signing

### Automatic Key Management

gh-switch automatically manages GPG keys for commit signing:

- **Per-profile keys** - Each profile can have its own GPG key
- **Automatic configuration** - Sets `user.signingkey` and `commit.gpgsign`
- **Key validation** - Checks if keys exist in your keyring
- **Platform integration** - Configures pinentry for macOS

```bash
# Add profile with GPG signing
gh-switch add work john@company.com "John Doe" 1A2B3C4D5E6F7G8H

# GPG signing is automatically enabled for commits
git commit -m "Signed commit"  # Automatically signed with work key
```

### Key Verification

When adding profiles with GPG keys, gh-switch:

- Validates key format (8+ hexadecimal characters)
- Checks if the key exists in your GPG keyring
- Warns if key is not found but allows you to continue
- Configures GPG agent for better password prompts (macOS)

## SSH Key Isolation

### Per-Profile SSH Keys

gh-switch supports separate SSH keys for each profile:

- **Naming convention**: `~/.ssh/id_{profile_name}`
- **Automatic detection** - Checks for profile-specific keys
- **Keychain integration** - Automatically adds keys to SSH agent/keychain
- **Status checking** - Shows if keys are loaded

```bash
# Create profile-specific SSH keys
ssh-keygen -t ed25519 -f ~/.ssh/id_work -C "work@company.com"
ssh-keygen -t ed25519 -f ~/.ssh/id_personal -C "personal@email.com"

# Switch profiles and auto-add SSH keys
gh-switch --auto-ssh switch work     # Loads ~/.ssh/id_work
gh-switch --auto-ssh switch personal # Loads ~/.ssh/id_personal
```

### SSH Key Security

- **Keychain integration** on macOS for secure key storage
- **Automatic cleanup** - Can remove keys when switching (optional)
- **Key status monitoring** - Shows which keys are currently loaded
- **Passphrase prompts** - Integrates with system keychain/agent

## Secure Credential Storage

### Platform-Specific Integration

gh-switch leverages platform credential stores:

- **macOS**: Keychain Access integration
- **Linux**: libsecret support
- **Windows**: Windows Credential Manager

### GitHub Token Management

While gh-switch doesn't store GitHub tokens directly, it provides guidance for:

- Using GitHub CLI authentication
- Updating saved credentials when switching profiles
- Managing multiple GitHub accounts securely

## Profile Validation

### Input Validation

gh-switch validates all inputs to prevent configuration errors:

- **Email format** - Validates email addresses using regex
- **GPG key format** - Checks key format and warns about issues
- **Profile names** - Ensures valid profile naming
- **File permissions** - Sets appropriate permissions on config files

### Configuration Integrity

- **JSON validation** - Ensures profile files are valid JSON
- **Backup creation** - Creates backups before major changes
- **Recovery mechanisms** - Can restore from backup if corruption occurs

## Best Practices

### GPG Key Management

1. **Use strong keys** - Prefer RSA 4096-bit or Ed25519 keys
2. **Key rotation** - Regularly update GPG keys
3. **Backup keys** - Securely backup your private keys
4. **Passphrase protection** - Use strong passphrases for private keys

```bash
# Generate a new GPG key
gpg --full-generate-key

# List your keys to get the key ID
gpg --list-secret-keys --keyid-format LONG

# Add to profile
gh-switch add work john@company.com "John Doe" YOUR_KEY_ID
```

### SSH Key Management

```bash
# Generate secure SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_work -C "work@company.com"

# Add to SSH agent with keychain (macOS)
ssh-add --apple-use-keychain ~/.ssh/id_work

# Or use gh-switch auto-add feature
gh-switch --auto-ssh switch work
```

### Profile Security

1. **Regular backups** - Export profiles regularly
2. **Secure storage** - Store profile exports securely
3. **Access control** - Ensure only you can read profile files
4. **Regular audits** - Review active profiles periodically

```bash
# Backup profiles securely
gh-switch export > ~/secure-backup/profiles-$(date +%Y%m%d).json
chmod 600 ~/secure-backup/profiles-*.json

# Regular security check
gh-switch current  # Review active configuration
gh-switch list     # Review all profiles
```
