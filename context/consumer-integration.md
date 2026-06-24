# php-ci — Consumer Integration

How downstream projects — especially T3Planet TYPO3 extensions — consume the image.

---

## Typical consumer pattern (GitLab CI)

T3Planet packages pin **immutable** tags for reproducibility:

```yaml
variables:
  PHP_CI_IMAGE: "himanshuramavat/php-ci"
  PHP_CI_VERSION: "1.4.0"   # bump when releasing new php-ci version

tests:
  image: ${PHP_CI_IMAGE}:${PHP_VERSION}-v${PHP_CI_VERSION}
  parallel:
    matrix:
      - PHP_VERSION: ["8.2", "8.3", "8.4"]
        TYPO3_VERSION: ["^13.4", "^14.3"]
```

**Lint / cs / stan** jobs often use a single pin, e.g. `8.2-v${PHP_CI_VERSION}`.

### Known downstream consumers (T3Planet)

| Package | Repository / path |
|---|---|
| `ns_aiuniverse` | `nitsan/ns-aiuniverse` — `.gitlab-ci.yml` |
| `ns_t3ai` | `nitsan/ns-t3ai` — `.gitlab-ci.yml` |
| `ns_t3aa` | `nitsan/ns-t3aa` — `.gitlab-ci.yml` |
| `ns_t3cs` | `nitsan/ns-t3cs` — `.gitlab-ci.yml` |

When cutting a new php-ci release, bump `PHP_CI_VERSION` in each consumer's `.gitlab-ci.yml` after the image is published.

---

## TYPO3-specific variables

Consumers commonly set:

```yaml
COMPOSER_ALLOW_SUPERUSER: "1"
TYPO3_SKIP_ASSET_PUBLISH: "1"
PHP_INI_MEMORY_LIMIT: "1G"          # or per-job -d memory_limit=
```

Functional tests without a DB service:

```yaml
variables:
  TYPO3_CONTEXT: Testing
  typo3DatabaseDriver: pdo_sqlite
```

The image ships `pdo_sqlite` specifically for TYPO3 Testing Framework functional tests.

---

## Deploy pipelines

Use the **deploy variant** only in deploy stages:

```yaml
deploy:production:
  image: himanshuramavat/php-ci:8.4-deploy-v1.4.0
  script:
    - rsync -avz --delete -e ssh ./public/ user@host:/var/www/html/public/
```

Do **not** use `:8.4-deploy` for test/lint/analyse jobs.

---

## GHCR vs Docker Hub

| Scenario | Image ref |
|---|---|
| Public, no auth | `ghcr.io/himanshuramavat/php-ci:8.4` or `himanshuramavat/php-ci:8.4` |
| Same GitHub org, private package | `packages: read` + `docker/login-action` with `GITHUB_TOKEN` |
| Cross-org / GitLab / Jenkins | PAT with `read:packages` as CI secret |

T3Planet GitLab jobs use Docker Hub ref `himanshuramavat/php-ci` by default (no GHCR login needed for public Hub pulls).

---

## What consumers should NOT expect

| Missing | Workaround |
|---|---|
| Node.js / npm | Separate `node:lts` job; pass assets via artifacts |
| TYPO3 CLI pre-installed | `composer require` in `before_script` |
| Database server in image | GitLab `services:` or GitHub sidecar containers |
| Xdebug | Not in default image; use `EXTRA_EXTENSIONS` downstream build or different image |

---

## Examples in this repo

- `examples/gitlab-ci.example.yml` — full TYPO3-oriented pipeline with SQLite functional tests, MySQL service, deploy stage
- `examples/github-actions.example.yml` — container job pattern

Human-facing guides (published from https://github.com/himanshuramavat/php-ci-docs):

- [TYPO3](https://himanshuramavat.github.io/php-ci-docs/docs/frameworks/typo3)
- [GitLab CI](https://himanshuramavat.github.io/php-ci-docs/docs/ci-providers/gitlab-ci)

---

## Bumping the consumer pin (checklist)

1. Publish php-ci release (`vX.Y.Z`) — see `context/tasks/release.md`
2. Verify tags exist on Docker Hub: `8.2-vX.Y.Z`, `8.3-vX.Y.Z`, `8.4-vX.Y.Z` (as needed)
3. Update `PHP_CI_VERSION` in each package `.gitlab-ci.yml`
4. Trigger or wait for package CI pipelines to validate
