# PHP for the project, run as PHP-FPM behind Caddy. The extensions and libraries are
# those of the official WordPress image (docker-library/wordpress, php8.5/fpm-alpine),
# without WordPress itself: Composer installs it, in public/wp. For local development.

# PHP 8.5, or the version DOCKER_PHP_VERSION gives in the .env of the project: 8.1,
# 8.6-rc, 8.4.12… a tag of the official image, as php:<version>-fpm-alpine.
ARG PHP_VERSION=8.5
FROM php:${PHP_VERSION}-fpm-alpine

# What Imagick reads and writes through: Ghostscript renders the first page of a PDF,
# which WordPress shows as its thumbnail, and the heic coder handles HEIC and AVIF. The
# JPEG, WebP and PDF coders follow on their own, once their libraries are there.
RUN apk add --no-cache ghostscript imagemagick imagemagick-heic

# gd is built with AVIF, WebP, JPEG and FreeType. The installer brings each library an
# extension needs, and removes what only building it needed.
COPY --from=mlocati/php-extension-installer:2 /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions bcmath exif gd imagick intl mysqli opcache zip xdebug

# The extensions a project adds, from DOCKER_PHP_EXTENSIONS in its .env: "redis apcu"…
# They get a layer of their own, so that the ones above stay in the cache.
ARG PHP_EXTENSIONS=""
RUN if [ -n "$PHP_EXTENSIONS" ]; then install-php-extensions $PHP_EXTENSIONS; fi

# Composer, and the sendmail of Mailpit, which php.ini hands every email to.
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY --from=axllent/mailpit:v1.31 /mailpit /usr/local/bin/mailpit

# php.ini is not copied here: compose.yaml mounts it, so that a change shows once PHP
# restarts, on vendor/bin/local-environment restart php, without a rebuild.

WORKDIR /app
