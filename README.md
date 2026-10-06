<h1 align="center">
    OffsetWP Local Environment
</h1>

<p align="center">
	The local server of an <a href="https://github.com/offsetwp">OffsetWP</a> project, on Docker.
</p>

<br/>

- 🌐 Caddy, serving the site over HTTP, or over HTTPS from a local authority, HTTP/3 included
- 🐘 PHP 8.5 FPM on Alpine, or another version, with the extensions of the official WordPress image, Composer and Xdebug
- 🗄️ MariaDB 11.8, or the MySQL or MariaDB of your production, published for a client
- ✉️ Mailpit, catching every email WordPress sends
- 📦 Nothing in the project: the stack runs from `vendor/`, set from `.env`, until you extract it

## Requirements

- [Docker](https://docs.docker.com/get-started/get-docker/) with Compose
- An OffsetWP project, such as one created from
  [offsetwp/project-skeleton](https://github.com/offsetwp/project-skeleton)

## Installation

The site answers on the address `WP_HOME` gives, in the `.env` of the project:

```dotenv
# .env
WP_HOME='http://localhost' # Over HTTPS, see HTTPS section; on other ports, see Custom ports section.
```

```bash
composer require --dev offsetwp/local-environment
vendor/bin/local-environment up
vendor/bin/local-environment wp core install --url=http://localhost --title="My project" \
	--admin_user=admin --admin_password='change-me' --admin_email=admin@example.com
```

By default, the stack exposes:

- The site: http://localhost, on port 80 (Over HTTPS, see HTTPS section)
- MariaDB: `127.0.0.1:3306`
  - User: `root`
  - Password: `DB_PASSWORD` of `.env` (`root` without it)
  - Database: `DB_DATABASE` of `.env` (`wordpress` without it)
- Mailpit: http://localhost:8025
  - No login: the inbox opens as it is
  - SMTP: `mailpit:1025`, inside the stack only: PHP hands it every email, with nothing to set

## HTTPS

Caddy serves the site over HTTPS once `WP_HOME` starts with `https://`, HTTP/3 included, with a certificate signed by a local authority of its own:

```dotenv
# .env
WP_HOME='https://localhost'
```

```bash
vendor/bin/local-environment up
vendor/bin/local-environment trust       # once: this computer trusts https://localhost
```

The site answers on https://localhost, and http://localhost redirects there. It works over HTTPS at once, and the browser warns about it until this computer trusts the authority of Caddy — the one change the stack makes to the computer, and an optional one. `trust` adds it to the system keychain on macOS, with sudo. On Linux and Windows, it copies it to `var/caddy-root.crt`, to import into the certificate store of the system, or of the browser. Firefox keeps a store of its own.

Every project creates its own authority, to trust once: `down -v` deletes it, and the new one needs `trust` again. To remove one from the keychain:

```bash
sudo security delete-certificate -c "Caddy Local Authority - 2026 ECC Root" /Library/Keychains/System.keychain
```

Back on `http://`, the browser may still follow the redirection to HTTPS it remembers: clearing its cache forgets it.

## Custom ports

The site takes ports 80 and 443 of this computer. When another server holds them, or for a second project at once, give the stack others, in `.env`:

```dotenv
WP_HOME='http://localhost:8000'   # or 'https://localhost:8443'
DOCKER_HTTP_PORT=8000
DOCKER_HTTPS_PORT=8443
```

Caddy listens on the port of `WP_HOME`, 80 or 443 when it has none: `DOCKER_HTTP_PORT` over HTTP; `DOCKER_HTTPS_PORT` over HTTPS, where `DOCKER_HTTP_PORT` redirects to `WP_HOME`. When they disagree, Caddy refuses to start, and says so along with the failure of `up`. Docker publishes both ports either way. Rootless Docker publishes no port below 1024: it needs others, as above.

The database and Mailpit have ports of their own, 3306 and 8025:

```dotenv
DB_HOST='127.0.0.1:3307'          # for wp-cli run from this computer
DOCKER_DATABASE_PORT=3307
DOCKER_MAILPIT_PORT=8125
```

## Commands

They run from the root of the project, wherever they are called from:

```bash
vendor/bin/local-environment up                  # start the stack, building the PHP image the first time
vendor/bin/local-environment up --build          # rebuild the PHP image, then start
vendor/bin/local-environment wp user list --format=json
vendor/bin/local-environment composer update
vendor/bin/local-environment trust               # over HTTPS: make this computer trust the certificates of Caddy
vendor/bin/local-environment extract             # copy compose.yaml and docker/ into the project
```

Anything else goes to `docker compose`, with the right files: `vendor/bin/local-environment down`, `ps`, `logs -f caddy`, `exec database mariadb -uroot -p`… An alias saves typing: `alias local-environment='vendor/bin/local-environment'`.

wp-cli also runs from this computer, as `php bin/wp-cli`: `DB_HOST='127.0.0.1'` reaches the database the stack publishes. Inside the stack, `DB_HOST` is `database`, whatever `.env` says.

## Configuration

The stack runs from `vendor/offsetwp/local-environment`, the root of the project as its directory, and needs no file of its own in the project. It is set from the `.env` of the project, where a missing variable takes the value below. A change shows on the next `up`:

```dotenv
# .env

# The address of the site: its scheme, its name, its port. See HTTPS and Custom ports.
WP_HOME='http://localhost'

# The ports, on this computer. See Custom ports.
DOCKER_HTTP_PORT=80
DOCKER_HTTPS_PORT=443
DOCKER_DATABASE_PORT=3306
DOCKER_MAILPIT_PORT=8025

# The database. MariaDB runs as root, so DB_USERNAME stays root, and it reads the name and
# the password on its first start only: after a change, down -v starts it over, empty.
DB_DATABASE='wordpress'
DB_USERNAME='root'
DB_PASSWORD='root'

# The owner of the files PHP writes, on Linux.
DOCKER_UID=1000
DOCKER_GID=1000

# Xdebug: off, develop, debug, profile, trace or coverage.
XDEBUG_MODE='off'

# The PHP limits. The upload one covers POST too.
DOCKER_PHP_MEMORY_LIMIT='256M'
DOCKER_PHP_UPLOAD_MAX_SIZE='64M'
DOCKER_PHP_MAX_EXECUTION_TIME=120

# More PHP extensions, such as 'redis apcu'. They show on up --build.
DOCKER_PHP_EXTENSIONS=''

# The PHP version, and the database image. See Changing the images.
DOCKER_PHP_VERSION='8.5'
DOCKER_DATABASE_IMAGE='mariadb:11.8'
```

Anything else — a php.ini, the Caddyfile, a service, an image… — goes in `compose.override.yaml`, at the root of the project, merged into the stack the way Docker Compose merges it anywhere. For instance, PHP settings of your own:

```yaml
# compose.override.yaml
services:
  php:
    volumes:
      - ./php.ini:/usr/local/etc/php/conf.d/zz-local.ini:ro
```

## Extracting the stack

To change the files themselves — the Dockerfile, the Caddyfile, the check Caddy starts with — copy them into the project:

```bash
vendor/bin/local-environment extract     # compose.yaml and docker/, at the root of the project
vendor/bin/local-environment up --build
```

`vendor/bin/local-environment` runs them from then on, and so does plain `docker compose`, which merges `compose.override.yaml` on its own. The project keeps its name, and with it its database and its certificates. A change to `docker/php/php.ini` shows once PHP restarts, on `vendor/bin/local-environment restart php`, and one to the Caddyfile or `caddy.sh` on `restart caddy`: `up` leaves a running service as it is, unless its configuration changes. One to the Dockerfile needs `up --build`.

## Services

| Service | What | Where |
| --- | --- | --- |
| `caddy` | [Caddy](https://caddyserver.com), serving `public/` over HTTP, or over HTTPS with HTTP/3 | `WP_HOME`, http://localhost by default |
| `php` | PHP 8.5 FPM on Alpine, or the version of `DOCKER_PHP_VERSION`, with the extensions of the official WordPress image — GD with AVIF and WebP, Imagick, intl… — along with Composer, and Xdebug, off | |
| `network` | The network `caddy` and `php` share, and the ports of the site: WordPress reaches itself on `WP_HOME`, for WP-Cron and Site Health, and either service restarts without cutting the other off | |
| `database` | MariaDB 11.8, or the image of `DOCKER_DATABASE_IMAGE` | `127.0.0.1:3306`, user `root`, with the password and the database of `.env` |
| `mailpit` | [Mailpit](https://mailpit.axllent.org): every email WordPress sends lands there | http://localhost:8025 |

## Volumes

The project is mounted as it is: a change shows on the next request. The database and the certificates live in Docker volumes, which `down` keeps. `down -v` deletes them: the database starts empty again, and the new authority needs `trust`. The volumes are named after the folder of the project: renamed, it starts on an empty database, the old one still listed by `docker volume ls`.

## Changing the images

PHP 8.5 and MariaDB 11.8 serve by default. Another version tests an upgrade before it ships, or matches the production server.

### PHP

`DOCKER_PHP_VERSION` takes a tag of the [official PHP image](https://hub.docker.com/_/php), as `php:<version>-fpm-alpine`:

```dotenv
# .env
DOCKER_PHP_VERSION='8.1'      # or '8.4', '8.4.12' for an exact release, '8.6-rc' for the next one
```

```bash
vendor/bin/local-environment up                  # builds the image of that version, the first time
vendor/bin/local-environment exec php php -v
```

Every version gets an image of its own: the next `up` builds a new one, with no `--build`, and going back to a version built before starts at once. A change to `DOCKER_PHP_EXTENSIONS` still needs `up --build`, which rebuilds the current version only. The images stay until removed, a few hundred megabytes each: `docker image rm <project>-php:8.1`, `<project>` being the folder of the project.

The project has to accept that version too: Composer refuses one outside the `php` constraint of `composer.json`, such as 8.1 against the `^8.5` of the skeleton. A release candidate builds once the [extension installer](https://github.com/mlocati/docker-php-extension-installer) supports its version: until then, the build stops on the first extension it cannot install.

### Database

`DOCKER_DATABASE_IMAGE` takes a MariaDB or MySQL image, the closest to the production server:

```dotenv
# .env
DOCKER_DATABASE_IMAGE='mysql:8.4'      # or 'mysql:8.0', 'mariadb:10.11'…
```

The data belongs to the image that created it: MySQL does not read the files of MariaDB, nor an older version those of a newer one. Changing the image means starting on an empty database, the current one deleted:

```bash
vendor/bin/local-environment down -v     # deletes the database, and the certificates of Caddy
vendor/bin/local-environment up
```

Then import a dump, of the production on `127.0.0.1:3306`. Over HTTPS, the new authority of Caddy needs `trust` again.

The client of the container is `mysql` in a MySQL image, `mariadb` in a MariaDB one: `exec database mysql -uroot -p`. `mysql:5.7` has no image for Apple Silicon: `platform: linux/amd64` runs the Intel one, under emulation:

```yaml
# compose.override.yaml
services:
  database:
    platform: linux/amd64
```
