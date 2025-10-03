package cmd

import (
	"fmt"

	"github.com/calghar/gh-account-switcher/internal/config"
	"github.com/spf13/cobra"
)

var addEmailCmd = &cobra.Command{
	Use:   "add-email <profile> <email>",
	Short: "Add an email to a profile",
	Args:  cobra.ExactArgs(2),
	RunE:  runAddEmail,
}

var removeEmailCmd = &cobra.Command{
	Use:   "remove-email <profile> <email>",
	Short: "Remove an email from a profile",
	Args:  cobra.ExactArgs(2),
	RunE:  runRemoveEmail,
}

var listEmailsCmd = &cobra.Command{
	Use:   "list-emails <profile>",
	Short: "List all emails for a profile",
	Args:  cobra.ExactArgs(1),
	RunE:  runListEmails,
}

func init() {
	rootCmd.AddCommand(addEmailCmd)
	rootCmd.AddCommand(removeEmailCmd)
	rootCmd.AddCommand(listEmailsCmd)
}

func runAddEmail(cmd *cobra.Command, args []string) error {
	profileName := args[0]
	email := args[1]

	configMgr, err := config.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize config manager: %w", err)
	}

	cfg, err := configMgr.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	if err := cfg.AddEmail(profileName, email); err != nil {
		return err
	}

	if err := configMgr.Save(cfg); err != nil {
		return fmt.Errorf("failed to save configuration: %w", err)
	}

	fmt.Printf("✓ Added email '%s' to profile '%s'\n", email, profileName)
	return nil
}

func runRemoveEmail(cmd *cobra.Command, args []string) error {
	profileName := args[0]
	email := args[1]

	configMgr, err := config.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize config manager: %w", err)
	}

	cfg, err := configMgr.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	if err := cfg.RemoveEmail(profileName, email); err != nil {
		return err
	}

	if err := configMgr.Save(cfg); err != nil {
		return fmt.Errorf("failed to save configuration: %w", err)
	}

	fmt.Printf("✓ Removed email '%s' from profile '%s'\n", email, profileName)
	return nil
}

func runListEmails(cmd *cobra.Command, args []string) error {
	profileName := args[0]

	configMgr, err := config.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize config manager: %w", err)
	}

	cfg, err := configMgr.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	profile, err := cfg.GetProfile(profileName)
	if err != nil {
		return err
	}

	fmt.Printf("Emails for profile '%s':\n", profileName)
	for _, email := range profile.Emails {
		marker := "  "
		if email == profile.PrimaryEmail {
			marker = "▶ "
		}
		fmt.Printf("%s%s\n", marker, email)
	}

	return nil
}
