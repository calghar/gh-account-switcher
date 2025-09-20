<!-- markdownlint-disable MD024 -->
# User Guide

This comprehensive guide covers all features of GitHub Account Switcher v2.0.

## Quick Start

### 1. Add Your First Profile

```bash
# Basic profile with email only
gh-switch add work john.doe@company.com

# Complete profile with name and GPG key
gh-switch add work john.doe@company.com "John Doe" ABC123DEF456

# Personal profile
gh-switch add personal john@personal.com "John Smith"
```

### 2. Switch Between Profiles

```bash
# Switch to work profile
gh-switch switch work

# List all profiles
gh-switch list

# Check current profile
gh-switch current
```

## Core Features

### Profile Management

#### Adding Profiles

```bash
# Syntax: gh-switch add <name> <email> [git-name] [gpg-key]
gh-switch add work john.doe@company.com "John Doe" ABC123DEF

# Interactive confirmation to switch immediately
# Use --yes to skip confirmations
gh-switch --yes add personal john@gmail.com "John Smith"
```

#### Listing Profiles

```bash
# Show all profiles with details
gh-switch list

# Output example:
# Available GitHub profiles:
# * work (john.doe@company.com) [John Doe] [GPG: ABC123DEF]
#   personal (john@gmail.com) [John Smith] [+1 emails]
```

#### Switching Profiles

```bash
# Switch to primary email
gh-switch switch work
# Output:
# Switched to profile 'work' with email 'john.doe@company.com' and name 'John Doe'
# 
# Next steps:
# • Add SSH key to keychain: ssh-add --apple-use-keychain ~/.ssh/id_work
# • Update saved credentials in Keychain Access (search for 'github.com')
# • View SSH config help: gh-switch help

# Switch to specific email (if profile has multiple)
gh-switch switch work john.contractor@company.com

# Silent switch (no output except errors)
gh-switch --yes switch personal
```

#### Improved Output Messages

The switch command now provides clean, actionable next steps instead of verbose explanations:

- **Concise**: Bullet-point format with only relevant suggestions
- **Contextual**: Shows SSH key commands only if the key file exists
- **Platform-aware**: Different suggestions for macOS, Linux, and Windows
- **Actionable**: Copy-pasteable commands with proper highlighting

#### Removing Profiles

```bash
# Remove with confirmation
gh-switch remove old-profile

# Skip confirmation
gh-switch --yes remove old-profile
```

### Multi-Email Support

Each profile can have multiple email addresses for different contexts.

#### Adding Additional Emails

```bash
# Add contractor email to work profile
gh-switch add-email work john.contractor@company.com

# Add consulting email
gh-switch add-email work j.doe@consulting.com
```

#### Managing Emails

```bash
# List all emails for a profile
gh-switch list-emails work

# Remove non-primary email
gh-switch remove-email work j.doe@consulting.com

# Note: Cannot remove primary email
```

#### Using Multiple Emails

```bash
# Switch to primary email
gh-switch switch work

# Switch to specific email
gh-switch switch work john.contractor@company.com

# The primary email is used by default
```

### Git Name Management

#### Setting Git Names

```bash
# Set git name for a profile
gh-switch set-name work "John Doe (Work)"

# Different name for personal
gh-switch set-name personal "Jane Doe"
```

#### How It Works

- Each profile can have a different `git config --global user.name`
- Name is set automatically when switching profiles
- **New**: If the profile is currently active, git config is updated immediately
- Useful for maintaining different identities

### Directory-Based Auto-Switching

Automatically switch profiles based on your current directory.

#### Setting Up Auto-Switching

```bash
# Set work profile for work directory
gh-switch auto ~/projects/work work

# Set personal profile for personal projects
gh-switch auto ~/projects/personal personal

# Use absolute paths for best results
gh-switch auto /home/user/company-projects work
```

#### Managing Auto-Switch Rules

```bash
# List all directory rules
gh-switch auto-list

# Remove a rule
gh-switch auto-remove ~/projects/work
```

#### How It Works

