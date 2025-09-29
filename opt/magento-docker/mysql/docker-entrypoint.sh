#!/bin/bash
set -euo pipefail

if [[ "${1}" == "mysqld" ]]; then
  if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initializing MySQL data directory"
    mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
  fi

  chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

  if [ -n "${MYSQL_ROOT_PASSWORD:-}" ]; then
    tfile=$(mktemp)
    cat <<SQL > "$tfile"
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER:-magento}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD:-magento}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE:-magento}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE:-magento}\`.* TO '${MYSQL_USER:-magento}'@'%';
FLUSH PRIVILEGES;
SQL
    set -- "$@" --init-file="$tfile"
  fi

  exec gosu mysql "$@"
fi

exec "$@"
