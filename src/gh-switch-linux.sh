#!/usr/bin/env bash
# GitHub Account Switcher for Linux v2.0
# Multi-email support, directory-based switching, and more

# Pull in shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/gh-switch-core.sh"

# Make sure we have what we need on Linux
check_prerequisites() {
    # Check for git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: Git is not installed${NC}"
        echo "Please install Git:"
        echo "  - Debian/Ubuntu: sudo apt-get install git"
        echo "  - RHEL/CentOS/Fedora: sudo dnf install git"
        echo "  - Arch Linux: sudo pacman -S git"
        exit 1
    fi
    
    # Check for jq
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: This script requires 'jq' to be installed${NC}"
        echo "Please install jq:"
        echo "  - Debian/Ubuntu: sudo apt-get install jq"
        echo "  - RHEL/CentOS/Fedora: sudo dnf install jq"
        echo "  - Arch Linux: sudo pacman -S jq"
        exit 1
    fi
    
    # Check for GPG if we plan to use signing
    if [ "$1" = "check-gpg" ]; then
        if ! command -v gpg &> /dev/null; then
            echo -e "${YELLOW}Warning: GPG is not installed. Signing commits will not work.${NC}"
            echo "To install GPG:"
            echo "  - Debian/Ubuntu: sudo apt-get install gnupg"
            echo "  - RHEL/CentOS/Fedora: sudo dnf install gnupg2"
            echo "  - Arch Linux: sudo pacman -S gnupg"
            # Continue without exit since GPG is optional
        fi
    fi
}

# Linux-specific SSH key auto-addition
auto_add_ssh_key() {
    local profile_name="$1"
    local ssh_key_file="$HOME/.ssh/id_${profile_name}"

    # Check if SSH key file exists
    if [ ! -f "$ssh_key_file" ]; then
        echo -e "${YELLOW}SSH key not found: ${ssh_key_file}${NC}"
        echo -e "${CYAN}Generate one with: ssh-keygen -t ed25519 -C \"your_email@example.com\" -f ${ssh_key_file}${NC}"
        return 1
    fi

    # Ensure SSH config entry exists
    ensure_ssh_config_entry "$profile_name"

    # Check if key is already loaded
    if is_ssh_key_loaded "$profile_name"; then
        echo -e "${GREEN}SSH key for profile '$profile_name' is already loaded${NC}"
        return 0
    fi

    # Add key to SSH agent
    echo -e "${CYAN}Adding SSH key to SSH agent...${NC}"
    if ssh-add "$ssh_key_file" 2>/dev/null; then
        echo -e "${GREEN}Successfully added SSH key for profile '$profile_name' to SSH agent${NC}"
        return 0
    else
        echo -e "${RED}Failed to add SSH key to SSH agent${NC}"
        echo -e "${YELLOW}You may need to run: ssh-add ~/.ssh/id_${profile_name}${NC}"
        return 1
    fi
}

