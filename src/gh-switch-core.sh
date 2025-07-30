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

# Pparse command line flags
parse_flags() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --yes|-y)
                SKIP_CONFIRMATIONS=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                echo "GitHub Account Switcher v$VERSION"
                exit 0
                ;;
            *)
                # Return remaining args with proper quoting
                printf '%q ' "$@"
                return
                ;;
        esac
    done
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
    echo "  help                           Show this help message"
    echo
    echo "Examples:"
    echo "  gh-switch add work john.doe@company.com \"John Doe\" 1A2B3C4D5E6F7G8H"
    echo "  gh-switch add personal john@gmail.com \"John Smith\""
    echo "  gh-switch add-email work john.doe@contractor.com"
    echo "  gh-switch switch work john.doe@contractor.com"
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

# Check if we're in a git repository
is_git_repo() {
    git rev-parse --git-dir > /dev/null 2>&1
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