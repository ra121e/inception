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

# 1. データの初期化チェック（ボリュームが空の場合のみ実行）
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # 設定用の一時的な起動（& でバックグラウンドへ）
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    pid="$!"

    # 起動待ち
    until mysqladmin ping > /dev/null 2>&1; do
        sleep 1
    done

    # SQL実行（初期設定、セキュリティ向上、WP用DB作成をすべてここで！）
    mysql -uroot << EOSQL
        -- セキュリティ設定
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        DELETE FROM mysql.user WHERE User='';
        DROP DATABASE IF EXISTS test;
        -- WordPress用DB/ユーザー作成
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
  CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL

    # 一時的なmysqldを安全に停止
    kill "$pid"
    wait "$pid"
    echo "MariaDB initial configuration completed."
fi

# ---------------------------------------------------------
# 【最重要】PID 1 を mysqld に引き継ぐ
# ---------------------------------------------------------
echo "Starting MariaDB in foreground..."
# exec を使うことで、このシェルスクリプトが mysqld プロセスに「変身」します
exec mysqld --user=mysql --datadir=/var/lib/mysql --console
