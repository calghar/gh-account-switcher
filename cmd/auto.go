package cmd

import (
	"fmt"
	"os"

	"github.com/calghar/gh-account-switcher/internal/config"
	"github.com/calghar/gh-account-switcher/internal/git"
	"github.com/spf13/cobra"
)

var autoCmd = &cobra.Command{
	Use:   "auto <directory> <profile>",
	Short: "Setup automatic profile switching for a directory",
	Long: `Configure automatic profile switching based on directory location.

This uses Git's includeIf feature to automatically use different profiles
for different project directories.

Examples:
  gh-switch auto ~/projects/work work
  gh-switch auto ~/projects/personal personal`,
	Args: cobra.ExactArgs(2),
	RunE: runAuto,
}

var autoListCmd = &cobra.Command{
	Use:   "auto-list",
	Short: "List all directory rules",
	Long:  `List all configured directory-to-profile mappings.`,
	RunE:  runAutoList,
}

var autoRemoveCmd = &cobra.Command{
	Use:   "auto-remove <directory>",
	Short: "Remove a directory rule",
	Long:  `Remove automatic profile switching for a directory.`,
	Args:  cobra.ExactArgs(1),
	RunE:  runAutoRemove,
}

func init() {
	rootCmd.AddCommand(autoCmd)
	rootCmd.AddCommand(autoListCmd)
	rootCmd.AddCommand(autoRemoveCmd)
}

func runAuto(cmd *cobra.Command, args []string) error {
	directory := args[0]
	profileName := args[1]

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

	// Verify directory exists
	if info, err := os.Stat(directory); err != nil {
		if os.IsNotExist(err) {
			return fmt.Errorf("directory does not exist: %s", directory)
		}
		return fmt.Errorf("failed to check directory: %w", err)
	} else if !info.IsDir() {
		return fmt.Errorf("path is not a directory: %s", directory)
	}

	// Get profile to verify it exists
	profile, err := cfg.GetProfile(profileName)
	if err != nil {
		return fmt.Errorf("profile not found: %w", err)
	}

	// Add directory rule
	if err := cfg.AddDirectoryRule(directory, profileName); err != nil {
		return fmt.Errorf("failed to add directory rule: %w", err)
	}

	// Save configuration
	if err := configMgr.Save(cfg); err != nil {
		return fmt.Errorf("failed to save configuration: %w", err)
	}

	// Setup Git includeIf configuration
	gitMgr, err := git.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize git manager: %w", err)
	}

	if err := gitMgr.SetupProfile(profile, directory); err != nil {
		return fmt.Errorf("failed to setup Git includeIf: %w", err)
	}

	fmt.Printf("✓ Directory rule added successfully!\n")
	fmt.Printf("  Directory: %s\n", directory)
	fmt.Printf("  Profile: %s\n", profileName)
	fmt.Printf("  Email: %s\n", profile.PrimaryEmail)
	fmt.Println("\nGit will now automatically use this profile for repositories in this directory.")
	fmt.Println("Note: This uses Git's includeIf feature, so you don't need to manually switch.")

	return nil
}

func runAutoList(cmd *cobra.Command, args []string) error {
	configMgr, err := config.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize config manager: %w", err)
	}

	cfg, err := configMgr.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	if len(cfg.DirectoryRules) == 0 {
		fmt.Println("No directory rules configured yet.")
		fmt.Println("\nAdd a rule with: gh-switch auto <directory> <profile>")
		return nil
	}

	fmt.Printf("Directory rules (%d):\n\n", len(cfg.DirectoryRules))

	for _, rule := range cfg.DirectoryRules {
		profile, err := cfg.GetProfile(rule.Profile)
		if err != nil {
			fmt.Printf("  %s → %s (profile not found!)\n", rule.Path, rule.Profile)
			continue
		}

		fmt.Printf("  %s\n", rule.Path)
		fmt.Printf("    → Profile: %s\n", rule.Profile)
		fmt.Printf("    → Email: %s\n", profile.PrimaryEmail)
		if profile.GitName != "" {
			fmt.Printf("    → Name: %s\n", profile.GitName)
		}
		fmt.Println()
	}

	return nil
}

func runAutoRemove(cmd *cobra.Command, args []string) error {
	directory := args[0]

	configMgr, err := config.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize config manager: %w", err)
	}

	cfg, err := configMgr.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	// Remove directory rule
	if err := cfg.RemoveDirectoryRule(directory); err != nil {
		return fmt.Errorf("failed to remove directory rule: %w", err)
	}

	// Save configuration
	if err := configMgr.Save(cfg); err != nil {
		return fmt.Errorf("failed to save configuration: %w", err)
	}

	fmt.Printf("✓ Directory rule removed: %s\n", directory)
	fmt.Println("\nNote: The Git includeIf directive remains in your global .gitconfig")
	fmt.Println("but will point to the profile config file which is still available.")

	return nil
}
