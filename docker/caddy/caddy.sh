#!/bin/sh
#
# Starts Caddy on the address of WP_HOME, once Docker publishes its port.
#
# Caddy listens on the port of WP_HOME, 80 or 443 when it has none, and Docker publishes
# DOCKER_HTTP_PORT and DOCKER_HTTPS_PORT, on the same ports in the container. When the
# port of WP_HOME is not the one its scheme publishes, the site is out of reach, with no
# error to say why: better to refuse to start, and to say what to change.

set -eu

case $WP_HOME in
  http://*) name=DOCKER_HTTP_PORT published=$DOCKER_HTTP_PORT default=80 ;;
  https://*) name=DOCKER_HTTPS_PORT published=$DOCKER_HTTPS_PORT default=443 ;;
  *)
    echo "WP_HOME is $WP_HOME: it starts with http://, or with https:// for Caddy to serve the site over HTTPS. Change it in .env." >&2
    exit 1
    ;;
esac

# The scheme, the name and the port of WP_HOME, without its path: Caddy would read a path,
# a trailing slash included, as the only one to serve.
SITE_ADDRESS=$(echo "$WP_HOME" | sed -E 's#^(https?://[^/]+).*#\1#')
port=$(echo "$SITE_ADDRESS" | sed -nE 's#^https?://[^:]+:([0-9]+)$#\1#p')

if [ "${port:-$default}" != "$published" ]; then
  echo "WP_HOME is $WP_HOME, on port ${port:-$default}, but Docker publishes $name, $published. Give them the same port, in .env." >&2
  exit 1
fi

export SITE_ADDRESS
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
