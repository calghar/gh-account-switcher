package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"github.com/calghar/gh-account-switcher/internal/config"
	"github.com/spf13/cobra"
)

var exportCmd = &cobra.Command{
	Use:   "export [file]",
	Short: "Export profiles to a file",
	Long: `Export all profiles to a JSON file or stdout.

Examples:
  gh-switch export                      # Print to stdout
  gh-switch export my-profiles.json     # Export to file`,
	Args: cobra.MaximumNArgs(1),
	RunE: runExport,
}

var importCmd = &cobra.Command{
	Use:   "import <file>",
	Short: "Import profiles from a file",
	Long:  `Import profiles from a JSON file.`,
	Args:  cobra.ExactArgs(1),
	RunE:  runImport,
}

func init() {
	rootCmd.AddCommand(exportCmd)
	rootCmd.AddCommand(importCmd)
}

func runExport(cmd *cobra.Command, args []string) error {
	configMgr, err := config.NewConfigManager()
	if err != nil {
		return fmt.Errorf("failed to initialize config manager: %w", err)
	}

	cfg, err := configMgr.Load()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	// Marshal to JSON
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal configuration: %w", err)
	}

	// Output to file or stdout
	if len(args) > 0 {
		filename := args[0]
		if err := os.WriteFile(filename, data, 0600); err != nil {
			return fmt.Errorf("failed to write export file: %w", err)
		}
		fmt.Printf("✓ Profiles exported to: %s\n", filename)
	} else {
		fmt.Println(string(data))
	}

	return nil
}

func runImport(cmd *cobra.Command, args []string) error {
	filename := args[0]

	// Read import file
	data, err := os.ReadFile(filename)
	if err != nil {
		return fmt.Errorf("failed to read import file: %w", err)
	}

	// Parse JSON
	var importedCfg config.Config
	if err := json.Unmarshal(data, &importedCfg); err != nil {
		return fmt.Errorf("failed to parse import file: %w", err)
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

	// Merge profiles
	conflictCount := 0
	newCount := 0
	for name, profile := range importedCfg.Profiles {
		if _, exists := cfg.Profiles[name]; exists {
			conflictCount++
			if !skipPrompts {
				fmt.Printf("Profile '%s' already exists. Overwrite? (y/N): ", name)
				var response string
				fmt.Scanln(&response)
				if strings.ToLower(response) != "y" {
					fmt.Printf("  Skipped: %s\n", name)
					continue
				}
			}
		} else {
			newCount++
		}

		// Validate profile
		if err := profile.Validate(); err != nil {
			fmt.Printf("Warning: Skipping invalid profile '%s': %v\n", name, err)
			continue
		}

		cfg.Profiles[name] = profile
	}

	// Merge directory rules
	for _, rule := range importedCfg.DirectoryRules {
		// Check if rule already exists
		exists := false
		for i, existingRule := range cfg.DirectoryRules {
			if existingRule.Path == rule.Path {
				cfg.DirectoryRules[i] = rule
				exists = true
				break
			}
		}
		if !exists {
			cfg.DirectoryRules = append(cfg.DirectoryRules, rule)
		}
	}

	// Save configuration
	if err := configMgr.Save(cfg); err != nil {
		return fmt.Errorf("failed to save configuration: %w", err)
	}

	fmt.Printf("✓ Import completed!\n")
	fmt.Printf("  New profiles: %d\n", newCount)
	if conflictCount > 0 {
		fmt.Printf("  Conflicts handled: %d\n", conflictCount)
	}

	return nil
}
