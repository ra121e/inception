#!/bin/bash
set -e

# Secrets
ROOT_PWD_FILE="/run/secrets/db_root_password"
USER_PWD_FILE="/run/secrets/db_password"

if [ ! -f "${ROOT_PWD_FILE}" ] || [ ! -f "${USER_PWD_FILE}" ]; then
  echo "Database password secrets not found"
  exit 1
fi

MYSQL_ROOT_PASSWORD=$(cat "${ROOT_PWD_FILE}")
MYSQL_PASSWORD=$(cat "${USER_PWD_FILE}")

MYSQL_DATABASE=${MYSQL_DATABASE:-wordpress}
MYSQL_USER=${MYSQL_USER:-wpuser}

# 初回かどうか判定
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Initializing MariaDB data directory..."
  mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql > /dev/null

  mysqld --user=mysql --bootstrap <<-EOSQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
    DELETE FROM mysql.user WHERE User='';
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    FLUSH PRIVILEGES;
EOSQL
fi

echo "Starting MariaDB..."
exec mysqld --user=mysql --console