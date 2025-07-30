#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/gh-switch-core.sh"

# Detect Windows environment
is_wsl() {
    if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
        return 0
    else
        return 1
    fi
}

is_git_bash() {
    if uname -a | grep -qE "MINGW|MSYS" ; then
        return 0
    else
        return 1
    fi
}

# Windows-specific paths
if is_git_bash; then
    WINDOWS_HOME=$(cd ~ && pwd -W)
    WINDOWS_HOME=${WINDOWS_HOME//\\/\/}
else
    WINDOWS_HOME=$HOME
fi

# Function to check prerequisites (Windows specific)
check_prerequisites() {
    # Check for git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: Git is not installed${NC}"
        echo "Please install Git for Windows:"
        echo "  - Download from: https://git-scm.com/download/win"
        echo "  - Or install via package manager:"
        echo "    - Chocolatey: choco install git"
        echo "    - Scoop: scoop install git"
        echo "    - Winget: winget install Git.Git"
        exit 1
    fi
    
    # Check for jq
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: This script requires 'jq' to be installed${NC}"
        echo "Please install jq:"
        echo "  - Chocolatey: choco install jq"
        echo "  - Scoop: scoop install jq"
        echo "  - Winget: winget install jqlang.jq"
        echo "  - Manual: Download from https://stedolan.github.io/jq/"
        exit 1
    fi
    
    # Check for GPG if we plan to use signing
    if [ "$1" = "check-gpg" ]; then
        if ! command -v gpg &> /dev/null; then
            echo -e "${YELLOW}Warning: GPG is not installed. Signing commits will not work.${NC}"
            echo "To install GPG:"
            echo "  - Install Gpg4win: https://gpg4win.org/"
            echo "  - Chocolatey: choco install gpg4win"
            echo "  - Scoop: scoop install gpg4win"
            echo "  - Winget: winget install GnuPG.Gpg4win"
            # Continue without exit since GPG is optional
        fi
    fi
    
    # Environment-specific tips
    if is_wsl; then
        echo -e "${BLUE}Note: Running in WSL environment${NC}"
    elif is_git_bash; then
        echo -e "${BLUE}Note: Running in Git Bash environment${NC}"
    fi
}

# Function to get Windows-style path for GPG
get_windows_gpg_path() {
    # Common GPG installation paths on Windows
    local gpg_paths=(
        "/c/Program Files (x86)/GnuPG/bin/gpg.exe"
        "/c/Program Files/GnuPG/bin/gpg.exe"
        "/c/ProgramData/chocolatey/bin/gpg.exe"
    )
    
    for path in "${gpg_paths[@]}"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    # Fallback to system PATH
    which gpg 2>/dev/null || echo "gpg"
}

# Function to switch to a profile (Windows-specific implementation)
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
        
        # Configure GPG for Windows
        local gpg_program=$(get_windows_gpg_path)
        
        # Set GPG program path for Git (Windows-specific)
        if is_git_bash; then
            # Convert to Windows path for Git Bash
            local windows_gpg_path
            if [[ "$gpg_program" =~ ^/c/ ]]; then
                windows_gpg_path="C:${gpg_program:2}"
                windows_gpg_path="${windows_gpg_path//\\/\\\\}"
            else
                windows_gpg_path="$gpg_program"
            fi
            git config --global gpg.program "$windows_gpg_path"
        else
            git config --global gpg.program "$gpg_program"
        fi
        
        # Configure GPG agent for Windows (if not WSL)
        if ! is_wsl; then
            if [ ! -f "$HOME/.gnupg/gpg-agent.conf" ]; then
                mkdir -p "$HOME/.gnupg"
                chmod 700 "$HOME/.gnupg"
                
                # Create basic gpg-agent.conf for Windows
                cat > "$HOME/.gnupg/gpg-agent.conf" << EOF
default-cache-ttl 3600
max-cache-ttl 86400
EOF
                
                # Use Kleopatra's pinentry if available
                if [ -f "/c/Program Files (x86)/GnuPG/bin/pinentry.exe" ]; then
                    echo "pinentry-program C:\\Program Files (x86)\\GnuPG\\bin\\pinentry.exe" >> "$HOME/.gnupg/gpg-agent.conf"
                elif [ -f "/c/Program Files/GnuPG/bin/pinentry.exe" ]; then
                    echo "pinentry-program C:\\Program Files\\GnuPG\\bin\\pinentry.exe" >> "$HOME/.gnupg/gpg-agent.conf"
                fi
                
                gpgconf --kill gpg-agent 2>/dev/null || true
                echo -e "${GREEN}Created GPG agent configuration${NC}"
            fi
        fi
        
        # Verify the key again before configuring
        if ! gpg --list-keys "$gpg_key" &>/dev/null; then
            echo -e "${YELLOW}Warning: GPG key '$gpg_key' not found in your keyring${NC}"
            echo "Commit signing may not work until you import the key."
            echo "Use Kleopatra (GUI) or 'gpg --import keyfile' to import your key."
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
    
    # Show additional info only for manual switches
    if [ "$switch_type" != "auto" ]; then
        # Windows-specific: Update SSH config if needed
        if [ -f "$HOME/.ssh/config" ]; then
            echo -e "${YELLOW}Note: You may need to update your SSH config manually for different GitHub accounts${NC}"
            echo "For example, you can set up different hosts in ~/.ssh/config:"
            echo "  Host github-$profile_name"
            echo "    HostName github.com"
            echo "    User git"
            echo "    IdentityFile ~/.ssh/id_${profile_name}"
            if ! is_wsl; then
                echo "    IdentitiesOnly yes"
            fi
        fi
        
        # Check credential helper
        local cred_helper=$(git config --global --get credential.helper)
        if [ -n "$cred_helper" ]; then
            echo -e "${YELLOW}Credential helper detected: $cred_helper${NC}"
            
            if [[ "$cred_helper" == *"manager"* ]] || [[ "$cred_helper" == *"wincred"* ]]; then
                echo -e "${YELLOW}You're using Windows Credential Manager for Git credentials.${NC}"
                echo "To manage stored credentials:"
                echo "1. Open Control Panel > User Accounts > Credential Manager"
                echo "2. Look under 'Windows Credentials' for 'git:https://github.com'"
                echo "3. Delete or modify the entry for the previous account"
            elif [[ "$cred_helper" == *"store"* ]]; then
                echo -e "${YELLOW}You're using git credential store.${NC}"
                echo "Check ~/.git-credentials file for stored credentials"
            fi
        else
            echo -e "${YELLOW}No credential helper configured. Consider adding:${NC}"
            if is_wsl; then
                echo "git config --global credential.helper store"
            else
                echo "git config --global credential.helper manager"
            fi
        fi
        
        # SSH agent tips for Windows
        if is_git_bash; then
            echo -e "${YELLOW}Tip: Start ssh-agent and add your SSH key:${NC}"
            echo "eval \$(ssh-agent -s)"
            echo "ssh-add ~/.ssh/id_${profile_name}"
        elif is_wsl; then
            echo -e "${YELLOW}Tip: Add your SSH key to ssh-agent:${NC}"
            echo "ssh-add ~/.ssh/id_${profile_name}"
        else
            echo -e "${YELLOW}Tip: Use ssh-agent or Pageant for SSH key management${NC}"
        fi
        
        # Remind about GitHub CLI authentication if installed
        if command -v gh &> /dev/null; then
            echo -e "${YELLOW}Note: If you use GitHub CLI, you'll need to run 'gh auth login' with the new account${NC}"
        fi
    fi
    
    return 0
}

