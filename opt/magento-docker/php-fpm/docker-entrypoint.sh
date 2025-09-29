#!/bin/bash
set -euo pipefail

PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-2048M}

for ini in /etc/php/8.3/fpm/conf.d/99-magento.ini /etc/php/8.3/cli/conf.d/99-magento.ini; do
  sed -i "s/^memory_limit = .*/memory_limit = ${PHP_MEMORY_LIMIT}/" "$ini"
done

mkdir -p /var/www/html/var /var/www/html/generated /var/www/html/pub/static /var/www/html/pub/media
chown -R test-ssh:clp /var/www/html

service cron start

if [[ "${1}" == php-fpm8.3* ]]; then
  exec "$@"
fi

exec "$@"
