#!/usr/bin/env bash
# GitHub Account Switcher for Linux
# Easily switch between multiple GitHub accounts on Linux systems

VERSION="1.0.0"
CONFIG_DIR="$HOME/.github-switcher"
PROFILES_FILE="$CONFIG_DIR/profiles.json"
CURRENT_PROFILE_FILE="$CONFIG_DIR/current_profile"

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check prerequisites
check_prerequisites() {
    # Check for git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: Git is not installed${NC}"
        echo "Please install Git:"
        echo "  - Debian/Ubuntu: sudo apt-get install git"
        echo "  - RHEL/CentOS: sudo yum install git"
        echo "  - Arch Linux: sudo pacman -S git"
        exit 1
    fi
    
    # Check for jq
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: This script requires 'jq' to be installed${NC}"
        echo "Please install jq:"
        echo "  - Debian/Ubuntu: sudo apt-get install jq"
        echo "  - RHEL/CentOS: sudo yum install jq"
        echo "  - Arch Linux: sudo pacman -S jq"
        exit 1
    fi
    
    # Check for GPG if we plan to use signing
    if [ "$1" = "check-gpg" ]; then
        if ! command -v gpg &> /dev/null; then
            echo -e "${YELLOW}Warning: GPG is not installed. Signing commits will not work.${NC}"
            echo "To install GPG:"
            echo "  - Debian/Ubuntu: sudo apt-get install gnupg"
            echo "  - RHEL/CentOS: sudo yum install gnupg2"
            echo "  - Arch Linux: sudo pacman -S gnupg"
            # Continue without exit since GPG is optional
        fi
    fi
}

# Create config directory if it doesn't exist
init_config() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        echo "{}" > "$PROFILES_FILE"
        echo -e "${GREEN}Initialized GitHub Account Switcher in $CONFIG_DIR${NC}"
    elif [ ! -f "$PROFILES_FILE" ]; then
        echo "{}" > "$PROFILES_FILE"
        echo -e "${GREEN}Created new profiles file at $PROFILES_FILE${NC}"
    fi
    
    # Ensure the profiles file is valid JSON
    if ! jq empty "$PROFILES_FILE" 2>/dev/null; then
        echo -e "${RED}Error: Profiles file is corrupted${NC}"
        echo "Would you like to reset it? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo "{}" > "$PROFILES_FILE"
            echo -e "${GREEN}Reset profiles file to empty state${NC}"
        else
            echo -e "${RED}Exiting without changes${NC}"
            exit 1
        fi
    fi
}

