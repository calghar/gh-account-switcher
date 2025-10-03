package cmd

import (
	"fmt"

	"github.com/calghar/gh-account-switcher/internal/config"
	"github.com/calghar/gh-account-switcher/internal/git"
	"github.com/calghar/gh-account-switcher/internal/ssh"
	"github.com/spf13/cobra"
)

var addCmd = &cobra.Command{
	Use:   "add <name> <email> [git-name] [gpg-key]",
	Short: "Add a new profile",
	Long: `Add a new GitHub profile with specified email and optional Git name and GPG key.

Examples:
  gh-switch add work john.doe@company.com "John Doe" ABC123DEF456
  gh-switch add personal john@gmail.com "Johnny Smith"`,
	Args: cobra.RangeArgs(2, 4),
	RunE: runAdd,
}

func init() {
	rootCmd.AddCommand(addCmd)
}

func runAdd(cmd *cobra.Command, args []string) error {
	profileName := args[0]
	email := args[1]
	gitName := ""
	gpgKey := ""

	if len(args) >= 3 {
		gitName = args[2]
	}
	if len(args) >= 4 {
		gpgKey = args[3]
	}

	// Initialize configuration manager
	configMgr, err := config.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize config manager: %w", err)
	}

	// Load existing configuration
	cfg, err := configMgr.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	// Check if Git is installed
	if err := git.CheckGitInstalled(); err != nil {
		return fmt.Errorf("git is required but not found: %w", err)
	}

	// Create profile
	profile := &config.Profile{
		Name:         profileName,
		Emails:       []string{email},
		PrimaryEmail: email,
		GitName:      gitName,
		GPGKey:       gpgKey,
	}

	// Validate and add profile
	if err := cfg.AddProfile(profile); err != nil {
		return fmt.Errorf("failed to add profile: %w", err)
	}

	// Save configuration
	if err := configMgr.Save(cfg); err != nil {
		return fmt.Errorf("failed to save configuration: %w", err)
	}

	// Setup SSH config entry
	sshMgr, err := ssh.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize SSH manager: %w", err)
	}

	if err := sshMgr.EnsureProfileEntry(profile); err != nil {
		fmt.Printf("Warning: Failed to setup SSH config: %v\n", err)
	} else {
		hostAlias := ssh.GetHostAlias(profileName)
		fmt.Printf("✓ SSH config entry created\n")
		fmt.Printf("  Use this host in git URLs: git@%s:user/repo.git\n", hostAlias)
	}

	// Success message
	fmt.Printf("\n✓ Profile '%s' added successfully!\n", profileName)
	fmt.Printf("  Email: %s\n", email)
	if gitName != "" {
		fmt.Printf("  Git name: %s\n", gitName)
	}
	if gpgKey != "" {
		fmt.Printf("  GPG key: %s\n", gpgKey)
	}

	// Check if SSH key exists
	sshKeyPath := ssh.GetSSHKeyPath(profileName)
	if !ssh.CheckSSHKeyExists(sshKeyPath) {
		fmt.Printf("\n⚠ SSH key not found: %s\n", sshKeyPath)
		fmt.Printf("  Generate one with: ssh-keygen -t ed25519 -f %s -C \"%s\"\n", sshKeyPath, email)
	}

	// Suggest next steps
	fmt.Println("\nNext steps:")
	fmt.Printf("  1. Set up a directory rule: gh-switch auto ~/projects/work %s\n", profileName)
	fmt.Printf("  2. Or switch manually: gh-switch switch %s\n", profileName)

	return nil
}
