# Task: Release php-ci

Immutable tags are published by `.github/workflows/publish-php-ci.yml`.

---

## Pre-release checklist

- [ ] Changes merged to `master`
- [ ] `./test-local.sh` passes (or at least affected PHP versions)
- [ ] `CHANGELOG.md`: move `[Unreleased]` items under new `## [x.y.z] - YYYY-MM-DD`
- [ ] If `DOCKERHUB.md` changed, plan to paste into [Docker Hub description](https://hub.docker.com/r/himanshuramavat/php-ci) (not auto-synced)
- [ ] Docs site updated in https://github.com/himanshuramavat/php-ci-docs if user-facing behaviour changed

---

## Tag and push

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

Push to `himanshuramavat/php-ci` remote (this nested repo's `origin`).

---

## What the publish workflow does

1. Resolves version from tag (`v1.4.0` → `1.4.0`)
2. Builds matrix PHP 8.4, 8.3, 8.2, 8.1 (unless manual dispatch overrides)
3. Pushes to GHCR + Docker Hub:
   - `<php>` (rolling — also refreshed on weekly rebuild)
   - `<php>-vX.Y.Z` (immutable)
   - `latest` on highest PHP only
4. Builds `8.4-deploy` + `8.4-deploy-vX.Y.Z`
5. Attaches provenance + SBOM
6. Cosign-signs digests (keyless, GitHub OIDC)
7. Trivy scan + post-build smoke on Docker Hub

---

## Manual publish (workflow_dispatch)

GitHub Actions → *Publish PHP CI Image* → Run workflow:

- `image_version`: e.g. `1.4.1`
- `php_versions`: e.g. `8.4,8.3,8.2,8.1`
- `push_latest`: true/false

Use for hotfix republish without a tag only if project policy allows (prefer tags).

---

## After publish — downstream consumers

Bump `PHP_CI_VERSION` in each consumer's `.gitlab-ci.yml` (see `context/consumer-integration.md` for the list).

---

## Rolling vs immutable

| Tag | Updated by |
|---|---|
| `8.4`, `latest` | Weekly rebuild **and** each release push |
| `8.4-v1.4.0` | **Only** at `v1.4.0` publish — frozen forever |

Consumers on immutable pins must bump version to get security fixes.

---

## Verify published image

```bash
docker pull himanshuramavat/php-ci:8.4-vX.Y.Z
docker run --rm himanshuramavat/php-ci:8.4-vX.Y.Z /usr/local/bin/verify-image.sh
```

Cosign verification: see `SECURITY.md`.
