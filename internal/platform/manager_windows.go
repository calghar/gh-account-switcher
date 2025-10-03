//go:build windows
// +build windows

package platform

// GetKeychainManager returns the appropriate keychain manager for Windows
func GetKeychainManager() (KeychainManager, error) {
	return &WindowsKeychain{}, nil
}

// GetPlatformName returns a human-readable platform name
func GetPlatformName() string {
	return "Windows"
}
