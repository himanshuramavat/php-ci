# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

- (none)

## [1.5.0] - 2026-06-27

### Added

- Opt-in **`8.4-deploy`** image variant (`Dockerfile` `deploy` target) with `rsync` and
  `openssh-client` for TYPO3/PHP deploy pipelines; published on release and weekly rebuild.
- `scripts/verify-deploy-image.sh` — fail-fast validation for the deploy variant.
- Contributor Covenant Code of Conduct.
- Architecture, CI workflow, and project context documentation.

### Changed

- Bumped Composer from 2.8 to 2.10.
- Refreshed GitHub Actions dependency group.
- Added optional deploy image variant documentation across README, Docker Hub description,
  examples, and contributing docs.

## [1.4.0] - 2026-06-10

### Added

- Trivy image vulnerability scan in CI (CRITICAL/HIGH, ignore-unfixed) via reusable composite
  action `.github/actions/trivy-image-scan`, with `.trivyignore` suppressing non-exploitable
  `linux-libc-dev` kernel-header CVEs.
- CodeQL code scanning (GitHub default setup) for the Actions workflows.
- GD functional smoke test (truecolor + PNG/WebP/JPEG) and MySQL/MariaDB PDO smoke test in CI
  and local runner.
- Hadolint Dockerfile lint job (`.hadolint.yaml`).
- Image-size reporting per PHP version in CI (warns past a soft limit).
- `linux/arm64` to published + weekly-rebuild manifests (multi-arch via QEMU).
- Build provenance and SBOM on publish.
- Cosign keyless signing of published image digests; verification documented in `SECURITY.md`.
- `EXTRA_EXTENSIONS` and `RUN_USER` build args for opt-in extra extensions and non-root images.
- Informational `HEALTHCHECK` (php -v) on the final image.
- Optional TYPO3 Testing Framework integration check (SQLite) in CI.
- `SECURITY.md`, `CONTRIBUTING.md`, label taxonomy (`.github/labels.yml`) with auto-sync
  workflow, and a README "Using this image from another org / CI" section.

### Changed

- Pinned Composer to `composer:2.8` (was rolling `composer:2`) for reproducible builds.
- Docs/examples now use `<php>-v<LATEST>` placeholders linking to Releases instead of hard
  immutable tags, to prevent drift.

### Fixed

- weekly-rebuild workflow now publishes rolling tags (incl. `latest` for the highest PHP)
  via `docker/metadata-action`; previously invalid `type=raw,...` strings were passed as
  literal tags.

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
