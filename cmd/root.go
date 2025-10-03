package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var (
	autoSSH        bool
	skipPrompts    bool
	version        = "2.0.0"
)

var rootCmd = &cobra.Command{
	Use:   "gh-switch",
	Short: "GitHub Account Switcher - Manage multiple Git identities",
	Long: `gh-switch is a modern CLI tool for managing multiple GitHub accounts.

It provides automatic directory-based profile switching using Git's includeIf,
SSH config management with IdentitiesOnly, and GPG signing support.`,
	Version: version,
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.PersistentFlags().BoolVarP(&autoSSH, "auto-ssh", "s", false, "Automatically add SSH key to agent/keychain")
	rootCmd.PersistentFlags().BoolVarP(&skipPrompts, "yes", "y", false, "Skip confirmation prompts")
}
