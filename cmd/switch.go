package cmd

import (
	"fmt"

	"github.com/calghar/gh-account-switcher/internal/config"
	"github.com/calghar/gh-account-switcher/internal/git"
	"github.com/calghar/gh-account-switcher/internal/platform"
	"github.com/calghar/gh-account-switcher/internal/ssh"
	"github.com/spf13/cobra"
)

var switchCmd = &cobra.Command{
	Use:   "switch <profile-name> [email]",
	Short: "Switch to a profile",
	Long: `Switch to the specified profile globally.

This sets the global Git configuration. For automatic switching based on
directory, use 'gh-switch auto' to setup directory rules instead.

Examples:
  gh-switch switch work
  gh-switch --auto-ssh switch work
  gh-switch switch work john.contractor@company.com`,
	Args: cobra.RangeArgs(1, 2),
	RunE: runSwitch,
}

func init() {
	rootCmd.AddCommand(switchCmd)
}

func runSwitch(cmd *cobra.Command, args []string) error {
	profileName := args[0]
	specificEmail := ""
	if len(args) > 1 {
		specificEmail = args[1]
	}

	// Initialize configuration manager
	configMgr, err := config.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize config manager: %w", err)
	}

	// Load configuration
	cfg, err := configMgr.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	// Get profile
	profile, err := cfg.GetProfile(profileName)
	if err != nil {
		return fmt.Errorf("profile not found: %w", err)
	}

	// If specific email is provided, verify it exists in profile
	emailToUse := profile.PrimaryEmail
	if specificEmail != "" {
		found := false
		for _, email := range profile.Emails {
			if email == specificEmail {
				emailToUse = specificEmail
				found = true
				break
			}
		}
		if !found {
			return fmt.Errorf("email '%s' not found in profile '%s'", specificEmail, profileName)
		}
	}

	// Setup Git configuration
	gitMgr, err := git.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize git manager: %w", err)
	}

	// Create a temporary profile with the selected email for switching
	switchProfile := *profile
	switchProfile.PrimaryEmail = emailToUse

	if err := gitMgr.SwitchProfile(&switchProfile); err != nil {
		return fmt.Errorf("failed to switch Git configuration: %w", err)
	}

	// Update current profile in config
	cfg.CurrentProfile = profileName
	if err := configMgr.Save(cfg); err != nil {
		return fmt.Errorf("failed to save configuration: %w", err)
	}

	// Success message
	fmt.Printf("✓ Switched to profile '%s'\n", profileName)
	fmt.Printf("  Email: %s\n", emailToUse)
	if profile.GitName != "" {
		fmt.Printf("  Name: %s\n", profile.GitName)
	}
	if profile.GPGKey != "" {
		fmt.Printf("  GPG signing: enabled\n")
	}

	// Handle SSH key if --auto-ssh flag is set
	if autoSSH {
		sshKeyPath := ssh.GetSSHKeyPath(profileName)

		if !ssh.CheckSSHKeyExists(sshKeyPath) {
			fmt.Printf("\n⚠ SSH key not found: %s\n", sshKeyPath)
			fmt.Printf("  Generate one with: ssh-keygen -t ed25519 -f %s -C \"%s\"\n", sshKeyPath, emailToUse)
		} else {
			// Get platform-specific keychain manager
			keychainMgr, err := platform.GetKeychainManager()
			if err != nil {
				return fmt.Errorf("failed to get keychain manager: %w", err)
			}

			// Check if key is already loaded
			loaded, err := keychainMgr.IsKeyLoaded(sshKeyPath)
			if err != nil {
				fmt.Printf("\n⚠ Warning: Failed to check SSH key status: %v\n", err)
			} else if loaded {
				fmt.Printf("\n✓ SSH key already loaded\n")
			} else {
				// Add key to keychain/agent
				fmt.Printf("\nAdding SSH key to %s...\n", platform.GetPlatformName())
				if err := keychainMgr.AddKey(sshKeyPath); err != nil {
					fmt.Printf("⚠ Warning: Failed to add SSH key: %v\n", err)
					fmt.Printf("  You may need to run: ssh-add %s\n", sshKeyPath)
				} else {
					fmt.Printf("✓ SSH key added successfully\n")
				}
			}

			// Show SSH host alias
			hostAlias := ssh.GetHostAlias(profileName)
			fmt.Printf("  Use this host in git URLs: git@%s:user/repo.git\n", hostAlias)
		}
	} else {
		// Suggest SSH key setup
		sshKeyPath := ssh.GetSSHKeyPath(profileName)
		if ssh.CheckSSHKeyExists(sshKeyPath) {
			fmt.Printf("\nSSH key available: %s\n", sshKeyPath)
			fmt.Printf("  Add with: gh-switch --auto-ssh switch %s\n", profileName)
			hostAlias := ssh.GetHostAlias(profileName)
			fmt.Printf("  Use this host in git URLs: git@%s:user/repo.git\n", hostAlias)
		}
	}

	return nil
}
