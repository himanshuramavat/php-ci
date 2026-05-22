# php-ci — Reusable PHP CI Docker Image

[![PHP](https://img.shields.io/badge/PHP-8.3%20%7C%208.2-blue)](https://www.php.net/)
[![Docker](https://img.shields.io/badge/Docker-GHCR-blue)](https://ghcr.io/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green)](./LICENSE)
[![Test CI](https://github.com/himanshuramavat/php-ci/actions/workflows/test-php-ci.yml/badge.svg?branch=main)](https://github.com/himanshuramavat/php-ci/actions/workflows/test-php-ci.yml)
[![Publish](https://github.com/himanshuramavat/php-ci/actions/workflows/publish-php-ci.yml/badge.svg?branch=main)](https://github.com/himanshuramavat/php-ci/actions/workflows/publish-php-ci.yml)

Production-ready, reusable CI image for **TYPO3**, **Laravel**, and general **PHP** projects.

Build once, push to GitHub Container Registry (GHCR), and reuse across:

- GitHub Actions
- GitLab CI
- Local development workflows
- Internal CI/CD infrastructure

**Primary image**

```bash
ghcr.io/himanshuramavat/php-ci:8.3
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
- Local Development
- Contributing
- Maintainer
- License

---

## Features

✅ PHP 8.3 and 8.2 support

✅ Composer 2 pre-installed

✅ TYPO3 and Laravel ready

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
image: ghcr.io/himanshuramavat/php-ci:8.3
```

### Pull image

```bash
docker pull ghcr.io/himanshuramavat/php-ci:8.3
```

### Run Composer

```bash
docker run --rm \
-v "$PWD:/builds" \
-w /builds \
ghcr.io/himanshuramavat/php-ci:8.3 \
composer install
```

---

## Image Tagging Strategy

| Tag | Purpose | Mutability |
|------|----------|------------|
| `8.3` | Primary CI PHP version | Rolling |
| `8.2` | Legacy support | Rolling |
| `latest` | Alias of latest stable | Rolling |
| `8.3-v1.0.0` | Immutable release | Fixed |

### Recommendations

Development:

```bash
8.3
```

Main branch:

```bash
8.3
```

Production:

```bash
8.3-v1.0.0
```

TYPO3 PHP 8.2 projects:

```bash
8.2
```

---

## What's Included

### PHP Extensions

```text
mysqli
pdo
pdo_mysql
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

### System Packages

```text
git
curl
unzip
zip
jq
ca-certificates
```

### Tools

- Composer 2
- Git
- jq

### Validation

Build immediately fails if:

- Required extensions are missing
- Composer is missing
- Runtime validation fails

---

## Project Structure

```text
.
├── Dockerfile
├── .dockerignore
├── .github/
│   └── workflows/
│       ├── test-php-ci.yml
│       └── publish-php-ci.yml
├── examples/
│   ├── gitlab-ci.example.yml
│   └── github-actions.example.yml
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
- Composer
- Runtime dependencies

---

### Root user

CI environments commonly require root access:

- GitHub Actions
- GitLab CI
- Docker executors

Prevents permission problems.

---

## Build / Login / Push / Pull

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
- Extensions
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

### Manual workflow dispatch

Configure:

- image_version
- php_versions
- push_latest

---

## Consumer Examples

GitLab:

```text
examples/gitlab-ci.example.yml
```

GitHub Actions:

```text
examples/github-actions.example.yml
```

---

## Local Development

```bash
docker pull ghcr.io/himanshuramavat/php-ci:8.3

docker run --rm -it \
-v "$PWD:/builds" \
-w /builds \
ghcr.io/himanshuramavat/php-ci:8.3 \
bash

composer install

vendor/bin/phpunit
```

---

## Contributing

Contributions are welcome.

### Steps

Clone repository:

```bash
git clone https://github.com/himanshuramavat/php-ci.git
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