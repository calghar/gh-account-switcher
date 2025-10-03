package platform

// KeychainManager defines the interface for platform-specific SSH key management
type KeychainManager interface {
	AddKey(keyPath string) error
	IsKeyLoaded(keyPath string) (bool, error)
	ListKeys() ([]string, error)
}
