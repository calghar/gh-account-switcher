package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
)

// Profile represents a GitHub account profile
type Profile struct {
	Name         string   `json:"name"`
	Emails       []string `json:"emails"`
	PrimaryEmail string   `json:"primary_email"`
	GitName      string   `json:"git_name,omitempty"`
	GPGKey       string   `json:"gpg_key,omitempty"`
	SSHKeyPath   string   `json:"ssh_key_path,omitempty"`
}

// DirectoryRule represents a directory-to-profile mapping
type DirectoryRule struct {
	Path    string `json:"path"`
	Profile string `json:"profile"`
}

// Config represents the application configuration
type Config struct {
	Profiles       map[string]*Profile `json:"profiles"`
	DirectoryRules []DirectoryRule     `json:"directory_rules"`
	CurrentProfile string              `json:"current_profile"`
}

// ConfigManager handles configuration persistence
type ConfigManager struct {
	configDir  string
	configFile string
}

// NewConfigManager creates a new configuration manager
func NewConfigManager() (*ConfigManager, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("failed to get home directory: %w", err)
	}

	configDir := filepath.Join(homeDir, ".github-switcher")
	configFile := filepath.Join(configDir, "config.json")

	// Create config directory if it doesn't exist
	if err := os.MkdirAll(configDir, 0700); err != nil {
		return nil, fmt.Errorf("failed to create config directory: %w", err)
	}

	return &ConfigManager{
		configDir:  configDir,
		configFile: configFile,
	}, nil
}

// Load reads the configuration from disk
func (cm *ConfigManager) Load() (*Config, error) {
	// If config file doesn't exist, return empty config
	if _, err := os.Stat(cm.configFile); os.IsNotExist(err) {
		return &Config{
			Profiles:       make(map[string]*Profile),
			DirectoryRules: []DirectoryRule{},
		}, nil
	}

	data, err := os.ReadFile(cm.configFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var config Config
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	// Initialize profiles map if nil
	if config.Profiles == nil {
		config.Profiles = make(map[string]*Profile)
	}

	return &config, nil
}

// Save writes the configuration to disk
func (cm *ConfigManager) Save(config *Config) error {
	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	if err := os.WriteFile(cm.configFile, data, 0600); err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}

	return nil
}

// Validate validates a profile
func (p *Profile) Validate() error {
	if p.Name == "" {
		return fmt.Errorf("profile name cannot be empty")
	}

	if p.PrimaryEmail == "" {
		return fmt.Errorf("primary email cannot be empty")
	}

	if !isValidEmail(p.PrimaryEmail) {
		return fmt.Errorf("invalid email format: %s", p.PrimaryEmail)
	}

	// Validate all emails
	for _, email := range p.Emails {
		if !isValidEmail(email) {
			return fmt.Errorf("invalid email format: %s", email)
		}
	}

	// Validate GPG key format if provided
	if p.GPGKey != "" && !isValidGPGKey(p.GPGKey) {
		return fmt.Errorf("invalid GPG key format: %s (expected 8+ hexadecimal characters)", p.GPGKey)
	}

	return nil
}

// isValidEmail validates email format
func isValidEmail(email string) bool {
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	return emailRegex.MatchString(email)
}

// isValidGPGKey validates GPG key format
func isValidGPGKey(key string) bool {
	gpgKeyRegex := regexp.MustCompile(`^[A-F0-9]{8,}$`)
	return gpgKeyRegex.MatchString(key)
}

// AddProfile adds or updates a profile
func (c *Config) AddProfile(profile *Profile) error {
	if err := profile.Validate(); err != nil {
		return err
	}

	// Ensure emails list contains primary email
	found := false
	for _, email := range profile.Emails {
		if email == profile.PrimaryEmail {
			found = true
			break
		}
	}
	if !found {
		profile.Emails = append([]string{profile.PrimaryEmail}, profile.Emails...)
	}

	c.Profiles[profile.Name] = profile
	return nil
}

// GetProfile retrieves a profile by name
func (c *Config) GetProfile(name string) (*Profile, error) {
	profile, exists := c.Profiles[name]
	if !exists {
		return nil, fmt.Errorf("profile '%s' not found", name)
	}
	return profile, nil
}

