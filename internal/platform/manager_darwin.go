//go:build darwin
// +build darwin

package platform

// GetKeychainManager returns the appropriate keychain manager for macOS
func GetKeychainManager() (KeychainManager, error) {
	return &DarwinKeychain{}, nil
}

// GetPlatformName returns a human-readable platform name
func GetPlatformName() string {
	return "macOS"
}
