package ssh

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/calghar/gh-account-switcher/internal/config"
)

// ConfigManager manages SSH configuration
type ConfigManager struct {
	sshConfigPath string
	homeDir       string
}

// NewConfigManager creates a new SSH configuration manager
func NewConfigManager() (*ConfigManager, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("failed to get home directory: %w", err)
	}

	sshDir := filepath.Join(homeDir, ".ssh")
	sshConfigPath := filepath.Join(sshDir, "config")

	// Create .ssh directory if it doesn't exist
	if err := os.MkdirAll(sshDir, 0700); err != nil {
		return nil, fmt.Errorf("failed to create .ssh directory: %w", err)
	}

	return &ConfigManager{
		sshConfigPath: sshConfigPath,
		homeDir:       homeDir,
	}, nil
}

// EnsureProfileEntry ensures an SSH config entry exists for a profile
func (sm *ConfigManager) EnsureProfileEntry(profile *config.Profile) error {
	hostAlias := fmt.Sprintf("github.com-%s", profile.Name)
	sshKeyFile := filepath.Join(sm.homeDir, ".ssh", fmt.Sprintf("id_%s", profile.Name))

	// Update profile's SSH key path if not set
	if profile.SSHKeyPath == "" {
		profile.SSHKeyPath = sshKeyFile
	}

	// Check if entry already exists
	if sm.entryExists(hostAlias) {
		return nil
	}

	// Create config file if it doesn't exist
	if _, err := os.Stat(sm.sshConfigPath); os.IsNotExist(err) {
		if err := os.WriteFile(sm.sshConfigPath, []byte{}, 0600); err != nil {
			return fmt.Errorf("failed to create SSH config: %w", err)
		}
	}

	// Append new entry
	entry := fmt.Sprintf(`
# GitHub profile: %s
Host %s
    HostName github.com
    User git
    IdentityFile %s
    IdentitiesOnly yes
`, profile.Name, hostAlias, sshKeyFile)

	file, err := os.OpenFile(sm.sshConfigPath, os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		return fmt.Errorf("failed to open SSH config: %w", err)
	}
	defer file.Close()

	if _, err := file.WriteString(entry); err != nil {
		return fmt.Errorf("failed to write SSH config entry: %w", err)
	}

	return nil
}

// entryExists checks if an SSH config entry already exists for a host
func (sm *ConfigManager) entryExists(hostAlias string) bool {
	file, err := os.Open(sm.sshConfigPath)
	if err != nil {
		return false
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, "Host ") && strings.Contains(line, hostAlias) {
			return true
		}
	}

	return false
}

// RemoveProfileEntry removes an SSH config entry for a profile
func (sm *ConfigManager) RemoveProfileEntry(profileName string) error {
	hostAlias := fmt.Sprintf("github.com-%s", profileName)

	file, err := os.Open(sm.sshConfigPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil // No config file, nothing to remove
		}
		return fmt.Errorf("failed to open SSH config: %w", err)
	}
	defer file.Close()

	var newLines []string
	scanner := bufio.NewScanner(file)
	inTargetEntry := false
	skipNext := false

	for scanner.Scan() {
		line := scanner.Text()
		trimmed := strings.TrimSpace(line)

		// Check for comment marking profile start
		if strings.HasPrefix(trimmed, "#") && strings.Contains(trimmed, fmt.Sprintf("GitHub profile: %s", profileName)) {
			skipNext = true
			continue
		}

		// Check for Host directive
		if strings.HasPrefix(trimmed, "Host ") {
			if strings.Contains(trimmed, hostAlias) {
				inTargetEntry = true
				continue
			} else {
				inTargetEntry = false
				skipNext = false
			}
		}

		// Skip lines that are part of target entry or marked to skip
		if inTargetEntry || skipNext {
			// If we hit a new Host or non-indented line, stop skipping
			if strings.HasPrefix(trimmed, "Host ") || (trimmed != "" && !strings.HasPrefix(line, " ") && !strings.HasPrefix(line, "\t")) {
				inTargetEntry = false
				skipNext = false
				newLines = append(newLines, line)
			}
			continue
		}

		newLines = append(newLines, line)
	}

	if err := scanner.Err(); err != nil {
		return fmt.Errorf("failed to read SSH config: %w", err)
	}

	// Write updated config
	content := strings.Join(newLines, "\n")
	if err := os.WriteFile(sm.sshConfigPath, []byte(content), 0600); err != nil {
		return fmt.Errorf("failed to write SSH config: %w", err)
	}

	return nil
}

// GetHostAlias returns the SSH host alias for a profile
func GetHostAlias(profileName string) string {
	return fmt.Sprintf("github.com-%s", profileName)
}

// GetSSHKeyPath returns the default SSH key path for a profile
func GetSSHKeyPath(profileName string) string {
	homeDir, _ := os.UserHomeDir()
	return filepath.Join(homeDir, ".ssh", fmt.Sprintf("id_%s", profileName))
}

// CheckSSHKeyExists checks if an SSH key file exists for a profile
func CheckSSHKeyExists(keyPath string) bool {
	_, err := os.Stat(keyPath)
	return err == nil
}
