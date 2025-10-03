package cmd

import (
	"fmt"
	"strings"

	"github.com/calghar/gh-account-switcher/internal/config"
	"github.com/calghar/gh-account-switcher/internal/git"
	"github.com/calghar/gh-account-switcher/internal/ssh"
	"github.com/spf13/cobra"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all profiles",
	Long:  `List all configured GitHub profiles with their details.`,
	RunE:  runList,
}

var currentCmd = &cobra.Command{
	Use:   "current",
	Short: "Show current profile",
	Long:  `Show the currently active profile and Git configuration.`,
	RunE:  runCurrent,
}

func init() {
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(currentCmd)
}

func runList(cmd *cobra.Command, args []string) error {
	configMgr, err := config.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize config manager: %w", err)
	}

	cfg, err := configMgr.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	if len(cfg.Profiles) == 0 {
		fmt.Println("No profiles configured yet.")
		fmt.Println("\nAdd a profile with: gh-switch add <name> <email>")
		return nil
	}

	fmt.Printf("Configured profiles (%d):\n\n", len(cfg.Profiles))

	for name, profile := range cfg.Profiles {
		marker := "  "
		if name == cfg.CurrentProfile {
			marker = "▶ "
		}

		fmt.Printf("%s%s\n", marker, name)
		fmt.Printf("    Primary email: %s\n", profile.PrimaryEmail)

		if len(profile.Emails) > 1 {
			otherEmails := []string{}
			for _, email := range profile.Emails {
				if email != profile.PrimaryEmail {
					otherEmails = append(otherEmails, email)
				}
			}
			if len(otherEmails) > 0 {
				fmt.Printf("    Other emails: %s\n", strings.Join(otherEmails, ", "))
			}
		}

		if profile.GitName != "" {
			fmt.Printf("    Git name: %s\n", profile.GitName)
		}

		if profile.GPGKey != "" {
			fmt.Printf("    GPG key: %s\n", profile.GPGKey)
		}

		// Check SSH key status
		sshKeyPath := ssh.GetSSHKeyPath(name)
		if ssh.CheckSSHKeyExists(sshKeyPath) {
			fmt.Printf("    SSH key: %s ✓\n", sshKeyPath)
		} else {
			fmt.Printf("    SSH key: %s (not found)\n", sshKeyPath)
		}

		fmt.Println()
	}

	// Show directory rules
	if len(cfg.DirectoryRules) > 0 {
		fmt.Println("Directory rules:")
		for _, rule := range cfg.DirectoryRules {
			fmt.Printf("  %s → %s\n", rule.Path, rule.Profile)
		}
	}

	return nil
}

func runCurrent(cmd *cobra.Command, args []string) error {
	configMgr, err := config.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize config manager: %w", err)
	}

	cfg, err := configMgr.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	// Get Git configuration
	gitMgr, err := git.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize git manager: %w", err)
	}

	email, name, signingKey, gpgEnabled := gitMgr.GetCurrentConfig()

	fmt.Println("Current Git configuration:")
	fmt.Printf("  Email: %s\n", email)
	if name != "" {
		fmt.Printf("  Name: %s\n", name)
	}
	if gpgEnabled && signingKey != "" {
		fmt.Printf("  GPG signing: enabled (key: %s)\n", signingKey)
	} else {
		fmt.Printf("  GPG signing: disabled\n")
	}

	// Try to find matching profile
	if cfg.CurrentProfile != "" {
		profile, err := cfg.GetProfile(cfg.CurrentProfile)
		if err == nil {
			fmt.Printf("\nActive profile: %s\n", cfg.CurrentProfile)
			fmt.Printf("  Primary email: %s\n", profile.PrimaryEmail)

			// Check if config matches profile
			if email != profile.PrimaryEmail {
				fmt.Printf("\n⚠ Warning: Git config email doesn't match profile email\n")
			}
		}
	} else {
		// Try to find profile by email
		for profileName, profile := range cfg.Profiles {
			if profile.PrimaryEmail == email {
				fmt.Printf("\nMatching profile: %s\n", profileName)
				break
			}
		}
	}

	return nil
}