// RemoveProfile removes a profile by name
func (c *Config) RemoveProfile(name string) error {
	if _, exists := c.Profiles[name]; !exists {
		return fmt.Errorf("profile '%s' not found", name)
	}

	delete(c.Profiles, name)

	// Remove associated directory rules
	var updatedRules []DirectoryRule
	for _, rule := range c.DirectoryRules {
		if rule.Profile != name {
			updatedRules = append(updatedRules, rule)
		}
	}
	c.DirectoryRules = updatedRules

	// Clear current profile if it's the one being removed
	if c.CurrentProfile == name {
		c.CurrentProfile = ""
	}

	return nil
}

// AddEmail adds an email to a profile
func (c *Config) AddEmail(profileName, email string) error {
	profile, err := c.GetProfile(profileName)
	if err != nil {
		return err
	}

	if !isValidEmail(email) {
		return fmt.Errorf("invalid email format: %s", email)
	}

	// Check if email already exists
	for _, e := range profile.Emails {
		if e == email {
			return fmt.Errorf("email '%s' already exists in profile '%s'", email, profileName)
		}
	}

	profile.Emails = append(profile.Emails, email)
	return nil
}

// RemoveEmail removes an email from a profile
func (c *Config) RemoveEmail(profileName, email string) error {
	profile, err := c.GetProfile(profileName)
	if err != nil {
		return err
	}

	if email == profile.PrimaryEmail {
		return fmt.Errorf("cannot remove primary email; set a different primary email first")
	}

	var updatedEmails []string
	found := false
	for _, e := range profile.Emails {
		if e != email {
			updatedEmails = append(updatedEmails, e)
		} else {
			found = true
		}
	}

	if !found {
		return fmt.Errorf("email '%s' not found in profile '%s'", email, profileName)
	}

	profile.Emails = updatedEmails
	return nil
}

// AddDirectoryRule adds a directory-to-profile mapping
func (c *Config) AddDirectoryRule(path, profileName string) error {
	if _, err := c.GetProfile(profileName); err != nil {
		return err
	}

	// Convert to absolute path
	absPath, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("failed to resolve absolute path: %w", err)
	}

	// Check if rule already exists and update it
	for i, rule := range c.DirectoryRules {
		if rule.Path == absPath {
			c.DirectoryRules[i].Profile = profileName
			return nil
		}
	}

	// Add new rule
	c.DirectoryRules = append(c.DirectoryRules, DirectoryRule{
		Path:    absPath,
		Profile: profileName,
	})

	return nil
}

// RemoveDirectoryRule removes a directory rule
func (c *Config) RemoveDirectoryRule(path string) error {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("failed to resolve absolute path: %w", err)
	}

	var updatedRules []DirectoryRule
	found := false
	for _, rule := range c.DirectoryRules {
		if rule.Path != absPath {
			updatedRules = append(updatedRules, rule)
		} else {
			found = true
		}
	}

	if !found {
		return fmt.Errorf("directory rule for '%s' not found", absPath)
	}

	c.DirectoryRules = updatedRules
	return nil
}

// GetProfileForDirectory returns the profile name for a given directory
func (c *Config) GetProfileForDirectory(dir string) (string, error) {
	absDir, err := filepath.Abs(dir)
	if err != nil {
		return "", fmt.Errorf("failed to resolve absolute path: %w", err)
	}

	// Check for exact match first
	for _, rule := range c.DirectoryRules {
		if rule.Path == absDir {
			return rule.Profile, nil
		}
	}

	// Check for parent directory matches (longest match wins)
	bestMatch := ""
	bestLength := 0

	for _, rule := range c.DirectoryRules {
		if len(rule.Path) > bestLength && filepath.HasPrefix(absDir, rule.Path) {
			bestMatch = rule.Profile
			bestLength = len(rule.Path)
		}
	}

	if bestMatch != "" {
		return bestMatch, nil
	}

	return "", fmt.Errorf("no profile configured for directory: %s", absDir)
}
