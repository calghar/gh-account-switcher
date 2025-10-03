//go:build windows
// +build windows

package platform

import (
	"fmt"
	"os/exec"
	"strings"
)

// WindowsKeychain implements KeychainManager for Windows
type WindowsKeychain struct{}

// AddKey adds an SSH key to the SSH agent on Windows
func (wk *WindowsKeychain) AddKey(keyPath string) error {
	cmd := exec.Command("ssh-add", keyPath)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to add SSH key to agent: %w\nOutput: %s", err, string(output))
	}
	return nil
}

// IsKeyLoaded checks if an SSH key is loaded in the agent
func (wk *WindowsKeychain) IsKeyLoaded(keyPath string) (bool, error) {
	cmd := exec.Command("ssh-add", "-l")
	output, err := cmd.Output()
	if err != nil {
		// Exit code 1 means no keys loaded, which is not an error
		if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 1 {
			return false, nil
		}
		return false, fmt.Errorf("failed to list SSH keys: %w", err)
	}

	// Convert Windows path separators for comparison
	normalizedKeyPath := strings.ReplaceAll(keyPath, "\\", "/")
	normalizedOutput := strings.ReplaceAll(string(output), "\\", "/")

	return strings.Contains(normalizedOutput, normalizedKeyPath), nil
}

// ListKeys lists all loaded SSH keys
func (wk *WindowsKeychain) ListKeys() ([]string, error) {
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
