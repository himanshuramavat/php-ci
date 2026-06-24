# php-ci — Core Context

*Always load with `AGENTS.md`.*

---

## Identity

| Field | Value |
|---|---|
| Project | `php-ci` |
| Maintainer | Himanshu Ramavat |
| Upstream | https://github.com/himanshuramavat/php-ci |
| License | Apache 2.0 |
| Role | Reusable PHP CI Docker image for TYPO3, Laravel, and general PHP pipelines |

**Not included:** Node.js, npm, Vite — front-end builds belong in a separate `node:lts` job.

---

## Published images

| Registry | Image |
|---|---|
| GHCR | `ghcr.io/himanshuramavat/php-ci` |
| Docker Hub | `himanshuramavat/php-ci` |

Tags are identical on both registries. Prefer GHCR in CI to avoid Docker Hub anonymous pull rate limits.

---

## PHP version matrix

| Version | Status | Notes |
|---|---|---|
| 8.4 | Primary | `latest` alias; deploy variant only on 8.4 |
| 8.3 | Supported | |
| 8.2 | Supported | Common for TYPO3 13.x matrices |
| 8.1 | Legacy | |
| 8.5 | Planned | Commented out in workflows — enable when `php:8.5-cli-bookworm` is GA |

---

## Tagging

| Pattern | Example | Mutability | When to use |
|---|---|---|---|
| Rolling minor | `8.4` | Rebuilt weekly | Dev / main-branch CI |
| Immutable release | `8.4-v1.4.0` | Fixed at publish | Production pin |
| `latest` | `latest` | Rolling | Alias of highest PHP (8.4) |
| Deploy rolling | `8.4-deploy` | Weekly | Deploy stages only |
| Deploy immutable | `8.4-deploy-v1.4.0` | Fixed | Pinned deploy pipelines |

Current release pinned by downstream consumers: **1.4.0** (check `CHANGELOG.md` for latest).

---

## What's in the default image

**Tools:** Composer 2 (pinned minor from `composer:2.10`), git, curl, jq, unzip, zip

**PHP extensions (default):** mysqli, pdo, pdo_mysql, pdo_pgsql, pgsql, pdo_sqlite, redis (PECL 6.3.0), gd, bcmath, sodium, mbstring, intl, zip, xml, ctype, json, tokenizer, fileinfo, opcache

**Databases:** MySQL/MariaDB, PostgreSQL, SQLite (via PDO drivers)

**WORKDIR:** `/builds` · **USER:** `root` (override via `RUN_USER` build arg)

---

## Conventions

- **Commits:** Conventional Commits — `feat:`, `fix:`, `ci:`, `docs:`, `chore:`, `refactor:`, `test:` (optional scope)
- **Default branch:** `master`
- **Releases:** Semantic versioning; git tag `vX.Y.Z` triggers publish workflow
- **CHANGELOG:** Keep a `[Unreleased]` block; move to `[x.y.z]` before tagging
- **Labels:** Taxonomy in `.github/labels.yml` (`prio:*`, `type:*`, `area:*`)
- **Dockerfile lint:** hadolint with `.hadolint.yaml`
- **CVE scan:** Trivy CRITICAL/HIGH, `ignore-unfixed`; `.trivyignore` for `linux-libc-dev` kernel-header noise

---

## Prerequisites (local)

- Docker with BuildKit (`DOCKER_BUILDKIT=1`, default on recent Docker)
- Bash

---

## Quick commands

```bash
# From repository root

# Full local suite (8.4 8.3 8.2 8.1 + deploy)
./test-local.sh

# Single version
PHP_VERSIONS="8.4" ./test-local.sh

# Manual build
DOCKER_BUILDKIT=1 docker build \
  --build-arg PHP_VERSION=8.4 \
  --build-arg IMAGE_VERSION=local \
  -t php-ci:8.4 .

# Deploy variant
docker build --target deploy --build-arg PHP_VERSION=8.4 -t php-ci:8.4-deploy .

# Shell in container
docker run --rm -it -v "$PWD:/builds" -w /builds php-ci:8.4 bash
```
