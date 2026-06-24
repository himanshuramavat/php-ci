# php-ci — Architecture

Docker multi-stage build. Single `Dockerfile`, three meaningful targets.

---

## Stages

```text
php:${PHP_VERSION}-cli-bookworm  (AS php-runtime)
    ↓ compile extensions, apt packages, purge PHPIZE_DEPS
composer:2.10                    (AS composer-bin)
    ↓ COPY /usr/bin/composer only
php-runtime                      (AS final)     ← default image :8.4 etc.
    ↓ verify-image.sh at build time
final                            (AS deploy)    ← :8.4-deploy only
    ↓ + rsync, openssh-client, verify-deploy-image.sh
```

### Stage 1: `php-runtime`

- Base: `php:${PHP_VERSION}-cli-bookworm` (Debian bookworm)
- Installs runtime + build deps, compiles core extensions, PECL `redis-6.3.0`
- Purges `${PHPIZE_DEPS}` in same layer to keep image lean
- `git config --global safe.directory '*'` for CI checkouts
- BuildKit apt/composer caches: `--mount=type=cache`

### Stage 2: `composer-bin`

- Copies Composer binary from pinned `composer:2.10` (not rolling `composer:2`)
- Minor bumped deliberately via Dependabot

### Stage 3: `final` (default target)

- Copies Composer + `scripts/verify-image.sh`
- Runs `verify-image.sh` during build — **image build fails if validation fails**
- `WORKDIR /builds`
- Optional non-root: `RUN_USER` build arg (default `root`)
- Informational `HEALTHCHECK` (`php -v`)
- OCI labels: `php.version`, `org.opencontainers.image.version` (= `IMAGE_VERSION`)

### Stage 4: `deploy` (opt-in)

- `FROM final AS deploy`
- Switches to `root`, installs `openssh-client` + `rsync`
- Runs `verify-deploy-image.sh` (chains base `verify-image.sh` + deploy tools)
- **Never** add deploy packages to the default `:8.4` image

---

## Build arguments

| Arg | Default | Purpose |
|---|---|---|
| `PHP_VERSION` | `8.4` | PHP minor to build |
| `IMAGE_VERSION` | `1.1.0` | Embedded in OCI labels / publish metadata |
| `SOURCE_REPOSITORY` | upstream URL | OCI `image.source` label |
| `EXTRA_EXTENSIONS` | `""` | Space-separated extra core extensions (best-effort compile) |
| `RUN_USER` | `root` | Non-root runtime user when set to e.g. `www-data` |

Examples:

```bash
# Non-root
docker build --build-arg RUN_USER=www-data -t php-ci:nonroot .

# Extra extensions (consumer-specific; not in default image)
docker build --build-arg EXTRA_EXTENSIONS="soap xsl pcntl" -t php-ci:extras .

# Deploy
docker build --target deploy --build-arg PHP_VERSION=8.4 -t php-ci:8.4-deploy .
```

Extensions needing extra system libraries (`ldap`, `imagick`) may require a downstream `FROM` layer — not all work via `EXTRA_EXTENSIONS` alone.

---

## Fail-fast validation

`scripts/verify-image.sh` runs at **image build time** and can be invoked manually:

```bash
docker run --rm php-ci:8.4 /usr/local/bin/verify-image.sh
```

Checks:
- Every entry in `REQUIRED_EXTENSIONS` is loaded
- `opcache` present
- `composer`, `git`, `jq` available

`scripts/verify-deploy-image.sh` additionally checks `rsync` and `ssh`.

---

## Design decisions (do not regress without reason)

| Decision | Rationale |
|---|---|
| Root default user | GitHub Actions / GitLab CI executors expect root; avoids permission issues |
| PHP-only image | Keeps size down; Node belongs in separate job |
| Composer copied, not installed via apt | Smaller, matches official Composer image |
| Multi-stage | Smaller final image; compile toolchain not shipped |
| Build-time validation | Broken images never reach registry |
| Deploy as separate target/tag | Test/lint jobs stay lean; deploy tooling opt-in |
| Pinned Composer minor | Reproducible builds; Dependabot bumps deliberately |
| `linux/arm64` on publish | Multi-arch via QEMU in publish + weekly workflows |

Soft image size limit in CI: **550 MB** (warning, not hard fail).

---

## Files that must stay in sync

| Change type | Files |
|---|---|
| New default extension | `Dockerfile`, `scripts/verify-image.sh`, `README.md` |
| Deploy tooling | `Dockerfile` deploy target, `scripts/verify-deploy-image.sh`, `README.md` |
| New PHP version | `Dockerfile` (via arg), all workflow matrices, `scripts/test-local.sh` default `PHP_VERSIONS`, `CHANGELOG.md`, [php-ci-docs](https://github.com/himanshuramavat/php-ci-docs) |

See `context/tasks/add-extension.md` for the extension checklist.
