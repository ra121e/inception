#!/bin/bash
set -e

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

ROOT_PWD_FILE="/run/secrets/db_root_password"
USER_PWD_FILE="/run/secrets/db_password"

if [ ! -f "${ROOT_PWD_FILE}" ]; then
  echo "Database root password secret not found"
  exit 1
fi
if [ ! -f "${USER_PWD_FILE}" ]; then
  echo "Database user password secret not found"
  exit 1
fi

MYSQL_ROOT_PASSWORD=$(cat "${ROOT_PWD_FILE}")
MYSQL_USER_PASSWORD=$(cat "${USER_PWD_FILE}")




# 環境変数からWP用のDB名とユーザー名を取得 (.env で定義している想定)
MYSQL_DATABASE="${MYSQL_DATABASE:-wordpress}"
MYSQL_USER="${MYSQL_USER:-wpuser}"

FIRST_INIT=false
if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Initializing MariaDB data directory..."
  mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql > /dev/null
  FIRST_INIT=true
fi

echo "Starting MariaDB..."
# 通常モードでmysqldをバックグラウンド起動
mysqld --user=mysql --console &
MYSQLD_PID=$!

echo "Waiting for MariaDB to be ready..."
# 起動待ち
until mysqladmin ping -uroot --silent; do
  sleep 1
done

echo "MariaDB is up. Running initialization SQL..."

if [ "$FIRST_INIT" = true ]; then
  # 1回目だけroot初期化と不要なもの削除
  mysql -uroot <<-EOSQL
    -- rootパスワード設定（ローカルからのみ）
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

    -- 匿名ユーザー削除
    DELETE FROM mysql.user WHERE User='';

    -- test DB削除
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
    FLUSH PRIVILEGES;
EOSQL
fi

# WP用DB/ユーザーが無ければ作成（idempotentに）
mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
  CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
  GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
  FLUSH PRIVILEGES;
EOSQL

echo "Initialization SQL completed. Bringing mysqld to foreground..."
wait "$MYSQLD_PID"