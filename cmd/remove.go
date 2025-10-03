package cmd

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/calghar/gh-account-switcher/internal/config"
	"github.com/calghar/gh-account-switcher/internal/git"
	"github.com/calghar/gh-account-switcher/internal/ssh"
	"github.com/spf13/cobra"
)

var removeCmd = &cobra.Command{
	Use:   "remove <profile-name>",
	Short: "Remove a profile",
	Long:  `Remove a profile and its associated directory rules.`,
	Args:  cobra.ExactArgs(1),
	RunE:  runRemove,
}

func init() {
	rootCmd.AddCommand(removeCmd)
}

func runRemove(cmd *cobra.Command, args []string) error {
	profileName := args[0]

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

	// Check if profile exists
	profile, err := cfg.GetProfile(profileName)
	if err != nil {
		return fmt.Errorf("profile not found: %w", err)
	}

	// Confirm removal if not skipping prompts
	if !skipPrompts {
		fmt.Printf("Are you sure you want to remove profile '%s'?\n", profileName)
		fmt.Printf("  Email: %s\n", profile.PrimaryEmail)

		// Count associated directory rules
		ruleCount := 0
		for _, rule := range cfg.DirectoryRules {
			if rule.Profile == profileName {
				ruleCount++
			}
		}
		if ruleCount > 0 {
			fmt.Printf("  Associated directory rules: %d\n", ruleCount)
		}

		fmt.Print("\nType 'yes' to confirm: ")
		reader := bufio.NewReader(os.Stdin)
		response, _ := reader.ReadString('\n')
		response = strings.TrimSpace(strings.ToLower(response))

		if response != "yes" {
			fmt.Println("Removal cancelled.")
			return nil
		}
	}

	// Remove profile from configuration
	if err := cfg.RemoveProfile(profileName); err != nil {
		return fmt.Errorf("failed to remove profile: %w", err)
	}

	// Save configuration
	if err := configMgr.Save(cfg); err != nil {
		return fmt.Errorf("failed to save configuration: %w", err)
	}

	// Remove Git configuration
	gitMgr, err := git.NewConfigManager()
	if err == nil {
		if err := gitMgr.RemoveProfileConfig(profileName); err != nil {
			fmt.Printf("Warning: Failed to remove Git config: %v\n", err)
		}
	}

	// Remove SSH configuration
	sshMgr, err := ssh.NewConfigManager()
	if err == nil {
		if err := sshMgr.RemoveProfileEntry(profileName); err != nil {
			fmt.Printf("Warning: Failed to remove SSH config: %v\n", err)
		}
	}

	fmt.Printf("✓ Profile '%s' removed successfully\n", profileName)
	fmt.Println("\nNote: SSH key file and Git includeIf directives were removed.")
	fmt.Println("Your SSH key file (if it exists) was not deleted.")

	return nil
}
