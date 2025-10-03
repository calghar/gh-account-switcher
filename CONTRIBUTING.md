# Contributing

## Setup

```bash
git clone https://github.com/calghar/gh-account-switcher.git
cd gh-account-switcher
make deps
make build
```

## Development

```bash
make build      # Build binary
make test       # Run tests
make fmt        # Format code
make lint       # Run linter
```

## Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make changes with clear commits
4. Run `make test && make lint`
5. Submit PR with description

## Code Standards

- Follow Go idioms and conventions
- Add tests for new features
- Update docs for user-facing changes
- Keep functions small and focused
- Use descriptive variable names

## Project Structure

```
cmd/              # CLI commands
internal/config/  # Profile management
internal/git/     # Git configuration
internal/ssh/     # SSH configuration
internal/platform/# Platform-specific code
```

## Testing

```bash
go test -v ./...
go test -race ./...
go test -coverprofile=coverage.out ./...
```

## Building

```bash
make build          # Current platform
make build-all      # All platforms
```

## Questions

Open an issue or start a discussion.
