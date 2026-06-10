#!/usr/bin/env bash
# Local test runner — mirrors .github/workflows/test-php-ci.yml
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PHP_VERSIONS="${PHP_VERSIONS:-8.4 8.3 8.2 8.1}"

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

  echo "==> Verifying image (${PHP_VERSION})"
  docker run --rm "${IMAGE}" /usr/local/bin/verify-image.sh

  echo "==> SQLite PDO smoke test (${PHP_VERSION})"
  docker run --rm "${IMAGE}" php -r '
    $pdo = new PDO("sqlite::memory:");
    $pdo->exec("CREATE TABLE t (id INTEGER PRIMARY KEY)");
    $pdo->exec("INSERT INTO t (id) VALUES (1)");
    exit($pdo->query("SELECT COUNT(*) FROM t")->fetchColumn() == 1 ? 0 : 1);
  '

  echo "==> GD smoke test (${PHP_VERSION})"
  docker run --rm "${IMAGE}" php -r '
    $img = imagecreatetruecolor(10, 10);
    if ($img === false) { exit(1); }
    imagefilledrectangle($img, 0, 0, 9, 9, imagecolorallocate($img, 1, 2, 3));
    $ok = imagepng($img, "/tmp/gd.png")
      && function_exists("imagewebp")
      && function_exists("imagecreatefromjpeg");
    exit($ok ? 0 : 1);
  '

  echo "==> Composer smoke test (${PHP_VERSION})"
  docker run --rm "${IMAGE}" \
    sh -c 'mkdir -p /tmp/smoke && cd /tmp/smoke && printf "%s\n" "{\"require\":{\"php\":\"*\"}}" > composer.json && composer install --no-interaction --no-progress'

  echo "==> OK: ${IMAGE}"
  echo
done

echo "All local tests passed."
