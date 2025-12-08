#!/bin/bash
set -e

WP_PATH="/var/www/html/wordpress"

# .env から来る DOMAIN_NAME。なければ localhost にする
DOMAIN_NAME=${DOMAIN_NAME:-localhost}

# DB 接続情報（.env と secrets から）
DB_HOST=${DB_HOST:-mariadb}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${MYSQL_DATABASE:-wordpress}
DB_USER=${MYSQL_USER:-wpuser}

DB_PWD_FILE="/run/secrets/db_password"
if [ ! -f "${DB_PWD_FILE}" ]; then
  echo "WordPress DB password secret not found"
  exit 1
fi
DB_PASSWORD=$(cat "${DB_PWD_FILE}")

mkdir -p /var/www/html

if [ ! -f "${WP_PATH}/wp-config.php" ]; then
  echo "Downloading WordPress..."
  TMP_FILE="/tmp/wordpress.tar.gz"
  curl -fSL https://wordpress.org/latest.tar.gz -o "${TMP_FILE}"
  tar -xzf "${TMP_FILE}" -C /var/www/html
  rm -f "${TMP_FILE}"

  chown -R nobody:nobody /var/www/html

  cd "${WP_PATH}"

  echo "Creating wp-config.php (custom minimal)..."

  # ユニークキー・ソルトを取得して変数に保持
  SALT=$(php -r "echo file_get_contents('https://api.wordpress.org/secret-key/1.1/salt/');")

  cat > wp-config.php <<EOF
<?php
define( 'DB_NAME', '${DB_NAME}' );
define( 'DB_USER', '${DB_USER}' );
define( 'DB_PASSWORD', '${DB_PASSWORD}' );
define( 'DB_HOST', '${DB_HOST}:${DB_PORT}' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

${SALT}

\$table_prefix = 'wp_';

define( 'WP_DEBUG', false );

define( 'WP_HOME', 'https://${DOMAIN_NAME}' );
define( 'WP_SITEURL', 'https://${DOMAIN_NAME}' );
define( 'FORCE_SSL_ADMIN', true );
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    \$_SERVER['HTTPS'] = 'on';
}

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
EOF
fi

echo "Starting php-fpm..."
exec "$@"
