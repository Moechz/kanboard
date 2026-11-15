#!/bin/sh
# ===========================================================================
# Kanboard entrypoint for a non-root container (TOS 7 requirement).
#
# The image runs Apache on port 80, which uid 1000 cannot bind. This wrapper
# serves the same PHP application with the built-in PHP web server on port 8080
# and keeps the SQLite database and plugins on the mounted volumes.
# ===========================================================================
set -e
set -u

mkdir -p /var/www/app/data /var/www/app/plugins 2>/dev/null || true

if ! ( : > /var/www/app/data/.write-test ) 2>/dev/null; then
  echo "kanboard: data folder is not writable by uid $(id -u)" >&2
  exit 1
fi
rm -f /var/www/app/data/.write-test

cd /var/www/app
exec php -S 0.0.0.0:8080 -t /var/www/app
