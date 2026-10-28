# syntax=docker/dockerfile:1.7
# -----------------------------------------------------------------------------
# Reusable PHP CI image for TYPO3, Laravel and general PHP pipelines.
#
# Build (PHP 8.5):
#   docker build \
#     --build-arg PHP_VERSION=8.5 \
#     --build-arg IMAGE_VERSION=1.5.0 \
#     -t ghcr.io/himanshuramavat/php-ci:8.5 .
#
#   docker build \
#     --build-arg PHP_VERSION=8.4 \
#     --build-arg IMAGE_VERSION=1.5.0 \
#     -t ghcr.io/himanshuramavat/php-ci:8.4 .
#
# Build (PHP 8.3):
#   docker build \
#     --build-arg PHP_VERSION=8.3 \
#     --build-arg IMAGE_VERSION=1.5.0 \
#     -t ghcr.io/himanshuramavat/php-ci:8.3 .
#
# Build (PHP 8.1):
#   docker build \
#     --build-arg PHP_VERSION=8.1 \
#     --build-arg IMAGE_VERSION=1.5.0 \
#     -t ghcr.io/himanshuramavat/php-ci:8.1 .
# -----------------------------------------------------------------------------

ARG PHP_VERSION=8.4
ARG IMAGE_VERSION=1.5.0

# -----------------------------------------------------------------------------
# Stage 1: PHP runtime with compiled extensions (single compile layer)
# -----------------------------------------------------------------------------
FROM php:${PHP_VERSION}-cli-bookworm AS php-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1 \
    COMPOSER_CACHE_DIR=/tmp/composer-cache \
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Optional extra core extensions, space-separated (e.g. "soap xsl pcntl ldap").
# These are installed via the extension installer.
ARG EXTRA_EXTENSIONS=""

# Runtime libraries and extension installation.
# We use mlocati/docker-php-extension-installer to handle complex dependencies
# and version-specific quirks (especially for PHP 8.5).
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    apt-get update -qq; \
    apt-get upgrade -y -qq --no-install-recommends; \
    apt-get install -y -qq --no-install-recommends \
        ca-certificates \
        curl \
        git \
        jq \
        unzip \
        zip; \
    # Install the extension installer
    curl -sSL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions; \
    chmod +x /usr/local/bin/install-php-extensions; \
    # Install standard extensions (Opcache is built-in for PHP 8.5, handled automatically by installer)
    install-php-extensions \
        bcmath \
        gd \
        intl \
        mbstring \
        mysqli \
        pdo_mysql \
        pdo_pgsql \
        pdo_sqlite \
        pgsql \
        xml \
        zip \
        redis; \
    # Install optional extra extensions if provided
    if [ -n "${EXTRA_EXTENSIONS}" ]; then \
        install-php-extensions ${EXTRA_EXTENSIONS}; \
    fi; \
    apt-get autoremove -y -qq; \
    rm -rf /tmp/* /var/tmp/* /usr/src/php*

# Git safe.directory for CI checkouts mounted from host or cloned in pipeline
RUN git config --global --add safe.directory '*'

# -----------------------------------------------------------------------------
# Stage 2: Composer binary (no duplicate Composer install logic)
# Minor pinned for reproducibility; bumped deliberately via Dependabot.
# -----------------------------------------------------------------------------
FROM composer:2.10 AS composer-bin

# -----------------------------------------------------------------------------
# Final image: PHP runtime + Composer + fail-fast validation
# -----------------------------------------------------------------------------
FROM php-runtime AS final

# Refresh OS security patches on top of the cached runtime. This layer sits AFTER
# the expensive extension-compile layer, so busting it (via SECURITY_REFRESH) lets
# the weekly rebuild pull new Debian fixes for already-installed packages
# (e.g. curl, libmariadb*) WITHOUT recompiling PHP extensions. Change the value of
# SECURITY_REFRESH to force this layer (and everything below it) to re-run.
ARG SECURITY_REFRESH=0
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    echo "security refresh token: ${SECURITY_REFRESH}"; \
    apt-get update -qq; \
    apt-get upgrade -y -qq --no-install-recommends; \
    apt-get autoremove -y -qq; \
    rm -rf /tmp/* /var/tmp/*

COPY --from=composer-bin /usr/bin/composer /usr/bin/composer
COPY scripts/verify-image.sh /usr/local/bin/verify-image.sh
RUN chmod +x /usr/local/bin/verify-image.sh

# Fail the image build immediately if required tooling is missing or broken.
RUN --mount=type=cache,target=/tmp/composer-cache,sharing=locked \
    set -eux; \
    /usr/local/bin/verify-image.sh

WORKDIR /builds

# Default runs as root (most CI executors expect it). Set RUN_USER to a non-root
# name to create that user and hand it /builds + the Composer cache, for orgs that
# forbid root containers. Default behaviour is unchanged.
ARG RUN_USER=root
RUN set -eux; \
    if [ "${RUN_USER}" != "root" ]; then \
        useradd --create-home --shell /bin/bash "${RUN_USER}"; \
        mkdir -p /builds /tmp/composer-cache; \
        chown -R "${RUN_USER}:${RUN_USER}" /builds /tmp/composer-cache; \
    fi
USER ${RUN_USER}

# Informational only: low value for ephemeral CI containers, but useful when the
# image is reused in long-running dev environments / orchestrators.
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD php -v >/dev/null 2>&1 || exit 1

ARG IMAGE_VERSION=1.5.0
ARG PHP_VERSION=8.4
ARG SOURCE_REPOSITORY=https://github.com/himanshuramavat/php-ci

LABEL maintainer="Himanshu Ramavat" \
    org.opencontainers.image.title="php-ci" \
    org.opencontainers.image.description="Production-ready reusable PHP CI image for TYPO3, Laravel and PHP pipelines" \
    org.opencontainers.image.version="${IMAGE_VERSION}" \
    org.opencontainers.image.source="${SOURCE_REPOSITORY}" \
    project="php-ci" \
    php.version="${PHP_VERSION}"

# -----------------------------------------------------------------------------
# Optional deploy variant: rsync + SSH for TYPO3/PHP deploy pipelines.
# Build: docker build --target deploy -t php-ci:8.4-deploy .
# Published as :8.4-deploy (not part of default :8.4).
# -----------------------------------------------------------------------------
FROM final AS deploy

USER root
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    apt-get update -qq; \
    apt-get install -y -qq --no-install-recommends \
        openssh-client \
        rsync; \
    rm -rf /var/lib/apt/lists/*

COPY scripts/verify-deploy-image.sh /usr/local/bin/verify-deploy-image.sh
RUN chmod +x /usr/local/bin/verify-deploy-image.sh && /usr/local/bin/verify-deploy-image.sh

ARG RUN_USER=root
USER ${RUN_USER}
