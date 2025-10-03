//go:build darwin
// +build darwin

package platform

import (
	"fmt"
	"os/exec"
	"strings"
)

// DarwinKeychain implements KeychainManager for macOS
type DarwinKeychain struct{}

// AddKey adds an SSH key to the macOS keychain
func (dk *DarwinKeychain) AddKey(keyPath string) error {
	cmd := exec.Command("ssh-add", "--apple-use-keychain", keyPath)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to add SSH key to keychain: %w\nOutput: %s", err, string(output))
	}
	return nil
}

// IsKeyLoaded checks if an SSH key is loaded in the agent
func (dk *DarwinKeychain) IsKeyLoaded(keyPath string) (bool, error) {
	cmd := exec.Command("ssh-add", "-l")
	output, err := cmd.Output()
	if err != nil {
		// Exit code 1 means no keys loaded, which is not an error
		if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 1 {
			return false, nil
		}
		return false, fmt.Errorf("failed to list SSH keys: %w", err)
	}

	return strings.Contains(string(output), keyPath), nil
}

// ListKeys lists all loaded SSH keys
func (dk *DarwinKeychain) ListKeys() ([]string, error) {
	cmd := exec.Command("ssh-add", "-l")
	output, err := cmd.Output()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 1 {
			return []string{}, nil // No keys loaded
		}
		return nil, fmt.Errorf("failed to list SSH keys: %w", err)
	}

	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	return lines, nil
}
