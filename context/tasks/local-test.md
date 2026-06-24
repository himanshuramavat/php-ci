# Task: Local Build and Test

---

## Full suite (recommended before PR)

From the repository root:

```bash
./test-local.sh
```

Wrapper calls `scripts/test-local.sh`. Default `PHP_VERSIONS="8.4 8.3 8.2 8.1"`.

Per version:
1. `docker build` with `PHP_VERSION` build arg
2. `verify-image.sh` inside container
3. SQLite PDO smoke
4. GD smoke
5. Composer install smoke

Then builds `8.4-deploy` and runs `verify-deploy-image.sh`.

---

## Fast iteration (single PHP)

```bash
PHP_VERSIONS="8.4" ./test-local.sh
```

---

## Manual build + verify

```bash
DOCKER_BUILDKIT=1 docker build \
  --build-arg PHP_VERSION=8.4 \
  --build-arg IMAGE_VERSION=local \
  -t php-ci:test-8.4 .

docker run --rm php-ci:test-8.4 /usr/local/bin/verify-image.sh
```

---

## Optional CI parity checks

```bash
# Dockerfile lint (matches test-php-ci.yml lint job)
hadolint Dockerfile

# CVE scan (matches Trivy composite action)
trivy image php-ci:test-8.4
```

Trivy requires [Trivy installed](https://trivy.dev/) locally.

---

## Interactive debugging

```bash
docker run --rm -it \
  -v "$PWD:/builds" \
  -w /builds \
  php-ci:test-8.4 \
  bash
```

Inside: `php -m`, `composer --version`, run extension-specific `php -r` snippets.

---

## DB smoke tests (CI only locally)

`test-local.sh` does **not** start PostgreSQL/MySQL/Redis sidecars. Those run in `test-php-ci.yml` only.

To reproduce DB smokes manually:

```bash
docker network create phpci-test
docker run -d --name phpci-postgres --network phpci-test \
  -e POSTGRES_PASSWORD=postgres postgres:16-alpine
# ... then docker run --network phpci-test php-ci:test-8.4 php -r '...'
```

Or push a branch and let GitHub Actions run the full matrix.

---

## Common failures

| Symptom | Likely cause |
|---|---|
| Build fails at `verify-image.sh` | Extension not compiled or missing from `REQUIRED_EXTENSIONS` |
| `pecl install` fails | Missing apt `-dev` package or wrong PECL version pin |
| Image huge | Forgot to purge `PHPIZE_DEPS` in same RUN layer |
| Deploy verify fails | Built without `--target deploy` |
