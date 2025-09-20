# Command Reference

Complete reference for all gh-switch commands and options.

## Core Commands

### `gh-switch add <name> <email> [git-name] [gpg-key]`

Add a new profile with the specified email and optional git name and GPG key.

**Examples:**

```bash
gh-switch add work john.doe@company.com "John Doe" ABC123DEF456
gh-switch add personal john@gmail.com "Johnny Smith"
```

### `gh-switch switch <name> [email]`

Switch to the specified profile. Optionally specify which email to use if the profile has multiple emails.

**Examples:**

```bash
gh-switch switch work
gh-switch switch work john.contractor@company.com
gh-switch --auto-ssh switch personal  # Auto-add SSH key
```

### `gh-switch list`

List all available profiles with their details.

### `gh-switch current`

Show the currently active profile and configuration.

### `gh-switch remove <name>`

Remove a profile permanently.

## Email Management

### `gh-switch add-email <profile> <email>`

Add an additional email address to an existing profile.

### `gh-switch remove-email <profile> <email>`

Remove an email address from a profile (cannot remove primary email).

### `gh-switch list-emails <profile>`

List all email addresses for a specific profile.

## Advanced Features

### `gh-switch set-name <profile> <name>`

Set or update the git name for a profile.

### `gh-switch auto <directory> <profile>`

Set up automatic profile switching for a directory.

### `gh-switch auto-remove <directory>`

Remove automatic switching for a directory.

### `gh-switch auto-list`

List all directory-based switching rules.

### `gh-switch export [file]`

Export profiles to a file (or stdout if no file specified).

### `gh-switch import <file>`

Import profiles from a file.

### `gh-switch update`

Update gh-switch to the latest version from GitHub.

## Global Options

- `--yes, -y`: Skip confirmation prompts (useful for automation)
- `--auto-ssh, -s`: Automatically add SSH key to agent/keychain when switching
- `--help, -h`: Show help message
- `--version, -v`: Show version information

## Examples

### Basic Workflow

```bash
# Set up profiles
gh-switch add work john.doe@company.com "John Doe (Work)" ABC123
gh-switch add personal john@gmail.com "John Smith"

# Switch between them
gh-switch switch work
gh-switch switch personal

# Add multiple emails to work profile
gh-switch add-email work john.contractor@company.com
gh-switch switch work john.contractor@company.com
```

### Automation

```bash
# Set up directory-based switching
gh-switch auto ~/projects/work work
gh-switch auto ~/projects/personal personal

# Now switching happens automatically when you cd
cd ~/projects/work     # Automatically switches to 'work' profile
cd ~/projects/personal # Automatically switches to 'personal' profile
```

### SSH Key Management

```bash
# Manual SSH key addition (traditional way)
gh-switch switch work
ssh-add --apple-use-keychain ~/.ssh/id_work

# Automatic SSH key addition (new feature)
gh-switch --auto-ssh switch work  # Automatically adds the SSH key
```

### Profile Management

```bash
# Export profiles for backup
gh-switch export > my-profiles.json

# Import on another machine
gh-switch import my-profiles.json

# Update to latest version
gh-switch update
```
