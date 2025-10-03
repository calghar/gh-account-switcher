//go:build linux
// +build linux

package platform

// GetKeychainManager returns the appropriate keychain manager for Linux
func GetKeychainManager() (KeychainManager, error) {
	return &LinuxKeychain{}, nil
}

// GetPlatformName returns a human-readable platform name
func GetPlatformName() string {
	return "Linux"
}
