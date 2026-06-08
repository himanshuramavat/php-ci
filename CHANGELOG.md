# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- (none)

### Fixed

- (none)

## [1.3.0] - 2026-06-06

### Added

- `scripts/verify-image.sh` for shared runtime validation across Dockerfile, CI, and local testing.
- PostgreSQL and Redis runtime smoke tests in GitHub CI.
- weekly rebuild workflow for rolling tags.
- Dependabot configuration for GitHub Actions and Docker updates.

### Fixed

- corrected branch references and CI badge links for `master`.
- added top-level `test-local.sh` wrapper to mirror docs and simplify local execution.

## [1.2.0] - 2026-05-29

### Added

- See GitHub release notes for details.

## [1.1.0] - 2026-05-25

### Added

- Enhance PHP CI image with additional database and image extensions.

## [1.0.0] - 2026-05-22

### Added

- Initial release and baseline features (Composer, PostgreSQL, SQLite, Redis, GD).
