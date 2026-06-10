# php-ci — Reusable PHP CI Docker Image

[![PHP](https://img.shields.io/badge/PHP-8.4%20%7C%208.3%20%7C%208.2%20%7C%208.1-blue)](https://www.php.net/)
[![Docker](https://img.shields.io/badge/Docker-GHCR%20%7C%20Hub-blue)](https://hub.docker.com/r/himanshuramavat/php-ci)
[![License](https://img.shields.io/badge/License-Apache%202.0-green)](./LICENSE)
[![Test CI](https://github.com/himanshuramavat/php-ci/actions/workflows/test-php-ci.yml/badge.svg?branch=master)](https://github.com/himanshuramavat/php-ci/actions/workflows/test-php-ci.yml)
[![Publish](https://github.com/himanshuramavat/php-ci/actions/workflows/publish-php-ci.yml/badge.svg?branch=master)](https://github.com/himanshuramavat/php-ci/actions/workflows/publish-php-ci.yml)

Production-ready, reusable CI image for **TYPO3**, **Laravel**, and general **PHP** projects.

Build once, push to GitHub Container Registry (GHCR) and [Docker Hub](https://hub.docker.com/r/himanshuramavat/php-ci), and reuse across:

- GitHub Actions
- GitLab CI
- Local development workflows
- Internal CI/CD infrastructure

**Primary image** (same tags on both registries)

```bash
ghcr.io/himanshuramavat/php-ci:8.4
himanshuramavat/php-ci:8.4
```

---

## Table of Contents

- Features
- Quick Start
- Image Tagging Strategy
- What's Included
- Project Structure
- Design Decisions
- Build / Login / Push / Pull
- Continuous Integration
- Publishing
- Consumer Examples
- Using this image from another org / CI
- Local Development
- Contributing
- Security
- Maintainer
- License

---

## Features

✅ PHP 8.4, 8.3, 8.2 and 8.1 support

✅ Composer 2 pre-installed

✅ TYPO3 (SQLite functional tests), Laravel, PostgreSQL, Redis ready

✅ PostgreSQL and SQLite support

✅ Redis extension support

✅ GD image processing support

✅ BCMath extension support

✅ Optimized multi-stage Docker build

✅ GitHub Actions and GitLab CI support

✅ Lightweight production image

✅ Build validation and smoke tests

✅ GitHub Container Registry support

✅ Semantic image versioning

---

## Quick Start

### GitLab CI / GitHub Actions

```yaml
image: ghcr.io/himanshuramavat/php-ci:8.4
```

### Pull image

```bash
docker pull ghcr.io/himanshuramavat/php-ci:8.4
```

### Run Composer

```bash
docker run --rm \
-v "$PWD:/builds" \
-w /builds \
ghcr.io/himanshuramavat/php-ci:8.4 \
composer install
```

---

## Image Tagging Strategy

| Tag | Purpose | Mutability |
|------|----------|------------|
| `8.4` | Primary CI PHP version | Rolling |
| `8.3` | Supported | Rolling |
| `8.2` | Supported | Rolling |
| `8.1` | Legacy | Rolling |
| `latest` | Alias of highest PHP built (8.4) | Rolling |
| `8.4-v<LATEST>` | Immutable release | Fixed |

> Immutable tags follow `<php>-v<x.y.z>`. Use the newest release from the
> [Releases page](https://github.com/himanshuramavat/php-ci/releases) — e.g. `8.4-v<LATEST>`.

### Recommendations

Development:

```bash
8.4
```

Main branch:

```bash
8.4
```

Production:

```bash
8.4-v<LATEST>
```

For stable release pinning, use the newest immutable tag from the
[Releases page](https://github.com/himanshuramavat/php-ci/releases), e.g. `8.4-v<LATEST>`.

TYPO3 PHP 8.2 projects:

```bash
8.2
```

legacy PHP 8.1 matrices:

```bash
8.1
```

---

## What's Included

### PHP Extensions

```text
mysqli
pdo
pdo_mysql
pdo_pgsql
pgsql
pdo_sqlite
redis
gd
bcmath
sodium
mbstring
intl
zip
xml
ctype
json
tokenizer
fileinfo
opcache
```

**TYPO3 extension CI:** `pdo_sqlite` supports TYPO3 Testing Framework functional tests without a database service. **Laravel/MySQL:** use `pdo_mysql`. **PostgreSQL:** use `pdo_pgsql` / `pgsql`. **Redis:** PECL `redis` for cache/queue test suites.

### Database support

- MySQL / MariaDB
- PostgreSQL
- SQLite

### System Packages

```text
git
curl
unzip
zip
jq
ca-certificates
libpq-dev
libsqlite3-dev
libpng-dev
libjpeg62-turbo-dev
libwebp-dev
libfreetype6-dev
```

### Tools

- Composer 2
- Git
- jq

### Validation

Build immediately fails if:

- Required PHP extensions are missing
- Database drivers fail to load
- Redis extension validation fails
- Composer is missing
- Runtime validation fails

---

## Project Structure

```text
.
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── Dockerfile
├── .dockerignore
├── .hadolint.yaml
├── .trivyignore
├── .github/
│   ├── actions/
│   │   └── trivy-image-scan/action.yml
│   ├── workflows/
│   │   ├── test-php-ci.yml
│   │   ├── publish-php-ci.yml
│   │   ├── weekly-rebuild.yml
│   │   └── labels.yml
│   ├── dependabot.yml
│   ├── labels.yml
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.yml
│       ├── config.yml
│       └── feature_request.yml
├── examples/
│   ├── gitlab-ci.example.yml
│   └── github-actions.example.yml
├── scripts/
│   ├── test-local.sh
│   └── verify-image.sh
├── test-local.sh
└── README.md
```

---

## Design Decisions

### Multi-stage build

Stage 1:

- Build PHP extensions

Stage 2:

- Copy Composer from official Composer image

Benefits:

- Smaller image
- Less duplication
- Better security

Composer is copied from the official `composer:2.8` image. The minor is **pinned** for
reproducible builds and bumped deliberately via Dependabot (not rolling `composer:2`).

---

### BuildKit caching

Uses:

```dockerfile
--mount=type=cache
```

Benefits:

- Faster CI builds
- Smaller published layers

---

### Fail-fast validation

Build checks:

- PHP extensions
- Database drivers
- Composer
- Runtime dependencies

---

### Root user

CI environments commonly require root access:

- GitHub Actions
- GitLab CI
- Docker executors

Prevents permission problems.

Orgs that forbid root containers can build a non-root variant via the `RUN_USER` build arg
(default `root`, unchanged):

```bash
docker build --build-arg RUN_USER=www-data -t php-ci:nonroot .
```

---

### Build-arg variants

Keep the default image lean; opt into extras at build time instead of bloating it:

| Build arg | Default | Purpose |
|---|---|---|
| `PHP_VERSION` | `8.4` | PHP minor to build |
| `EXTRA_EXTENSIONS` | _(empty)_ | Space-separated extra core extensions (e.g. `soap xsl pcntl`) |
| `RUN_USER` | `root` | Non-root runtime user when set to a non-root name |

```bash
docker build \
  --build-arg PHP_VERSION=8.4 \
  --build-arg EXTRA_EXTENSIONS="soap xsl pcntl" \
  -t php-ci:8.4-extras .
```

Extras are compiled best-effort while the build toolchain is present; extensions needing
extra system libraries (e.g. `ldap`, `imagick`) may require a downstream `FROM` layer.

---

## Build / Login / Push / Pull
For rolling tags and weekly rebuilds, see [CHANGELOG.md](./CHANGELOG.md) and the scheduled workflow in `.github/workflows/weekly-rebuild.yml`.
### Build

PHP 8.3:

```bash
DOCKER_BUILDKIT=1 docker build \
--build-arg PHP_VERSION=8.3 \
--build-arg IMAGE_VERSION=1.0.0 \
-t ghcr.io/himanshuramavat/php-ci:8.3 \
-t ghcr.io/himanshuramavat/php-ci:latest \
.
```

PHP 8.2:

```bash
DOCKER_BUILDKIT=1 docker build \
--build-arg PHP_VERSION=8.2 \
-t ghcr.io/himanshuramavat/php-ci:8.2 \
.
```

PHP 8.1:

```bash
DOCKER_BUILDKIT=1 docker build \
--build-arg PHP_VERSION=8.1 \
--build-arg IMAGE_VERSION=1.1.0 \
-t ghcr.io/himanshuramavat/php-ci:8.1 \
.
```

---

### Login

```bash
echo "$GITHUB_TOKEN" | docker login ghcr.io \
-u USERNAME \
--password-stdin
```

---

### Push

```bash
docker push ghcr.io/himanshuramavat/php-ci:8.3

docker push ghcr.io/himanshuramavat/php-ci:latest
```

---

### Pull

```bash
docker pull ghcr.io/himanshuramavat/php-ci:8.3
```

---

## Continuous Integration

Workflow:

```text
.github/workflows/test-php-ci.yml
```

Runs on:

- Push
- Pull Request

Checks:

- Image build
- PHP extensions
- PostgreSQL support
- SQLite support
- GD extension
- Redis extension
- Composer
- git
- jq
- Smoke tests

Publishing only happens after releases.

---

## Publishing

Workflow:

```text
.github/workflows/publish-php-ci.yml
```

Publishing triggers:

### Tag release

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## Consumer Examples

### GitLab

```yaml
image: ghcr.io/himanshuramavat/php-ci:8.3

stages:
  - test

test:
  stage: test
  script:
    - composer install
    - vendor/bin/phpunit
```

### GitHub Actions

```yaml
name: Test

on:
  push:
  pull_request:

jobs:
  tests:
    runs-on: ubuntu-latest

    container:
      image: ghcr.io/himanshuramavat/php-ci:8.3

    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: composer install

      - name: Run tests
        run: vendor/bin/phpunit
```

---

## Using this image from another org / CI

The image is published to **GHCR** and **Docker Hub** with identical tags.

### Public image (default)

GHCR packages can be made public — then no auth is needed:

```yaml
container:
  image: ghcr.io/himanshuramavat/php-ci:8.4
```

To avoid Docker Hub anonymous pull rate limits in busy pipelines, prefer the GHCR ref above
(or authenticate to Docker Hub).

### Private / org-scoped GHCR

If the package is private, the consuming workflow needs `packages: read` and a login. The
built-in `GITHUB_TOKEN` works for repos in the **same org** that have access to the package:

```yaml
permissions:
  contents: read
  packages: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      # ... then pull/run ghcr.io/himanshuramavat/php-ci:8.4
```

**Cross-org / external CI** (GitLab, Jenkins, another GitHub org): `GITHUB_TOKEN` won't have
access. Create a **Personal Access Token** (or fine-grained token) with `read:packages`,
store it as a secret, and log in with it:

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
```

Grant the token's account access under the package's *Package settings → Manage access*.

### Node.js for front-end builds

This image is **PHP-only** — it ships no Node.js. TYPO3/Laravel front-end steps (Vite, npm)
should run in a separate `node:lts` job/container (or a sibling service), then share built
assets via artifacts. Keeping Node out of this image keeps it small and focused.

---

## Local Development

### Pull image

```bash
docker pull ghcr.io/himanshuramavat/php-ci:8.3
```

### Open shell inside container

```bash
docker run --rm -it \
-v "$PWD:/builds" \
-w /builds \
ghcr.io/himanshuramavat/php-ci:8.3 \
bash
```

### Run Composer

```bash
composer install
```

### Run PHPUnit

```bash
vendor/bin/phpunit
```

### Run local validation script

```bash
chmod +x test-local.sh
./test-local.sh
```

---

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](./CONTRIBUTING.md) for local testing, the
extension-addition checklist, the PHP version matrix policy, and the release process.

### Steps

Clone repository:

```bash
git clone git@github.com:himanshuramavat/php-ci.git
```

Create branch:

```bash
git checkout -b feature/my-feature
```

Commit:

```bash
git commit -m "feat: add feature"
```

Push:

```bash
git push origin feature/my-feature
```

Open a Pull Request.

---

## Security

Vulnerability reporting, supported versions, image scanning, and cosign signature verification
are documented in [SECURITY.md](./SECURITY.md).

---

## Maintainer

**Himanshu Ramavat**

GitHub:

https://github.com/HimanshuRamavat

Website:

https://himanshuramavat.in

---

## License

This project is licensed under the Apache License 2.0.

See the LICENSE file for details.