- When you run `gh-switch` without arguments in a git repo, it checks for directory rules
- Longest matching path wins
- Rules are checked against current working directory
- Switching is silent (no output unless there's an error)

#### Example Workflow

```bash
# Set up rules
gh-switch auto ~/work work
gh-switch auto ~/personal personal

# Navigate to work directory
cd ~/work/project1
gh-switch  # Automatically switches to 'work' profile

# Navigate to personal directory
cd ~/personal/my-project
gh-switch  # Automatically switches to 'personal' profile
```

### Profile Import/Export

#### Exporting Profiles

```bash
# Export to stdout (for viewing)
gh-switch export

# Export to file
gh-switch export my-profiles.json

# Export for backup
gh-switch export ~/backups/github-profiles-$(date +%Y%m%d).json
```

#### Importing Profiles

```bash
# Import from file (merges with existing)
gh-switch import my-profiles.json

# Skip confirmation prompts
gh-switch --yes import my-profiles.json
```

#### Use Cases

- **Backup**: Regular exports for configuration backup
- **Team Sharing**: Share common profile templates
- **Migration**: Move profiles between machines
- **Bulk Setup**: Import pre-configured profiles

## Advanced Usage

### Working with GPG Signing

#### Setting Up GPG Keys

```bash
# Add profile with GPG key
gh-switch add work john@company.com "John Doe" ABC123DEF456

# The script will:
# - Configure git signing key
# - Enable commit signing
# - Set up platform-specific GPG agent
```

#### GPG Key Management

- Keys must be imported into your GPG keyring first
- Use `gpg --list-keys` to find key IDs
- Platform-specific pinentry programs are configured automatically

### SSH Configuration

#### Multiple SSH Keys

Set up different SSH keys for different accounts:

```bash
# Generate keys
ssh-keygen -t ed25519 -C "work@company.com" -f ~/.ssh/id_work
ssh-keygen -t ed25519 -C "personal@gmail.com" -f ~/.ssh/id_personal

# Configure SSH (see docs/examples/ssh-config-example)
```

#### SSH Agent Integration

- **macOS**: Keys added to Keychain automatically
- **Linux**: Manual ssh-add required
- **Windows**: Depends on environment (Git Bash, WSL, etc.)

### Credential Management

#### Platform-Specific Helpers

- **macOS**: osxkeychain (automatic)
- **Linux**: libsecret or store
- **Windows**: manager (Windows Credential Manager)

#### Best Practices

1. Use secure credential helpers
2. Clear old credentials when switching accounts
3. Review stored credentials periodically

## Command Reference

### Global Options

```bash
-h, --help      Show help message
-v, --version   Show version information
-y, --yes       Skip confirmation prompts (for automation)
```

### Profile Commands

```bash
add <name> <email> [name] [gpg]    Add new profile
list                               List all profiles
current                           Show current profile
switch <name> [email]             Switch to profile
remove <name>                     Remove profile
```

### Email Commands

```bash
add-email <profile> <email>       Add email to profile
remove-email <profile> <email>    Remove email from profile
list-emails <profile>             List profile emails
```

### Name Management

```bash
set-name <profile> <name>         Set git name for profile
```

### Directory Rules

```bash
auto <directory> <profile>        Add auto-switch rule
auto-remove <directory>           Remove auto-switch rule
auto-list                         List all rules
```

### Import/Export

```bash
export [file]                     Export profiles
import <file>                     Import profiles
```

## Configuration Files

### Profile Storage

- **Location**: `~/.github-switcher/profiles.json`
- **Format**: JSON with profile objects
- **Backup**: Automatic backups during migrations

### Directory Rules

- **Location**: `~/.github-switcher/directory_rules.json`
- **Format**: JSON mapping directories to profiles

### Current Profile

- **Location**: `~/.github-switcher/current_profile`
- **Format**: Plain text file with profile name

## Best Practices

### 1. Profile Naming

- Use descriptive names: `work`, `personal`, `client-name`
- Avoid spaces and special characters
- Keep names short but meaningful

### 2. Email Management

- Set primary email to your most-used address for that profile
- Add additional emails as needed for different contexts
- Remove unused emails to keep profiles clean

### 3. Directory Organization

- Use consistent directory structures
- Set up auto-switching for main project directories
- Consider separate directories for different clients/companies

### 4. Security

- Use GPG signing for important repositories
- Review credential storage regularly
- Use SSH keys instead of passwords
- Keep GPG keys backed up securely

### 5. Team Workflows

- Export/import profiles for consistent team setup
- Share SSH config examples
- Document profile conventions

For additional support, see the [Troubleshooting Guide](troubleshooting.md).
