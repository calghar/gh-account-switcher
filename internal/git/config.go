package git

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/calghar/gh-account-switcher/internal/config"
)

// ConfigManager manages Git configuration
type ConfigManager struct {
	homeDir string
}

// NewConfigManager creates a new Git configuration manager
func NewConfigManager() (*ConfigManager, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("failed to get home directory: %w", err)
	}

	return &ConfigManager{
		homeDir: homeDir,
	}, nil
}

// SetupProfile creates a profile-specific gitconfig file and sets up includeIf
func (gm *ConfigManager) SetupProfile(profile *config.Profile, directoryPath string) error {
	// Create profile-specific gitconfig file
	profileConfigPath := filepath.Join(gm.homeDir, fmt.Sprintf(".gitconfig-%s", profile.Name))

	var configContent strings.Builder
	configContent.WriteString(fmt.Sprintf("# Git configuration for profile: %s\n", profile.Name))
	configContent.WriteString(fmt.Sprintf("[user]\n"))
	configContent.WriteString(fmt.Sprintf("\temail = %s\n", profile.PrimaryEmail))

	if profile.GitName != "" {
		configContent.WriteString(fmt.Sprintf("\tname = %s\n", profile.GitName))
	}

	// GPG signing configuration
	if profile.GPGKey != "" {
		configContent.WriteString(fmt.Sprintf("\tsigningkey = %s\n", profile.GPGKey))
		configContent.WriteString(fmt.Sprintf("[commit]\n"))
		configContent.WriteString(fmt.Sprintf("\tgpgsign = true\n"))
	}

	// SSH command configuration (if SSH key path is specified)
	if profile.SSHKeyPath != "" {
		configContent.WriteString(fmt.Sprintf("[core]\n"))
		configContent.WriteString(fmt.Sprintf("\tsshCommand = ssh -i %s -F /dev/null\n", profile.SSHKeyPath))
	}

	// Write profile-specific config
	if err := os.WriteFile(profileConfigPath, []byte(configContent.String()), 0600); err != nil {
		return fmt.Errorf("failed to write profile config: %w", err)
	}

	// Add includeIf directive to global gitconfig
	if directoryPath != "" {
		absPath, err := filepath.Abs(directoryPath)
		if err != nil {
			return fmt.Errorf("failed to resolve absolute path: %w", err)
		}

		// Ensure path ends with /
		if !strings.HasSuffix(absPath, "/") {
			absPath += "/"
		}

		// Check if includeIf already exists
		includeIfSection := fmt.Sprintf("includeIf.gitdir:%s.path", absPath)
		existingPath := gm.getGlobalConfig(includeIfSection)

		if existingPath == "" {
			// Add new includeIf directive
			if err := gm.setGlobalConfig(includeIfSection, profileConfigPath); err != nil {
				return fmt.Errorf("failed to set includeIf directive: %w", err)
			}
		} else if existingPath != profileConfigPath {
			// Update existing includeIf directive
			if err := gm.setGlobalConfig(includeIfSection, profileConfigPath); err != nil {
				return fmt.Errorf("failed to update includeIf directive: %w", err)
			}
		}
	}

	return nil
}

// SetupAllProfiles sets up includeIf directives for all directory rules
func (gm *ConfigManager) SetupAllProfiles(cfg *config.Config) error {
	for _, rule := range cfg.DirectoryRules {
		profile, err := cfg.GetProfile(rule.Profile)
		if err != nil {
			return fmt.Errorf("failed to get profile %s: %w", rule.Profile, err)
		}

		if err := gm.SetupProfile(profile, rule.Path); err != nil {
			return fmt.Errorf("failed to setup profile %s: %w", profile.Name, err)
		}
	}

	return nil
}

// SwitchProfile manually switches to a profile globally (for non-directory-based switching)
func (gm *ConfigManager) SwitchProfile(profile *config.Profile) error {
	// Set global user.email
	if err := gm.setGlobalConfig("user.email", profile.PrimaryEmail); err != nil {
		return fmt.Errorf("failed to set email: %w", err)
	}

	// Set global user.name if specified
	if profile.GitName != "" {
		if err := gm.setGlobalConfig("user.name", profile.GitName); err != nil {
			return fmt.Errorf("failed to set name: %w", err)
		}
	}

	// GPG signing
	if profile.GPGKey != "" {
		if err := gm.setGlobalConfig("user.signingkey", profile.GPGKey); err != nil {
			return fmt.Errorf("failed to set GPG key: %w", err)
		}
		if err := gm.setGlobalConfig("commit.gpgsign", "true"); err != nil {
			return fmt.Errorf("failed to enable GPG signing: %w", err)
		}
	} else {
		// Optionally unset GPG signing
		_ = gm.unsetGlobalConfig("commit.gpgsign")
		_ = gm.unsetGlobalConfig("user.signingkey")
	}

	return nil
}

// GetCurrentConfig returns the current git configuration
func (gm *ConfigManager) GetCurrentConfig() (email, name, signingKey string, gpgEnabled bool) {
	email = gm.getGlobalConfig("user.email")
	name = gm.getGlobalConfig("user.name")
	signingKey = gm.getGlobalConfig("user.signingkey")
	gpgSign := gm.getGlobalConfig("commit.gpgsign")
	gpgEnabled = strings.ToLower(gpgSign) == "true"

	return
}

// setGlobalConfig sets a global git configuration value
func (gm *ConfigManager) setGlobalConfig(key, value string) error {
	cmd := exec.Command("git", "config", "--global", key, value)
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("git config failed: %w\n%s", err, string(output))
	}
	return nil
}

// unsetGlobalConfig unsets a global git configuration value
func (gm *ConfigManager) unsetGlobalConfig(key string) error {
	cmd := exec.Command("git", "config", "--global", "--unset", key)
	_ = cmd.Run() // Ignore errors (key might not exist)
	return nil
}

// getGlobalConfig gets a global git configuration value
func (gm *ConfigManager) getGlobalConfig(key string) string {
	cmd := exec.Command("git", "config", "--global", "--get", key)
	output, err := cmd.Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(output))
}

// RemoveProfileConfig removes a profile's gitconfig file and includeIf directives
func (gm *ConfigManager) RemoveProfileConfig(profileName string) error {
	// Remove profile-specific gitconfig file
	profileConfigPath := filepath.Join(gm.homeDir, fmt.Sprintf(".gitconfig-%s", profileName))
	if err := os.Remove(profileConfigPath); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to remove profile config: %w", err)
	}

	// Note: includeIf directives remain in global config but point to non-existent files
	// This is safe and won't cause issues

	return nil
}

// CheckGitInstalled verifies that git is installed
func CheckGitInstalled() error {
	cmd := exec.Command("git", "--version")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("git is not installed or not in PATH")
	}
	return nil
}
