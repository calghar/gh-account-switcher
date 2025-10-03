.PHONY: build install clean test lint help

BINARY_NAME=gh-switch
VERSION?=2.0.0
BUILD_DIR=dist
GO=go
GOFLAGS=-ldflags="-s -w -X github.com/calghar/gh-account-switcher/cmd.version=$(VERSION)"

## help: Show this help message
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

## build: Build the binary for current platform
build:
	@echo "Building $(BINARY_NAME) v$(VERSION)..."
	$(GO) build $(GOFLAGS) -o $(BINARY_NAME) .
	@echo "Build complete: ./$(BINARY_NAME)"

## build-all: Build binaries for all platforms
build-all:
	@echo "Building for all platforms..."
	@mkdir -p $(BUILD_DIR)
	GOOS=darwin GOARCH=amd64 $(GO) build $(GOFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64 .
	GOOS=darwin GOARCH=arm64 $(GO) build $(GOFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64 .
	GOOS=linux GOARCH=amd64 $(GO) build $(GOFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 .
	GOOS=linux GOARCH=arm64 $(GO) build $(GOFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-arm64 .
	GOOS=windows GOARCH=amd64 $(GO) build $(GOFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe .
	@echo "All builds complete in $(BUILD_DIR)/"

## install: Install the binary to ~/bin
install: build
	@echo "Installing $(BINARY_NAME) to ~/bin..."
	@mkdir -p ~/bin
	@cp $(BINARY_NAME) ~/bin/$(BINARY_NAME)
	@chmod +x ~/bin/$(BINARY_NAME)
	@echo "Installed to ~/bin/$(BINARY_NAME)"
	@echo "Make sure ~/bin is in your PATH"

## test: Run tests
test:
	$(GO) test -v -race -coverprofile=coverage.out ./...

## lint: Run golangci-lint
lint:
	@which golangci-lint > /dev/null || (echo "golangci-lint not found, install from https://golangci-lint.run/" && exit 1)
	golangci-lint run ./...

## clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -f $(BINARY_NAME)
	@rm -rf $(BUILD_DIR)
	@rm -f coverage.out
	@echo "Clean complete"

## deps: Download dependencies
deps:
	$(GO) mod download
	$(GO) mod tidy

## fmt: Format code
fmt:
	$(GO) fmt ./...
	gofmt -s -w .

.DEFAULT_GOAL := help