# Switch profiles on Linux
switch_profile() {
    if [ $# -lt 1 ]; then
        echo -e "${RED}Error: Missing profile name${NC}"
        echo "Usage: gh-switch switch <name> [email]"
        return 1
    fi

    local profile_name="$1"
    local specified_email="$2"
    local switch_type="${3:-manual}"  # manual or auto
    
    # Check if profile exists
    if ! jq -e ".\"$profile_name\"" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: Profile '$profile_name' does not exist${NC}"
        echo "Use 'gh-switch list' to see available profiles"
        return 1
    fi
    
    # Determine which email to use
    local email
    if [ -n "$specified_email" ]; then
        # Validate that the specified email exists in the profile
        if ! jq -e ".\"$profile_name\".emails | map(select(. == \"$specified_email\")) | length > 0" "$PROFILES_FILE" > /dev/null 2>&1; then
            echo -e "${RED}Error: Email '$specified_email' not found in profile '$profile_name'${NC}"
            echo "Use 'gh-switch list-emails $profile_name' to see available emails"
            return 1
        fi
        email="$specified_email"
    else
        # Use primary email
        email=$(jq -r ".\"$profile_name\".primary_email" "$PROFILES_FILE")
        if [ "$email" = "null" ] || [ -z "$email" ]; then
            # Fallback to first email if primary_email is not set (for backward compatibility)
            email=$(jq -r ".\"$profile_name\".emails[0] // .\"$profile_name\".email" "$PROFILES_FILE")
        fi
    fi
    
    # Get profile details
    local git_name=$(jq -r ".\"$profile_name\".name" "$PROFILES_FILE")
    local gpg_key=$(jq -r ".\"$profile_name\".gpg_key" "$PROFILES_FILE")
    
    # Update git config
    if ! git config --global user.email "$email"; then
        echo -e "${RED}Error: Failed to update git email configuration${NC}"
        return 1
    fi
    
    # Update git name if specified
    if [ -n "$git_name" ] && [ "$git_name" != "null" ]; then
        if ! git config --global user.name "$git_name"; then
            echo -e "${RED}Error: Failed to update git name configuration${NC}"
            return 1
        fi
        if [ "$switch_type" != "auto" ]; then
            echo -e "${GREEN}Switched to profile '$profile_name' with email '$email' and name '$git_name'${NC}"
        fi
    else
        if [ "$switch_type" != "auto" ]; then
            echo -e "${GREEN}Switched to profile '$profile_name' with email '$email'${NC}"
        fi
    fi
    
    # Update GPG key if provided
    if [ -n "$gpg_key" ] && [ "$gpg_key" != "null" ]; then
        check_prerequisites "check-gpg"
        
        # Configure GPG agent for Linux
        if [ ! -f "$HOME/.gnupg/gpg-agent.conf" ]; then
            mkdir -p "$HOME/.gnupg"
            chmod 700 "$HOME/.gnupg"
            
            # Create basic gpg-agent.conf for Linux
            cat > "$HOME/.gnupg/gpg-agent.conf" << EOF
default-cache-ttl 3600
max-cache-ttl 86400
EOF
            # Try to set pinentry program
            if command -v pinentry-gtk2 &> /dev/null; then
                echo "pinentry-program $(which pinentry-gtk2)" >> "$HOME/.gnupg/gpg-agent.conf"
            elif command -v pinentry-qt &> /dev/null; then
                echo "pinentry-program $(which pinentry-qt)" >> "$HOME/.gnupg/gpg-agent.conf"
            elif command -v pinentry-curses &> /dev/null; then
                echo "pinentry-program $(which pinentry-curses)" >> "$HOME/.gnupg/gpg-agent.conf"
            fi
            
            gpgconf --kill gpg-agent
            echo -e "${GREEN}Created GPG agent configuration${NC}"
        fi
        
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
            if [ "$switch_type" != "auto" ] && confirm "No GPG key specified for this profile. Disable GPG signing?"; then
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
    echo "$profile_name" > "$CURRENT_PROFILE_FILE"

    # Handle SSH key auto-addition if requested
    local ssh_handled=false
    if [ "$AUTO_SSH" = true ] && [ "$switch_type" != "auto" ]; then
        echo ""
        if auto_add_ssh_key "$profile_name"; then
            ssh_handled=true
        fi
    fi

    # Show additional info only for manual switches
    if [ "$switch_type" != "auto" ]; then
        echo ""
        echo -e "${CYAN}Next steps:${NC}"

        # Check if SSH key exists and suggest adding it (only if not already handled)
        local ssh_key_file="$HOME/.ssh/id_${profile_name}"
        if [ -f "$ssh_key_file" ] && [ "$ssh_handled" = false ]; then
            if is_ssh_key_loaded "$profile_name"; then
                echo -e "• SSH key for this profile: ${GREEN}already loaded in SSH agent${NC}"
            else
                echo -e "• Add SSH key to ssh-agent: ${YELLOW}ssh-add ~/.ssh/id_${profile_name}${NC}"
            fi
        fi
        
        # Check credential helper and suggest credential cleanup
        local cred_helper=$(git config --global --get credential.helper)
        if [[ "$cred_helper" == *"libsecret"* ]]; then
            echo -e "• Clear stored credentials: ${YELLOW}secret-tool clear protocol https host github.com${NC}"
        elif [[ "$cred_helper" == *"store"* ]]; then
            echo -e "• Update stored credentials in ~/.git-credentials"
        fi
        
        # Remind about GitHub CLI authentication if installed
        if command -v gh &> /dev/null; then
            echo -e "• Authenticate GitHub CLI: ${YELLOW}gh auth login${NC}"
        fi
        
        echo -e "• View SSH config help: ${YELLOW}gh-switch help${NC}"
    fi
    
    return 0
}

# Show all available profiles
list_profiles() {
    echo -e "${BLUE}Available GitHub profiles:${NC}"
    
    # Check if profiles file exists and is not empty
    if [ ! -f "$PROFILES_FILE" ] || [ ! -s "$PROFILES_FILE" ]; then
        echo -e "${YELLOW}No profiles found. Add one with 'gh-switch add <name> <email>'${NC}"
        return 0
    fi
    
    # Get current profile if exists
    local current_profile=""
    if [ -f "$CURRENT_PROFILE_FILE" ]; then
        current_profile=$(cat "$CURRENT_PROFILE_FILE")
    fi
    
    # List all profiles with multi-email support
    jq -r 'to_entries | .[] | .key' "$PROFILES_FILE" 2>/dev/null | while read -r profile_name; do
        # Get profile details
        local primary_email=$(jq -r ".\"$profile_name\".primary_email // .\"$profile_name\".email" "$PROFILES_FILE")
        local email_count=$(jq -r ".\"$profile_name\".emails | length // 1" "$PROFILES_FILE")
        local git_name=$(jq -r ".\"$profile_name\".name" "$PROFILES_FILE")
        local gpg_key=$(jq -r ".\"$profile_name\".gpg_key" "$PROFILES_FILE")
        
        # Build profile info
        local profile_info="$profile_name ($primary_email)"
        if [ -n "$git_name" ] && [ "$git_name" != "null" ]; then
            profile_info="$profile_info [$git_name]"
        fi
        if [ "$email_count" -gt 1 ]; then
            profile_info="$profile_info [+$((email_count-1)) emails]"
        fi
        if [ -n "$gpg_key" ] && [ "$gpg_key" != "null" ]; then
            profile_info="$profile_info [GPG: $gpg_key]"
        fi
        
        # Display with current marker
        if [ "$profile_name" = "$current_profile" ]; then
            echo -e "${GREEN}* $profile_info${NC}"
        else
            echo "  $profile_info"
        fi
    done
    
    return 0
}

# Current profile
show_current_profile() {
    if [ ! -f "$CURRENT_PROFILE_FILE" ]; then
        echo -e "${YELLOW}No active profile selected${NC}"
        echo "Use 'gh-switch switch <name>' to select a profile"
        return 0
    fi
    
    local current_profile=$(cat "$CURRENT_PROFILE_FILE")
    if ! jq -e ".\"$current_profile\"" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: Current profile '$current_profile' no longer exists in profiles list${NC}"
        echo "Use 'gh-switch list' to see available profiles"
        return 1
    fi
    
    # Get current git configuration
    local git_email=$(git config --global user.email)
    local git_name=$(git config --global user.name)
    local primary_email=$(jq -r ".\"$current_profile\".primary_email // .\"$current_profile\".email" "$PROFILES_FILE")
    local profile_name=$(jq -r ".\"$current_profile\".name" "$PROFILES_FILE")
    local gpg_key=$(jq -r ".\"$current_profile\".gpg_key" "$PROFILES_FILE")
    
    echo -e "${GREEN}Current profile: $current_profile${NC}"
    echo -e "Active email: $git_email"
    if [ -n "$git_name" ]; then
        echo -e "Active name: $git_name"
    fi
    
    # Show all emails for this profile
    if jq -e ".\"$current_profile\".emails" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "Available emails:"
        jq -r ".\"$current_profile\".emails[]" "$PROFILES_FILE" | while read -r email_addr; do
            if [ "$email_addr" = "$primary_email" ]; then
                if [ "$email_addr" = "$git_email" ]; then
                    echo -e "  ${GREEN}* $email_addr (primary, active)${NC}"
                else
                    echo -e "  ${YELLOW}* $email_addr (primary)${NC}"
                fi
            else
                if [ "$email_addr" = "$git_email" ]; then
                    echo -e "  ${GREEN}* $email_addr (active)${NC}"
                else
                    echo -e "    $email_addr"
                fi
            fi
        done
    else
        echo -e "Primary email: $primary_email"
    fi
    
    # Show profile name info
    if [ -n "$profile_name" ] && [ "$profile_name" != "null" ]; then
        echo -e "Profile name: $profile_name"
        if [ "$profile_name" != "$git_name" ]; then
            echo -e "${YELLOW}Warning: Git name ($git_name) doesn't match profile name ($profile_name)${NC}"
        fi
    fi
    
    if [ -n "$gpg_key" ] && [ "$gpg_key" != "null" ]; then
        echo -e "GPG Key: $gpg_key"
    fi
    
    # Verify git config matches profile
    if [ "$git_email" != "$primary_email" ] && ! jq -e ".\"$current_profile\".emails | map(select(. == \"$git_email\")) | length > 0" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${YELLOW}Warning: Git config email ($git_email) doesn't match any profile email${NC}"
        echo "Run 'gh-switch switch $current_profile' to resynchronize"
    fi
    
    # Show git signing status
    local signing_enabled=$(git config --global --get commit.gpgsign)
    if [ -n "$signing_enabled" ] && [ "$signing_enabled" = "true" ]; then
        echo -e "Commit signing: ${GREEN}enabled${NC}"
        
        # Verify GPG key in git config matches profile
        local git_signing_key=$(git config --global --get user.signingkey)
        if [ -n "$git_signing_key" ] && [ -n "$gpg_key" ] && [ "$git_signing_key" != "$gpg_key" ]; then
            echo -e "${YELLOW}Warning: Git signing key ($git_signing_key) doesn't match profile GPG key ($gpg_key)${NC}"
        fi
    else
        echo -e "Commit signing: ${YELLOW}disabled${NC}"
    fi
    
    # Linux specific: Check SSH key in ssh-agent
    if ssh-add -l 2>/dev/null | grep -q "id_${current_profile}"; then
        echo -e "SSH key for this profile: ${GREEN}loaded in SSH agent${NC}"
    else
        echo -e "SSH key for this profile: ${YELLOW}not found in SSH agent${NC}"
        echo "Consider adding it with: ssh-add ~/.ssh/id_${current_profile}"
    fi
    
    # Check for directory-based auto-switching
    local auto_profile=$(get_directory_profile 2>/dev/null)
    if [ -n "$auto_profile" ]; then
        if [ "$auto_profile" = "$current_profile" ]; then
            echo -e "Directory rule: ${GREEN}matches current profile${NC}"
        else
            echo -e "Directory rule: ${YELLOW}suggests profile '$auto_profile'${NC}"
        fi
    fi
    
    return 0
}

# Remove a profile
remove_profile() {
    if [ $# -lt 1 ]; then
        echo -e "${RED}Error: Missing profile name${NC}"
        echo "Usage: gh-switch remove <name>"
        return 1
    fi

    local profile_name="$1"
    
    # Check if profile exists
    if ! jq -e ".\"$profile_name\"" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: Profile '$profile_name' does not exist${NC}"
        echo "Use 'gh-switch list' to see available profiles"
        return 1
    fi
    
    # Ask for confirmation
    if ! confirm "Are you sure you want to remove profile '$profile_name'?"; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        return 0
    fi
    
    # Check if it's the current profile
    if [ -f "$CURRENT_PROFILE_FILE" ] && [ "$(cat "$CURRENT_PROFILE_FILE")" = "$profile_name" ]; then
        echo -e "${YELLOW}Warning: Removing the current active profile${NC}"
        rm -f "$CURRENT_PROFILE_FILE"
    fi
    
    # Remove profile from profiles.json
    if ! jq "del(.\"$profile_name\")" "$PROFILES_FILE" > "$CONFIG_DIR/temp.json"; then
        echo -e "${RED}Error: Failed to update profile file${NC}"
        return 1
    fi
    
    if ! mv "$CONFIG_DIR/temp.json" "$PROFILES_FILE"; then
        echo -e "${RED}Error: Failed to save profile file${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Profile '$profile_name' removed${NC}"
    
    # Suggest switching to another profile if available
    local other_profile=$(jq -r 'keys | .[0] // empty' "$PROFILES_FILE")
    if [ -n "$other_profile" ]; then
        if confirm "Would you like to switch to profile '$other_profile'?"; then
            switch_profile "$other_profile"
        fi
    fi
    
    return 0
}

# Check prerequisites and initialize
check_prerequisites
init_config

# Parse global flags first
# Handle global flags that should exit immediately
case "$1" in
    --help|-h)
        show_help
        exit 0
        ;;
    --version|-v)
        echo "GitHub Account Switcher v$VERSION"
        exit 0
        ;;
esac

# Parse flags manually to preserve variable state
args=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --yes|-y)
            SKIP_CONFIRMATIONS=true
            shift
            ;;
        --auto-ssh|-s)
            AUTO_SSH=true
            shift
            ;;
        *)
            args+=("$1")
            shift
            ;;
    esac
done
set -- "${args[@]}"

# Check for directory-based auto-switching if in a git repo and no command specified
if [ $# -eq 0 ] && is_git_repo; then
    auto_switch_check
    exit 0
fi

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
    "add-email")
        add_email_to_profile "$@"
        ;;
    "remove-email")
        remove_email_from_profile "$@"
        ;;
    "list-emails")
        list_profile_emails "$@"
        ;;
    "set-name")
        set_profile_name "$@"
        ;;
    "auto")
        add_directory_rule "$@"
        ;;
    "auto-remove")
        remove_directory_rule "$@"
        ;;
    "auto-list")
        list_directory_rules
        ;;
    "export")
        export_profiles "$@"
        ;;
    "import")
        import_profiles "$@"
        ;;
    "update")
        update_gh_switch
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