# Function to validate email format
validate_email() {
    if [[ ! "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        echo -e "${RED}Invalid email format: $1${NC}"
        echo "Please provide a valid email address."
        return 1
    fi
    return 0
}

# Function to display help message
show_help() {
    echo -e "${BLUE}GitHub Account Switcher for Linux v$VERSION${NC}"
    echo "A tool to quickly switch between GitHub accounts"
    echo
    echo "Usage:"
    echo "  gh-switch [command] [options]"
    echo
    echo "Commands:"
    echo "  list                     List all profiles"
    echo "  current                  Show current profile"
    echo "  add <name> <email> [gpg] Add a new profile (gpg key ID is optional)"
    echo "  switch <name>            Switch to a profile"
    echo "  remove <name>            Remove a profile"
    echo "  help                     Show this help message"
    echo
    echo "Examples:"
    echo "  gh-switch add work john.doe@company.com 1A2B3C4D5E6F7G8H"
    echo "  gh-switch add personal john.personal@gmail.com"
    echo "  gh-switch switch work"
    echo
}

# Function to add a new profile
add_profile() {
    if [ $# -lt 2 ]; then
        echo -e "${RED}Error: Missing arguments${NC}"
        echo "Usage: gh-switch add <name> <email> [gpg-key-id]"
        return 1
    fi

    name="$1"
    email="$2"
    gpg_key=""
    
    if [ $# -ge 3 ]; then
        gpg_key="$3"
        
        # Verify GPG key exists if provided
        if ! gpg --list-keys "$gpg_key" &>/dev/null; then
            echo -e "${YELLOW}Warning: GPG key '$gpg_key' not found in your keyring${NC}"
            echo "The key ID will still be saved, but signing may not work until you import the key."
            echo "Continue anyway? (y/N)"
            read -r response
            if ! [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                echo -e "${RED}Operation cancelled${NC}"
                return 1
            fi
        fi
    fi
    
    # Validate email
    validate_email "$email" || return 1
    
    # Check if profile already exists
    if jq -e ".\"$name\"" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${YELLOW}Profile '$name' already exists. Updating...${NC}"
    fi
    
    # Add profile to profiles.json
    if ! jq --arg name "$name" --arg email "$email" --arg gpg "$gpg_key" \
       '.[$name] = {"email": $email, "gpg_key": $gpg}' "$PROFILES_FILE" > "$CONFIG_DIR/temp.json"; then
        echo -e "${RED}Error: Failed to update profile file${NC}"
        return 1
    fi
    
    if ! mv "$CONFIG_DIR/temp.json" "$PROFILES_FILE"; then
        echo -e "${RED}Error: Failed to save profile file${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Profile '$name' added/updated with email '$email'${NC}"
    
    # Offer to switch to this profile
    echo -e "${YELLOW}Would you like to switch to this profile now? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        switch_profile "$name"
    fi
    
    return 0
}

# Function to switch to a profile
switch_profile() {
    if [ $# -lt 1 ]; then
        echo -e "${RED}Error: Missing profile name${NC}"
        echo "Usage: gh-switch switch <name>"
        return 1
    fi

    name="$1"
    
    # Check if profile exists
    if ! jq -e ".\"$name\"" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: Profile '$name' does not exist${NC}"
        echo "Use 'gh-switch list' to see available profiles"
        return 1
    fi
    
    # Get profile details
    email=$(jq -r ".\"$name\".email" "$PROFILES_FILE")
    gpg_key=$(jq -r ".\"$name\".gpg_key" "$PROFILES_FILE")
    
    # Update git config
    if ! git config --global user.email "$email"; then
        echo -e "${RED}Error: Failed to update git email configuration${NC}"
        return 1
    fi
    echo -e "${GREEN}Switched to profile '$name' with email '$email'${NC}"
    
    # Update GPG key if provided
    if [ -n "$gpg_key" ] && [ "$gpg_key" != "null" ]; then
        check_prerequisites "check-gpg"
        
        # Verify the key again before configuring
        if ! gpg --list-keys "$gpg_key" &>/dev/null; then
            echo -e "${YELLOW}Warning: GPG key '$gpg_key' not found in your keyring${NC}"
            echo "Commit signing may not work until you import the key."
        fi
        
        if ! git config --global user.signingkey "$gpg_key"; then
            echo -e "${RED}Error: Failed to configure GPG signing key${NC}"
        else
            echo -e "${GREEN}Configured GPG signing with key '$gpg_key'${NC}"
        fi
        
        if ! git config --global commit.gpgsign true; then
            echo -e "${RED}Error: Failed to enable GPG signing${NC}"
        else
            echo -e "${GREEN}Enabled GPG signing for commits${NC}"
        fi
    else
        # Check if we should disable GPG signing
        if git config --global --get commit.gpgsign > /dev/null; then
            echo -e "${YELLOW}No GPG key specified for this profile. Disable GPG signing? [y/N]${NC}"
            read -r response
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                if ! git config --global --unset commit.gpgsign; then
                    echo -e "${RED}Error: Failed to disable GPG signing${NC}"
                fi
                if ! git config --global --unset user.signingkey; then
                    echo -e "${RED}Error: Failed to remove GPG signing key${NC}"
                fi
                echo -e "${YELLOW}GPG signing disabled${NC}"
            fi
        fi
    fi
    
    # Save current profile
    echo "$name" > "$CURRENT_PROFILE_FILE"
    
    # Linux-specific: Update SSH agent if needed
    if [ -n "$SSH_AUTH_SOCK" ]; then
        echo -e "${YELLOW}Note: You may need to add different SSH keys to your agent using 'ssh-add'${NC}"
        echo "For example: ssh-add ~/.ssh/id_${name}"
    fi
    
    # Check credential helper
    cred_helper=$(git config --global --get credential.helper)
    if [ -n "$cred_helper" ]; then
        echo -e "${YELLOW}Credential helper detected: $cred_helper${NC}"
        echo -e "${YELLOW}You may need to update cached credentials manually${NC}"
        
        if [[ "$cred_helper" == *"libsecret"* ]]; then
            echo -e "${YELLOW}For Linux: Use seahorse or secret-tool to manage credentials${NC}"
            echo "Example: secret-tool clear service github.com"
        elif [[ "$cred_helper" == *"cache"* ]]; then
            echo -e "${YELLOW}You're using Git's cache credential helper. Credentials will expire after a timeout.${NC}"
        fi
    fi
    
    # Remind about GitHub CLI authentication if installed
    if command -v gh &> /dev/null; then
        echo -e "${YELLOW}Note: If you use GitHub CLI, you'll need to run 'gh auth login' with the new account${NC}"
    fi
    
    return 0
}

# Function to list all profiles
list_profiles() {
    echo -e "${BLUE}Available GitHub profiles:${NC}"
    
    # Check if profiles file exists and is not empty
    if [ ! -f "$PROFILES_FILE" ] || [ ! -s "$PROFILES_FILE" ]; then
        echo -e "${YELLOW}No profiles found. Add one with 'gh-switch add <name> <email>'${NC}"
        return 0
    fi
    
    # Get current profile if exists
    current_profile=""
    if [ -f "$CURRENT_PROFILE_FILE" ]; then
        current_profile=$(cat "$CURRENT_PROFILE_FILE")
    fi
    
    # List all profiles
    if ! jq -r 'to_entries | .[] | "\(.key) (\(.value.email))" + if .value.gpg_key != null and .value.gpg_key != "" then " [GPG: \(.value.gpg_key)]" else "" end' "$PROFILES_FILE" 2>/dev/null | 
    while read -r line; do
        profile_name=$(echo "$line" | cut -d' ' -f1)
        if [ "$profile_name" = "$current_profile" ]; then
            echo -e "${GREEN}* $line${NC}"
        else
            echo "  $line"
        fi
    done; then
        echo -e "${RED}Error: Failed to parse profiles${NC}"
        return 1
    fi
    
    # Check if no profiles were listed
    if [ "$(jq 'length' "$PROFILES_FILE")" -eq 0 ]; then
        echo -e "${YELLOW}No profiles found. Add one with 'gh-switch add <name> <email>'${NC}"
    fi
    
    return 0
}

# Function to show current profile
show_current_profile() {
    if [ ! -f "$CURRENT_PROFILE_FILE" ]; then
        echo -e "${YELLOW}No active profile selected${NC}"
        echo "Use 'gh-switch switch <name>' to select a profile"
        return 0
    fi
    
    current_profile=$(cat "$CURRENT_PROFILE_FILE")
    if ! jq -e ".\"$current_profile\"" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: Current profile '$current_profile' no longer exists in profiles list${NC}"
        echo "Use 'gh-switch list' to see available profiles"
        return 1
    fi
    
    email=$(jq -r ".\"$current_profile\".email" "$PROFILES_FILE")
    gpg_key=$(jq -r ".\"$current_profile\".gpg_key" "$PROFILES_FILE")
    
    echo -e "${GREEN}Current profile: $current_profile${NC}"
    echo -e "Email: $email"
    if [ -n "$gpg_key" ] && [ "$gpg_key" != "null" ]; then
        echo -e "GPG Key: $gpg_key"
    fi
    
    # Verify git config matches profile
    git_email=$(git config --global user.email)
    if [ "$git_email" != "$email" ]; then
        echo -e "${YELLOW}Warning: Git config email ($git_email) doesn't match profile email ($email)${NC}"
        echo "Run 'gh-switch switch $current_profile' to resynchronize"
    fi
    
    # Show git signing status
    signing_enabled=$(git config --global --get commit.gpgsign)
    if [ -n "$signing_enabled" ] && [ "$signing_enabled" = "true" ]; then
        echo -e "Commit signing: ${GREEN}enabled${NC}"
    else
        echo -e "Commit signing: ${YELLOW}disabled${NC}"
    fi
    
    return 0
}

# Function to remove a profile
remove_profile() {
    if [ $# -lt 1 ]; then
        echo -e "${RED}Error: Missing profile name${NC}"
        echo "Usage: gh-switch remove <name>"
        return 1
    fi

    name="$1"
    
    # Check if profile exists
    if ! jq -e ".\"$name\"" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: Profile '$name' does not exist${NC}"
        echo "Use 'gh-switch list' to see available profiles"
        return 1
    fi
    
    # Ask for confirmation
    echo -e "${YELLOW}Are you sure you want to remove profile '$name'? (y/N)${NC}"
    read -r response
    if ! [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        return 0
    fi
    
    # Check if it's the current profile
    if [ -f "$CURRENT_PROFILE_FILE" ] && [ "$(cat "$CURRENT_PROFILE_FILE")" = "$name" ]; then
        echo -e "${YELLOW}Warning: Removing the current active profile${NC}"
        rm -f "$CURRENT_PROFILE_FILE"
    fi
    
    # Remove profile from profiles.json
    if ! jq "del(.\"$name\")" "$PROFILES_FILE" > "$CONFIG_DIR/temp.json"; then
        echo -e "${RED}Error: Failed to update profile file${NC}"
        return 1
    fi
    
    if ! mv "$CONFIG_DIR/temp.json" "$PROFILES_FILE"; then
        echo -e "${RED}Error: Failed to save profile file${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Profile '$name' removed${NC}"
    
    # Suggest switching to another profile if available
    other_profile=$(jq -r 'keys | .[0] // empty' "$PROFILES_FILE")
    if [ -n "$other_profile" ]; then
        echo -e "${YELLOW}Would you like to switch to profile '$other_profile'? (y/N)${NC}"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            switch_profile "$other_profile"
        fi
    fi
    
    return 0
}

# Check prerequisites and initialize
check_prerequisites
init_config

# Parse command line arguments
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

command="$1"
shift

case "$command" in
    "add")
        add_profile "$@"
        ;;
    "switch")
        switch_profile "$@"
        ;;
    "list")
        list_profiles
        ;;
    "current")
        show_current_profile
        ;;
    "remove")
        remove_profile "$@"
        ;;
    "help")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $command${NC}"
        show_help
        exit 1
        ;;
esac

exit_code=$?
exit $exit_code