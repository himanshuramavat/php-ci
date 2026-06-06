#!/usr/bin/env bash
set -euo pipefail

REQUIRED_EXTENSIONS=(
  mysqli
  sodium
  pdo_mysql
  pdo_pgsql
  pgsql
  pdo_sqlite
  gd
  redis
  bcmath
  intl
  zip
  mbstring
  fileinfo
  json
  ctype
  tokenizer
  xml
  pdo
)

for ext in "${REQUIRED_EXTENSIONS[@]}"; do
  php -r "exit(extension_loaded('${ext}') ? 0 : 1);" || {
    echo "ERROR: Missing PHP extension: ${ext}" >&2
    exit 1
  }
done

php -m | grep -qi 'opcache'
php -m | grep -qE '^(mysqli|sodium|PDO|pdo_mysql|pdo_pgsql|pgsql|pdo_sqlite|gd|redis|bcmath|intl|zip)$'
composer --version | grep -qi 'Composer version'
git --version >/dev/null
jq --version >/dev/null
