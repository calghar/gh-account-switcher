# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed
- Fixed directory rules matching sibling folders: a rule for `~/work` no longer applies to `~/work2`

## [1.1.0] - 2026-11-13

### Fixed
- Fixed `github.com-<profile>` aliases failing in directory-rule folders: the generated `sshCommand` now uses `-o IdentitiesOnly=yes` instead of `-F /dev/null`

### Changed
- Changed `gh-switch switch` output to say only git identity changed and remotes need the SSH host alias

## [1.0.0] - 2026-03-18

### Added
- Added Go rewrite with `includeIf` directory switching, per-profile `.gitconfig-<profile>` files, and GPG signing per profile
- Added automatic SSH key loading and `github.com-<profile>` host aliases with `IdentitiesOnly yes`
- Added multiple emails per profile and multi-account management

### Changed
- Changed the docs to explain why SSH host aliases are required
