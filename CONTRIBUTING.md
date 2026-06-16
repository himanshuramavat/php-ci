# Contributing to php-ci

Thanks for helping improve this reusable PHP CI image. This guide covers local testing,
the (easy-to-get-wrong) extension-addition flow, and the release process.

## Prerequisites

- Docker with BuildKit (`DOCKER_BUILDKIT=1`, default on recent Docker).
- Bash.

## Running tests locally

The root wrapper mirrors `.github/workflows/test-php-ci.yml`:

```bash
./test-local.sh                 # builds + tests all PHP versions (8.4 8.3 8.2 8.1)
PHP_VERSIONS="8.4" ./test-local.sh   # single version, faster iteration
```

It delegates to [`scripts/test-local.sh`](scripts/test-local.sh) and runs, per version:
`verify-image.sh` → SQLite PDO → GD → Composer smoke.

Optional manual checks:

```bash
hadolint Dockerfile                                  # Dockerfile lint (matches CI)
trivy image php-ci:test-8.4                           # CVE scan (matches CI)
```

## Adding a PHP extension

The extension list lives in **three** places that must stay in sync — update **all three**:

1. **`Dockerfile`** — add to the `docker-php-ext-install` list (and any required `-dev`
   apt package + `docker-php-ext-configure`).
2. **`scripts/verify-image.sh`** — add to `REQUIRED_EXTENSIONS` so the build fails fast if it
   is missing.
3. **`README.md`** — add to the *What's Included → PHP Extensions* list.

If the extension only matters to some consumers, prefer the `EXTRA_EXTENSIONS` build arg
instead of baking it into the default image:

```bash
docker build --build-arg EXTRA_EXTENSIONS="soap xsl" ...
```

Then run `./test-local.sh` to confirm the build still passes everywhere.

## PHP version matrix

PHP `8.1`–`8.4` are built. `8.5` rows are present but commented out across the workflows and
will be enabled once `php:8.5-cli-bookworm` is GA on Docker Hub — uncomment the matrix rows
and run the full local suite.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):
`feat:`, `fix:`, `ci:`, `docs:`, `chore:`, `refactor:`, `test:`. Scope is optional, e.g.
`ci(security): add Trivy image scan`.

## Release process

Releases are immutable tags published by `.github/workflows/publish-php-ci.yml`:

1. Land changes on `master`.
2. Move the `## [Unreleased]` block in `CHANGELOG.md` under a new `## [x.y.z]` heading.
3. Tag and push:
   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```
4. The publish workflow builds `linux/amd64,linux/arm64`, pushes
   `<php>` + `<php>-vX.Y.Z` (+ `latest` for the highest PHP) to GHCR and Docker Hub, attaches
   provenance + SBOM, and cosign-signs the digests.

Rolling tags are additionally rebuilt weekly by `.github/workflows/weekly-rebuild.yml` to pick
up Debian/PHP base updates.

5. If `DOCKERHUB.md` changed, paste its contents into the
   [Docker Hub repository description](https://hub.docker.com/r/himanshuramavat/php-ci)
   (Docker Hub does not auto-sync this file).

## Labels

Issues/PRs use the taxonomy in [`.github/labels.yml`](.github/labels.yml):
`prio:*`, `type:*`, `area:*`. Labels are synced automatically when that file changes on
`master`.
