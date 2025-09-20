#!/usr/bin/env bash
VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.github-switcher"
PROFILES_FILE="$CONFIG_DIR/profiles.json"
CURRENT_PROFILE_FILE="$CONFIG_DIR/current_profile"
DIRECTORY_RULES_FILE="$CONFIG_DIR/directory_rules.json"

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global flags
SKIP_CONFIRMATIONS=false
AUTO_SSH=false

# Parse command line flags (modifies global variables in-place)
# Call with: parse_flags "$@"
# Then use: shift $FLAGS_PARSED to remove parsed flags from $@
parse_flags() {
    FLAGS_PARSED=0
    while [[ $# -gt 0 ]]; do
        case $1 in
            --yes|-y)
                SKIP_CONFIRMATIONS=true
                shift
                ((FLAGS_PARSED++))
                ;;
            --auto-ssh|-s)
                AUTO_SSH=true
                shift
                ((FLAGS_PARSED++))
                ;;
            *)
                # Stop parsing when we hit non-flag argument
                return 0
                ;;
        esac
    done
    return 0
}

# Ask for confirmation
confirm() {
    local message="$1"
    local default="${2:-N}"
    
    if [ "$SKIP_CONFIRMATIONS" = true ]; then
        echo -e "${YELLOW}$message (auto-confirmed)${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}$message (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate email format
validate_email() {
    if [[ ! "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        echo -e "${RED}Invalid email format: $1${NC}"
        echo "Please provide a valid email address."
        return 1
    fi
    return 0
}

# Validate GPG key format
validate_gpg_key() {
    local key="$1"
    if [[ ! "$key" =~ ^[A-F0-9]{8,}$ ]]; then
        echo -e "${YELLOW}Warning: GPG key '$key' doesn't match expected format${NC}"
        echo "Expected format: 8+ hexadecimal characters (e.g., 1A2B3C4D5E6F7G8H)"
        if ! confirm "Continue anyway?"; then
            return 1
        fi
    fi
    return 0
}

# Create config directory if it doesn't exist
init_config() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        echo "{}" > "$PROFILES_FILE"
        echo "{}" > "$DIRECTORY_RULES_FILE"
        echo -e "${GREEN}Initialized GitHub Account Switcher in $CONFIG_DIR${NC}"
    elif [ ! -f "$PROFILES_FILE" ]; then
        echo "{}" > "$PROFILES_FILE"
        echo -e "${GREEN}Created new profiles file at $PROFILES_FILE${NC}"
    fi
    
    if [ ! -f "$DIRECTORY_RULES_FILE" ]; then
        echo "{}" > "$DIRECTORY_RULES_FILE"
    fi
    
    # Ensure the profiles file is valid JSON
    if ! jq empty "$PROFILES_FILE" 2>/dev/null; then
        echo -e "${RED}Error: Profiles file is corrupted${NC}"
        if confirm "Would you like to reset it?"; then
            echo "{}" > "$PROFILES_FILE"
            echo -e "${GREEN}Reset profiles file to empty state${NC}"
        else
            echo -e "${RED}Exiting without changes${NC}"
            exit 1
        fi
    fi
    
    # Migrate old format profiles to new format (backward compatibility)
    migrate_profiles
}

# Migrate old profile format to new multi-email format
migrate_profiles() {
    # Check if any profiles use the old format (single email field)
    if jq -e 'to_entries | .[] | select(.value.email and (.value.emails | not))' "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${YELLOW}Migrating profiles to new multi-email format...${NC}"
        
        # Create backup
        cp "$PROFILES_FILE" "$CONFIG_DIR/profiles.json.backup"
        
        # Migrate each profile
        jq 'to_entries | map(
            if .value.email and (.value.emails | not) then
                .value = {
                    "emails": [.value.email],
                    "primary_email": .value.email,
                    "name": (.value.name // ""),
                    "gpg_key": .value.gpg_key
                }
            else . end
        ) | from_entries' "$PROFILES_FILE" > "$CONFIG_DIR/temp.json"
        
        if mv "$CONFIG_DIR/temp.json" "$PROFILES_FILE"; then
            echo -e "${GREEN}Successfully migrated profiles to new format${NC}"
            echo -e "${YELLOW}Backup saved as: $CONFIG_DIR/profiles.json.backup${NC}"
        else
            echo -e "${RED}Error: Failed to migrate profiles${NC}"
            # Restore from backup
            mv "$CONFIG_DIR/profiles.json.backup" "$PROFILES_FILE"
        fi
    fi
}

# Help message
show_help() {
    echo -e "${BLUE}GitHub Account Switcher v$VERSION${NC}"
    echo "A tool to quickly switch between GitHub accounts with multi-email support"
    echo
    echo "Usage:"
    echo "  gh-switch [global-options] [command] [options]"
    echo
    echo "Global Options:"
    echo "  -y, --yes           Skip confirmation prompts"
    echo "  -s, --auto-ssh      Automatically add SSH key to agent/keychain"
    echo "  -h, --help          Show this help message"
    echo "  -v, --version       Show version information"
    echo
    echo "Commands:"
    echo "  list                List all profiles"
    echo "  current             Show current profile and active email"
    echo "  add <name> <email> [git-name] [gpg-key]  Add a new profile"
    echo "  switch <name> [email]           Switch to a profile (optionally specify email)"
    echo "  remove <name>                   Remove a profile"
    echo "  add-email <name> <email>        Add an additional email to an existing profile"
    echo "  remove-email <name> <email>     Remove an email from a profile"
    echo "  list-emails <name>              List all emails for a profile"
    echo "  set-name <name> <git-name>      Set or update the git name for a profile"
    echo "  auto <directory> <profile>      Set up automatic profile switching for directory"
    echo "  auto-remove <directory>         Remove automatic switching for directory"
    echo "  auto-list                       List all directory-based switching rules"
    echo "  export [file]                   Export profiles to file (default: stdout)"
    echo "  import <file>                   Import profiles from file"
    echo "  update                          Update gh-switch to the latest version"
    echo "  help                           Show this help message"
    echo
    echo "Examples:"
    echo "  gh-switch add work john.doe@company.com \"John Doe\" 1A2B3C4D5E6F7G8H"
    echo "  gh-switch add personal john@gmail.com \"John Smith\""
    echo "  gh-switch add-email work john.doe@contractor.com"
    echo "  gh-switch switch work john.doe@contractor.com"
    echo "  gh-switch --auto-ssh switch work"
    echo "  gh-switch auto ~/projects/work work"
    echo "  gh-switch export > my-profiles.json"
    echo "  gh-switch --yes import my-profiles.json"
    echo
}

# Add a new profile
add_profile() {
    if [ $# -lt 2 ]; then
        echo -e "${RED}Error: Missing arguments${NC}"
        echo "Usage: gh-switch add <profile-name> <email> [git-name] [gpg-key-id]"
        return 1
    fi

    local profile_name="$1"
    local email="$2"
    local git_name="${3:-}"
    local gpg_key="${4:-}"
    
    # Validate email
    validate_email "$email" || return 1
    
    # Validate GPG key if provided
    if [ -n "$gpg_key" ]; then
        validate_gpg_key "$gpg_key" || return 1
        
        # Verify GPG key exists if provided
        if command -v gpg &> /dev/null && ! gpg --list-keys "$gpg_key" &>/dev/null; then
            echo -e "${YELLOW}Warning: GPG key '$gpg_key' not found in your keyring${NC}"
            echo "The key ID will still be saved, but signing may not work until you import the key."
            if ! confirm "Continue anyway?"; then
                echo -e "${RED}Operation cancelled${NC}"
                return 1
            fi
        fi
    fi
    
    # Check if profile already exists
    if jq -e ".\"$profile_name\"" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${YELLOW}Profile '$profile_name' already exists. Updating...${NC}"
    fi
    
    # Add profile to profiles.json with new structure
    if ! jq --arg name "$profile_name" --arg email "$email" --arg git_name "$git_name" --arg gpg "$gpg_key" \
       '.[$name] = {"emails": [$email], "primary_email": $email, "name": $git_name, "gpg_key": $gpg}' "$PROFILES_FILE" > "$CONFIG_DIR/temp.json"; then
        echo -e "${RED}Error: Failed to update profile file${NC}"
        return 1
    fi
    
    if ! mv "$CONFIG_DIR/temp.json" "$PROFILES_FILE"; then
        echo -e "${RED}Error: Failed to save profile file${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Profile '$profile_name' added/updated:${NC}"
    echo -e "  Primary email: $email"
    [ -n "$git_name" ] && echo -e "  Git name: $git_name"
    [ -n "$gpg_key" ] && echo -e "  GPG key: $gpg_key"
    
    # Offer to switch to this profile
    if confirm "Would you like to switch to this profile now?"; then
        switch_profile "$profile_name"
    fi
    
    return 0
}

# Add email to existing profile
add_email_to_profile() {
    if [ $# -lt 2 ]; then
        echo -e "${RED}Error: Missing arguments${NC}"
        echo "Usage: gh-switch add-email <name> <email>"
        return 1
    fi

    local profile_name="$1"
    local email="$2"
    
    # Validate email
    validate_email "$email" || return 1
    
    # Check if profile exists
    if ! jq -e ".\"$profile_name\"" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: Profile '$profile_name' does not exist${NC}"
        echo "Use 'gh-switch add $profile_name $email' to create a new profile"
        return 1
    fi
    
    # Check if email already exists in profile
    if jq -e ".\"$profile_name\".emails | map(select(. == \"$email\")) | length > 0" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${YELLOW}Email '$email' already exists in profile '$profile_name'${NC}"
        return 0
    fi
    
    # Add email to profile
    if ! jq --arg name "$profile_name" --arg email "$email" \
       '.[$name].emails += [$email]' "$PROFILES_FILE" > "$CONFIG_DIR/temp.json"; then
        echo -e "${RED}Error: Failed to update profile file${NC}"
        return 1
    fi
    
    if ! mv "$CONFIG_DIR/temp.json" "$PROFILES_FILE"; then
        echo -e "${RED}Error: Failed to save profile file${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Added email '$email' to profile '$profile_name'${NC}"
    return 0
}

# Remove email from profile
remove_email_from_profile() {
    if [ $# -lt 2 ]; then
        echo -e "${RED}Error: Missing arguments${NC}"
        echo "Usage: gh-switch remove-email <name> <email>"
        return 1
    fi

    local profile_name="$1"
    local email="$2"
    
    # Check if profile exists
    if ! jq -e ".\"$profile_name\"" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: Profile '$profile_name' does not exist${NC}"
        return 1
    fi
    
    # Check if this is the primary email
    local primary_email=$(jq -r ".\"$profile_name\".primary_email" "$PROFILES_FILE")
    if [ "$primary_email" = "$email" ]; then
        echo -e "${RED}Error: Cannot remove primary email '$email'${NC}"
        echo "Set a different email as primary first or remove the entire profile"
        return 1
    fi
    
    # Remove email from profile
    if ! jq --arg name "$profile_name" --arg email "$email" \
       '.[$name].emails = (.[$name].emails | map(select(. != $email)))' "$PROFILES_FILE" > "$CONFIG_DIR/temp.json"; then
        echo -e "${RED}Error: Failed to update profile file${NC}"
        return 1
    fi
    
    if ! mv "$CONFIG_DIR/temp.json" "$PROFILES_FILE"; then
        echo -e "${RED}Error: Failed to save profile file${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Removed email '$email' from profile '$profile_name'${NC}"
    return 0
}

# List emails for a profile
list_profile_emails() {
    if [ $# -lt 1 ]; then
        echo -e "${RED}Error: Missing profile name${NC}"
        echo "Usage: gh-switch list-emails <name>"
        return 1
    fi

    local profile_name="$1"
    
    # Check if profile exists
    if ! jq -e ".\"$profile_name\"" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: Profile '$profile_name' does not exist${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Emails for profile '$profile_name':${NC}"
    
    # Get primary email
    local primary_email=$(jq -r ".\"$profile_name\".primary_email" "$PROFILES_FILE")
    
    # List all emails
    jq -r ".\"$profile_name\".emails[]" "$PROFILES_FILE" | while read -r email_addr; do
        if [ "$email_addr" = "$primary_email" ]; then
            echo -e "${GREEN}* $email_addr (primary)${NC}"
        else
            echo "  $email_addr"
        fi
    done
    
    return 0
}

# Set git name for profile
set_profile_name() {
    if [ $# -lt 2 ]; then
        echo -e "${RED}Error: Missing arguments${NC}"
        echo "Usage: gh-switch set-name <profile> <git-name>"
        return 1
    fi

    local profile_name="$1"
    local git_name="$2"
    
    # Check if profile exists
    if ! jq -e ".\"$profile_name\"" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: Profile '$profile_name' does not exist${NC}"
        return 1
    fi
    
    # Update git name in profile
    if ! jq --arg name "$profile_name" --arg git_name "$git_name" \
       '.[$name].name = $git_name' "$PROFILES_FILE" > "$CONFIG_DIR/temp.json"; then
        echo -e "${RED}Error: Failed to update profile file${NC}"
        return 1
    fi
    
    if ! mv "$CONFIG_DIR/temp.json" "$PROFILES_FILE"; then
        echo -e "${RED}Error: Failed to save profile file${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Set git name for profile '$profile_name' to '$git_name'${NC}"
    
    # Update the current git configuration if this is the active profile
    if [ -f "$CURRENT_PROFILE_FILE" ]; then
        local current_profile=$(cat "$CURRENT_PROFILE_FILE")
        if [ "$current_profile" = "$profile_name" ]; then
            if ! git config --global user.name "$git_name"; then
                echo -e "${YELLOW}Warning: Failed to update current git name configuration${NC}"
            else
                echo -e "${GREEN}Updated current git configuration with new name${NC}"
            fi
        fi
    fi
    
    return 0
}

# Export profiles
export_profiles() {
    local output_file="${1:-}"
    
    if [ -n "$output_file" ]; then
        if jq '.' "$PROFILES_FILE" > "$output_file"; then
            echo -e "${GREEN}Profiles exported to '$output_file'${NC}"
        else
            echo -e "${RED}Error: Failed to export profiles${NC}"
            return 1
        fi
    else
        jq '.' "$PROFILES_FILE"
    fi
    
    return 0
}

# Import profiles
import_profiles() {
    if [ $# -lt 1 ]; then
        echo -e "${RED}Error: Missing import file${NC}"
        echo "Usage: gh-switch import <file>"
        return 1
    fi

    local import_file="$1"
    
    if [ ! -f "$import_file" ]; then
        echo -e "${RED}Error: Import file '$import_file' does not exist${NC}"
        return 1
    fi
    
    # Validate JSON format
    if ! jq empty "$import_file" 2>/dev/null; then
        echo -e "${RED}Error: Import file is not valid JSON${NC}"
        return 1
    fi
    
    # Create backup
    cp "$PROFILES_FILE" "$CONFIG_DIR/profiles.json.backup"
    
    # Show what will be imported
    echo -e "${BLUE}Profiles to import:${NC}"
    jq -r 'to_entries | .[] | "  \(.key): \(.value.primary_email // .value.email)"' "$import_file"
    
    if ! confirm "Import these profiles? This will merge with existing profiles."; then
        echo -e "${YELLOW}Import cancelled${NC}"
        return 0
    fi
    
    # Merge profiles
    if ! jq -s '.[0] * .[1]' "$PROFILES_FILE" "$import_file" > "$CONFIG_DIR/temp.json"; then
        echo -e "${RED}Error: Failed to merge profiles${NC}"
        return 1
    fi
    
    if ! mv "$CONFIG_DIR/temp.json" "$PROFILES_FILE"; then
        echo -e "${RED}Error: Failed to save merged profiles${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Successfully imported profiles${NC}"
    echo -e "${YELLOW}Backup saved as: $CONFIG_DIR/profiles.json.backup${NC}"
    
    return 0
}

# Update gh-switch to the latest version
update_gh_switch() {
    echo -e "${BLUE}Checking for updates...${NC}"

    # GitHub repository information
    local REPO_OWNER="calghar"
    local REPO_NAME="gh-account-switcher"
    local GITHUB_API="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME"

    # Check if we can reach GitHub
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Error: curl is required for updates${NC}"
        return 1
    fi

    # Get latest version from GitHub API
    local latest_version
    latest_version=$(curl -s "$GITHUB_API/releases/latest" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4 2>/dev/null)

    if [ -z "$latest_version" ]; then
        echo -e "${RED}Error: Could not fetch latest version from GitHub${NC}"
        echo "Please check your internet connection or update manually."
        return 1
    fi

    # Remove 'v' prefix if present
    latest_version=${latest_version#v}

    # Compare versions
    if [ "$latest_version" = "$VERSION" ]; then
        echo -e "${GREEN}You are already running the latest version ($VERSION)${NC}"
        return 0
    fi

    echo -e "${YELLOW}New version available: $latest_version (current: $VERSION)${NC}"

    if ! confirm "Would you like to update now?"; then
        echo -e "${YELLOW}Update cancelled${NC}"
        return 0
    fi

    # Detect platform
    local platform
    case "$(uname -s)" in
        Darwin)  platform="macos" ;;
        Linux)   platform="linux" ;;
        MINGW*|MSYS*|CYGWIN*) platform="windows" ;;
        *)
            echo -e "${RED}Error: Unsupported platform $(uname -s)${NC}"
            return 1
            ;;
    esac

    # Find current installation location
    local install_path
    install_path=$(which gh-switch 2>/dev/null)
    if [ -z "$install_path" ]; then
        echo -e "${RED}Error: Could not locate current gh-switch installation${NC}"
        return 1
    fi

    # Download new version
    local download_url="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/main/src/gh-switch-${platform}.sh"
    local temp_file="/tmp/gh-switch-update-$$"

    echo -e "${CYAN}Downloading update...${NC}"
    if ! curl -fsSL "$download_url" -o "$temp_file"; then
        echo -e "${RED}Error: Failed to download update${NC}"
        rm -f "$temp_file"
        return 1
    fi

    # Verify download
    if [ ! -s "$temp_file" ]; then
        echo -e "${RED}Error: Downloaded file is empty${NC}"
        rm -f "$temp_file"
        return 1
    fi

    # Create backup
    local backup_file="${install_path}.backup"
    if ! cp "$install_path" "$backup_file"; then
        echo -e "${RED}Error: Could not create backup${NC}"
        rm -f "$temp_file"
        return 1
    fi

    # Install new version
    echo -e "${CYAN}Installing update...${NC}"
    if ! cp "$temp_file" "$install_path"; then
        echo -e "${RED}Error: Failed to install update${NC}"
        echo -e "${YELLOW}Restoring backup...${NC}"
        cp "$backup_file" "$install_path"
        rm -f "$temp_file" "$backup_file"
        return 1
    fi

    # Set executable permissions
    chmod +x "$install_path"

    # Download and update core file if needed
    local core_dir
    core_dir=$(dirname "$install_path")
    if [[ "$install_path" == *"/.local/bin/"* ]]; then
        core_dir="$HOME/.local/lib/gh-switch"
        mkdir -p "$core_dir"
        if ! curl -fsSL "https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/main/src/gh-switch-core.sh" -o "$core_dir/gh-switch-core.sh"; then
            echo -e "${YELLOW}Warning: Could not update core file${NC}"
        fi
    fi

    # Clean up
    rm -f "$temp_file" "$backup_file"

    echo -e "${GREEN}Successfully updated to version $latest_version!${NC}"
    echo -e "${CYAN}Run 'gh-switch --version' to verify the update${NC}"

    return 0
}

# Check if we're in a git repository
is_git_repo() {
    git rev-parse --git-dir > /dev/null 2>&1
}

# Check if SSH key is loaded in agent
is_ssh_key_loaded() {
    local profile_name="$1"
    ssh-add -l 2>/dev/null | grep -q "id_${profile_name}"
}

# Ensure SSH config has entry for this profile
ensure_ssh_config_entry() {
    local profile_name="$1"
    local ssh_config="$HOME/.ssh/config"
    local host_alias="github.com-${profile_name}"
    local ssh_key_file="$HOME/.ssh/id_${profile_name}"

    # Create .ssh directory if it doesn't exist
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Create config file if it doesn't exist
    if [ ! -f "$ssh_config" ]; then
        touch "$ssh_config"
        chmod 600 "$ssh_config"
    fi

    # Check if entry already exists
    if grep -q "Host ${host_alias}" "$ssh_config" 2>/dev/null; then
        return 0
    fi

    # Add entry to SSH config
    cat >> "$ssh_config" << EOF

# GitHub profile: ${profile_name}
Host ${host_alias}
    HostName github.com
    User git
    IdentityFile ${ssh_key_file}
    IdentitiesOnly yes
EOF

    echo -e "${GREEN}Added SSH config entry for profile '${profile_name}'${NC}"
    echo -e "${YELLOW}Use this host in git URLs: git@${host_alias}:user/repo.git${NC}"
    return 0
}

# Auto-add SSH key to agent/keychain (platform-specific implementation will override)
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

    # Platform-specific implementation should override this
    echo -e "${YELLOW}SSH key auto-addition not implemented for this platform${NC}"
    return 1
}

# Current directory profile rule
get_directory_profile() {
    local current_dir="$(pwd)"
    
    # Check for exact match first
    local profile=$(jq -r --arg dir "$current_dir" '.[$dir] // empty' "$DIRECTORY_RULES_FILE" 2>/dev/null)
    if [ -n "$profile" ]; then
        echo "$profile"
        return 0
    fi
    
    # Check for parent directory matches (longest match wins)
    local best_match=""
    local best_length=0
    
    while IFS= read -r rule_dir; do
        if [[ "$current_dir" == "$rule_dir"* ]]; then
            local rule_length=${#rule_dir}
            if [ $rule_length -gt $best_length ]; then
                best_match=$(jq -r --arg dir "$rule_dir" '.[$dir]' "$DIRECTORY_RULES_FILE")
                best_length=$rule_length
            fi
        fi
    done < <(jq -r 'keys[]' "$DIRECTORY_RULES_FILE" 2>/dev/null)
    
    if [ -n "$best_match" ]; then
        echo "$best_match"
        return 0
    fi
    
    return 1
}

# Add directory rule
add_directory_rule() {
    if [ $# -lt 2 ]; then
        echo -e "${RED}Error: Missing arguments${NC}"
        echo "Usage: gh-switch auto <directory> <profile>"
        return 1
    fi

    local directory="$1"
    local profile_name="$2"
    
    # Convert to absolute path
    directory=$(realpath "$directory" 2>/dev/null || echo "$directory")
    
    # Check if profile exists
    if ! jq -e ".\"$profile_name\"" "$PROFILES_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: Profile '$profile_name' does not exist${NC}"
        return 1
    fi
    
    # Check if directory exists
    if [ ! -d "$directory" ]; then
        echo -e "${YELLOW}Warning: Directory '$directory' does not exist${NC}"
        if ! confirm "Add rule anyway?"; then
            return 1
        fi
    fi
    
    # Add rule
    if ! jq --arg dir "$directory" --arg profile "$profile_name" \
       '.[$dir] = $profile' "$DIRECTORY_RULES_FILE" > "$CONFIG_DIR/temp.json"; then
        echo -e "${RED}Error: Failed to update directory rules${NC}"
        return 1
    fi
    
    if ! mv "$CONFIG_DIR/temp.json" "$DIRECTORY_RULES_FILE"; then
        echo -e "${RED}Error: Failed to save directory rules${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Added automatic switching rule:${NC}"
    echo -e "  Directory: $directory"
    echo -e "  Profile: $profile_name"
    
    return 0
}

# Remove directory rule
remove_directory_rule() {
    if [ $# -lt 1 ]; then
        echo -e "${RED}Error: Missing directory${NC}"
        echo "Usage: gh-switch auto-remove <directory>"
        return 1
    fi

    local directory="$1"
    
    # Convert to absolute path
    directory=$(realpath "$directory" 2>/dev/null || echo "$directory")
    
    # Check if rule exists
    if ! jq -e --arg dir "$directory" '.[$dir]' "$DIRECTORY_RULES_FILE" > /dev/null 2>&1; then
        echo -e "${RED}Error: No automatic switching rule found for '$directory'${NC}"
        return 1
    fi
    
    # Remove rule
    if ! jq --arg dir "$directory" 'del(.[$dir])' "$DIRECTORY_RULES_FILE" > "$CONFIG_DIR/temp.json"; then
        echo -e "${RED}Error: Failed to update directory rules${NC}"
        return 1
    fi
    
    if ! mv "$CONFIG_DIR/temp.json" "$DIRECTORY_RULES_FILE"; then
        echo -e "${RED}Error: Failed to save directory rules${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Removed automatic switching rule for '$directory'${NC}"
    
    return 0
}

# List directory rules
list_directory_rules() {
    echo -e "${BLUE}Automatic profile switching rules:${NC}"
    
    if [ ! -f "$DIRECTORY_RULES_FILE" ] || [ "$(jq 'length' "$DIRECTORY_RULES_FILE")" -eq 0 ]; then
        echo -e "${YELLOW}No automatic switching rules configured${NC}"
        return 0
    fi
    
    jq -r 'to_entries | .[] | "  \(.key) -> \(.value)"' "$DIRECTORY_RULES_FILE"
    
    return 0
}

# Check and auto-switch profile based on directory
auto_switch_check() {
    local profile=$(get_directory_profile)
    if [ -n "$profile" ]; then
        local current_profile=""
        if [ -f "$CURRENT_PROFILE_FILE" ]; then
            current_profile=$(cat "$CURRENT_PROFILE_FILE")
        fi
        
        if [ "$current_profile" != "$profile" ]; then
            echo -e "${CYAN}Auto-switching to profile '$profile' for current directory${NC}"
            switch_profile "$profile" "" "auto"
        fi
    fi
}