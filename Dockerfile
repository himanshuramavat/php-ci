# syntax=docker/dockerfile:1.7
# -----------------------------------------------------------------------------
# Reusable PHP CI image for TYPO3, Laravel and general PHP pipelines.
#
# Build (PHP 8.4):
#   docker build \
#     --build-arg PHP_VERSION=8.4 \
#     --build-arg IMAGE_VERSION=1.1.0 \
#     -t ghcr.io/himanshuramavat/php-ci:8.4 .
#
# Build (PHP 8.3):
#   docker build \
#     --build-arg PHP_VERSION=8.3 \
#     --build-arg IMAGE_VERSION=1.1.0 \
#     -t ghcr.io/himanshuramavat/php-ci:8.3 .
# -----------------------------------------------------------------------------

ARG PHP_VERSION=8.4
ARG IMAGE_VERSION=1.1.0

# -----------------------------------------------------------------------------
# Stage 1: PHP runtime with compiled extensions (single compile layer)
# -----------------------------------------------------------------------------
FROM php:${PHP_VERSION}-cli-bookworm AS php-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1 \
    COMPOSER_CACHE_DIR=/tmp/composer-cache \
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Runtime libraries stay installed; build-only packages are purged in the same layer.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    apt-get update -qq; \
    apt-get install -y -qq --no-install-recommends \
        ca-certificates \
        curl \
        git \
        jq \
        unzip \
        zip \
        default-libmysqlclient-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libonig-dev \
        libpng-dev \
        libpq-dev \
        libsqlite3-dev \
        libwebp-dev \
        libxml2-dev \
        libzip-dev \
        ${PHPIZE_DEPS}; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-configure intl; \
    docker-php-ext-install -j"$(nproc)" \
        bcmath \
        gd \
        intl \
        mbstring \
        mysqli \
        opcache \
        pdo_mysql \
        pdo_pgsql \
        pdo_sqlite \
        pgsql \
        xml \
        zip; \
    pecl install redis; \
    docker-php-ext-enable redis; \
    apt-get purge -y -qq ${PHPIZE_DEPS}; \
    apt-get autoremove -y -qq; \
    rm -rf /tmp/* /var/tmp/* /usr/src/php*

# Git safe.directory for CI checkouts mounted from host or cloned in pipeline
RUN git config --global --add safe.directory '*'

# -----------------------------------------------------------------------------
# Stage 2: Composer binary (no duplicate Composer install logic)
# -----------------------------------------------------------------------------
FROM composer:2 AS composer-bin

# -----------------------------------------------------------------------------
# Final image: PHP runtime + Composer + fail-fast validation
# -----------------------------------------------------------------------------
FROM php-runtime AS final

COPY --from=composer-bin /usr/bin/composer /usr/bin/composer

# Fail the image build immediately if required tooling is missing or broken.
RUN --mount=type=cache,target=/tmp/composer-cache,sharing=locked \
    set -eux; \
    for ext in mysqli sodium pdo_mysql pdo_pgsql pgsql pdo_sqlite gd redis bcmath intl zip mbstring fileinfo json ctype tokenizer xml pdo; do \
      php -r "exit(extension_loaded('${ext}') ? 0 : 1);" \
        || { echo "ERROR: Missing PHP extension: ${ext}" >&2; exit 1; }; \
    done; \
    php -m | grep -qi 'opcache'; \
    php -m | grep -qE '^(mysqli|sodium|PDO|pdo_mysql|pdo_pgsql|pgsql|pdo_sqlite|gd|redis|bcmath|intl|zip)$'; \
    composer --version | grep -qi 'Composer version'; \
    git --version >/dev/null

WORKDIR /builds

ARG IMAGE_VERSION=1.1.0
ARG PHP_VERSION=8.4
ARG SOURCE_REPOSITORY=https://github.com/himanshuramavat/php-ci

LABEL maintainer="Himanshu Ramavat" \
    org.opencontainers.image.title="php-ci" \
    org.opencontainers.image.description="Production-ready reusable PHP CI image for TYPO3, Laravel and PHP pipelines" \
    org.opencontainers.image.version="${IMAGE_VERSION}" \
    org.opencontainers.image.source="${SOURCE_REPOSITORY}" \
    project="php-ci" \
    php.version="${PHP_VERSION}"
