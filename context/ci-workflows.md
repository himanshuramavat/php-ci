# php-ci — CI Workflows

All workflows live in `.github/workflows/`. Reusable composite action: `.github/actions/trivy-image-scan/`.

---

## test-php-ci.yml

**Triggers:** push to `master` / `feature/*`, PRs to `master`

### Job: `lint-dockerfile`

- hadolint on `Dockerfile` with `.hadolint.yaml`

### Job: `build-and-test` (matrix)

- PHP: `8.4`, `8.3`, `8.2`, `8.1` (fail-fast: false)
- Build with Buildx, load locally, GHA cache per PHP version
- Report image size (warn if > 550 MB)
- Trivy scan via composite action
- Start sidecar network `phpci-test` with PostgreSQL 16, MariaDB 11, Redis 7
- Run `verify-image.sh` inside built image
- Smoke tests: SQLite PDO, GD, PostgreSQL PDO, MySQL PDO, Redis extension
- Verify Composer, git, jq, `/builds` exists
- Composer install smoke (minimal `composer.json` in workspace mount)
- TYPO3 Testing Framework boot check (8.4 only, `continue-on-error: true`)
- Tear down sidecars (`if: always()`)

### Job: `build-and-test-deploy`

- Build `--target deploy`, tag `php-ci:test-8.4-deploy`
- Trivy + `verify-deploy-image.sh` + rsync/ssh version checks

**Publishing:** this workflow does **not** push images.

---

## publish-php-ci.yml

**Triggers:** push tag `v*`, or `workflow_dispatch` (manual version + PHP list)

**Permissions:** `packages: write`, `id-token: write` (cosign OIDC)

### Job: `resolve-version`

- Tag push → version from `refs/tags/v*` (strip `v`)
- Manual → `image_version` input
- PHP matrix from input or default `8.4,8.3,8.2,8.1` (sorted desc for `latest` logic)

### Job: `build-and-push` (matrix per PHP)

- Platforms: `linux/amd64`, `linux/arm64` (QEMU)
- Push to GHCR + Docker Hub
- Tags per version:
  - `<php>` (rolling)
  - `<php>-v<version>` (immutable)
  - `latest` (only highest PHP when `push_latest=true`)
- Provenance + SBOM enabled
- Cosign keyless sign each digest
- Trivy scan published GHCR image
- Post-build smoke: pull from Docker Hub, check pdo_sqlite, pdo_pgsql, gd, redis, composer

### Job: `build-and-push-deploy`

- Target `deploy`, PHP 8.4
- Tags: `8.4-deploy`, `8.4-deploy-v<version>`
- Same signing / Trivy / smoke as main images

**Secrets required:** `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` (+ `GITHUB_TOKEN` for GHCR)

---

## weekly-rebuild.yml

**Triggers:** cron `0 3 * * 1` (Monday 03:00 UTC), `workflow_dispatch`

Rebuilds **rolling** tags only (no immutable `-v` tags):
- `8.4`, `8.3`, `8.2`, `8.1` + `latest` on 8.4
- `8.4-deploy`

Picks up Debian/PHP base image security patches without a semver release.

---

## labels.yml

Syncs `.github/labels.yml` taxonomy to GitHub when changed on `master`.

---

## Trivy policy

- Composite action scans built/published images
- Fails on **CRITICAL** and **HIGH** fixable CVEs
- `ignore-unfixed: true`
- `.trivyignore` suppresses non-exploitable `linux-libc-dev` kernel-header CVEs

---

## Enabling PHP 8.5

When `php:8.5-cli-bookworm` is GA:

1. Uncomment `8.5` in `test-php-ci.yml` matrix
2. Uncomment in `weekly-rebuild.yml` matrix
3. Add to `publish-php-ci.yml` default PHP list / manual input docs
4. Update `scripts/test-local.sh` default `PHP_VERSIONS`
5. Update `CHANGELOG.md`, README, [php-ci-docs](https://github.com/himanshuramavat/php-ci-docs)

---

## Local parity

`./test-local.sh` mirrors the core of `build-and-test` + deploy job (no Trivy, no sidecar DB tests). For full CI parity run hadolint + trivy manually — see `context/tasks/local-test.md`.
