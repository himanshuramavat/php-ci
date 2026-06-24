# Task: Add or Change a PHP Extension

---

## Default image extension (affects all consumers)

Update **all three** — missing any one lets broken images ship:

### 1. `Dockerfile`

In the `php-runtime` stage `RUN` block:

- Add required `-dev` apt packages **before** `docker-php-ext-install`
- Add `docker-php-ext-configure` if needed (see `gd`, `intl` patterns)
- Add extension name to `docker-php-ext-install` list

For PECL extensions, follow the `redis` pattern (`pecl install` + `docker-php-ext-enable`).

### 2. `scripts/verify-image.sh`

Add to `REQUIRED_EXTENSIONS` array. Build fails immediately if missing.

### 3. `README.md`

Add to *What's Included → PHP Extensions* list.

### 4. Verify

```bash
./test-local.sh
# or
PHP_VERSIONS="8.4" ./test-local.sh
```

Optional CI parity:

```bash
hadolint Dockerfile
trivy image php-ci:test-8.4
```

---

## Opt-in extension (single consumer / experiment)

Prefer **not** bloating the default image:

```bash
docker build --build-arg EXTRA_EXTENSIONS="soap xsl pcntl" -t php-ci:custom .
```

- Compiled best-effort in Dockerfile when `EXTRA_EXTENSIONS` is non-empty
- **Do not** add to `verify-image.sh` unless promoting to default image
- Extensions needing extra system libs may fail — document or add apt packages

---

## Deploy variant changes

When adding/changing deploy tooling (not PHP extensions):

| File | Change |
|---|---|
| `Dockerfile` | `deploy` target apt packages |
| `scripts/verify-deploy-image.sh` | fail-fast checks |
| `README.md` | *Deploy variant* section |

```bash
docker build --target deploy --build-arg PHP_VERSION=8.4 -t php-ci:8.4-deploy .
docker run --rm php-ci:8.4-deploy /usr/local/bin/verify-deploy-image.sh
```

---

## New PHP minor version

Beyond the three-file rule:

- Uncomment/add matrix rows in `test-php-ci.yml`, `weekly-rebuild.yml`, `publish-php-ci.yml`
- Update `scripts/test-local.sh` default `PHP_VERSIONS`
- `CHANGELOG.md` + README + docs repo https://github.com/himanshuramavat/php-ci-docs

---

## Do not

- Add Node.js, nginx, or database servers to the default image
- Add `rsync`/`openssh-client` to `final` target — use `deploy` target
- Skip `verify-image.sh` — it is the contract with CI smoke tests