# Function to list all profiles (enhanced with name display)
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

# Function to show current profile (enhanced with name and directory info)
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
    
    # Show environment info
    if is_wsl; then
        echo -e "Environment: ${BLUE}WSL${NC}"
    elif is_git_bash; then
        echo -e "Environment: ${BLUE}Git Bash${NC}"
    else
        echo -e "Environment: ${BLUE}Unix-like shell${NC}"
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
        
        # Show GPG program path
        local git_gpg_program=$(git config --global --get gpg.program)
        if [ -n "$git_gpg_program" ]; then
            echo -e "GPG program: $git_gpg_program"
        fi
    else
        echo -e "Commit signing: ${YELLOW}disabled${NC}"
    fi
    
    # Windows specific: Check SSH key availability
    if ssh-add -l 2>/dev/null | grep -q "id_${current_profile}"; then
        echo -e "SSH key for this profile: ${GREEN}loaded in SSH agent${NC}"
    else
        echo -e "SSH key for this profile: ${YELLOW}not found in SSH agent${NC}"
        if is_git_bash; then
            echo "Consider adding it with: ssh-add ~/.ssh/id_${current_profile}"
        elif is_wsl; then
            echo "Consider adding it with: ssh-add ~/.ssh/id_${current_profile}"
        else
            echo "Consider loading it in your SSH agent or Pageant"
        fi
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

# Function to remove a profile (from original script)
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
remaining_args=$(parse_flags "$@")
eval "set -- $remaining_args"

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