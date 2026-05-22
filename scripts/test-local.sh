#!/usr/bin/env bash
# Local test runner — mirrors .github/workflows/test-php-ci.yml
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PHP_VERSIONS="${PHP_VERSIONS:-8.3 8.2}"

cd "${ROOT_DIR}"

for PHP_VERSION in ${PHP_VERSIONS}; do
  IMAGE="php-ci:test-${PHP_VERSION}"
  echo "==> Building ${IMAGE}"
  DOCKER_BUILDKIT=1 docker build \
    --build-arg PHP_VERSION="${PHP_VERSION}" \
    --build-arg IMAGE_VERSION="local" \
    --build-arg SOURCE_REPOSITORY="local" \
    -t "${IMAGE}" \
    .

  echo "==> Verifying PHP extensions (${PHP_VERSION})"
  docker run --rm "${IMAGE}" php -m | tee /tmp/php-modules-"${PHP_VERSION}".txt

  for ext in mysqli sodium pdo_mysql pdo_pgsql pgsql pdo_sqlite sqlite3 intl zip mbstring fileinfo json ctype tokenizer xml pdo bcmath gd redis; do
    docker run --rm "${IMAGE}" php -r "exit(extension_loaded('${ext}') ? 0 : 1);" \
      || { echo "Missing extension: ${ext}"; exit 1; }
  done

  grep -qi 'opcache' "/tmp/php-modules-${PHP_VERSION}.txt"

  echo "==> Verifying Composer (${PHP_VERSION})"
  docker run --rm "${IMAGE}" composer --version

  echo "==> Verifying CI utilities (${PHP_VERSION})"
  docker run --rm "${IMAGE}" git --version
  docker run --rm "${IMAGE}" jq --version
  docker run --rm "${IMAGE}" test -d /builds

  echo "==> Composer smoke test (${PHP_VERSION})"
  docker run --rm "${IMAGE}" \
    sh -c 'mkdir -p /tmp/smoke && cd /tmp/smoke && printf "%s\n" "{\"require\":{\"php\":\"*\"}}" > composer.json && composer install --no-interaction --no-progress'

  echo "==> OK: ${IMAGE}"
  echo
done

echo "All local tests passed."
