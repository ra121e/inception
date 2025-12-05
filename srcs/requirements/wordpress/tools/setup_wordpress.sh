#!/bin/bash
set -e

WP_PATH="/var/www/html/wordpress"

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

define( 'WP_HOME', 'https://localhost:8443' );
define( 'WP_SITEURL', 'https://localhost:8443' );
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


# #!/bin/bash
# set -e

# WP_DIR="/var/www/html/wordpress"
# WP_CONFIG="${WP_DIR}/wp-config.php"


# export WP_MEMORY_LIMIT=512M
# php -d memory_limit=512M /var/www/html/wp-cli.phar core download --allow-root
# php -d memory_limit=512M /var/www/html/wp-cli.phar config create \
#     --dbname="$WORDPRESS_DB_NAME" \
#     --dbuser="$WORDPRESS_DB_USER" \
#     --dbpass="$WORDPRESS_DB_PASSWORD" \
#     --dbhost="$WORDPRESS_DB_HOST" \
#     --allow-root
# php -d memory_limit=512M /var/www/html/wp-cli.phar core install \
#     --url=localhost \
#     --title=inception \
#     --admin_user=admin \
#     --admin_password=admin \
#     --admin_email=admin@admin.com \
#     --allow-root

# cd /var/www/html
# curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
# chmod +x wp-cli.phar
# ./wp-cli.phar core download --allow-root
# ./wp-cli.phar config create --dbname=wordpress --dbuser=wordpress --dbpass=wordpress --dbhost=db --allow-root
# ./wp-cli.phar core install --url=localhost --title=inception --admin_user=admin --admin_password=admin --admin_email=admin@admin.com --allow-root



# # # 初回のみ設定
# # if [ ! -f "$WP_CONFIG" ]; then
# #     echo "WordPress 初期設定を開始します..."

# #     # 確実にサンプルファイルが存在するかチェック
# #     if [ ! -f "$WP_DIR/wp-config-sample.php" ]; then
# #         echo "Error: wp-config-sample.php が見つかりません: $WP_DIR"
# #         exit 1
# #     fi


# #     # 必須環境変数チェック
# #     : "${WORDPRESS_DB_HOST:?WORDPRESS_DB_HOSTが未設定です}"
# #     : "${WORDPRESS_DB_NAME:?WORDPRESS_DB_NAMEが未設定です}"
# #     : "${WORDPRESS_DB_USER:?WORDPRESS_DB_USERが未設定です}"
# #     : "${WORDPRESS_DB_PASSWORD:?WORDPRESS_DB_PASSWORDが未設定です}"

# #     # wp-config.php生成
# #     cp "${WP_DIR}/wp-config-sample.php" "$WP_CONFIG"
# #     sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" "$WP_CONFIG"
# #     sed -i "s/username_here/$WORDPRESS_DB_USER/" "$WP_CONFIG"
# #     sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" "$WP_CONFIG"
# #     sed -i "s/localhost/$WORDPRESS_DB_HOST/" "$WP_CONFIG"

# #     # 権限設定
# #     chown -R nobody:nobody "$WP_DIR"

# #     echo "WordPress の初期設定が完了しました。"
# # else
# #     echo "WordPress はすでに設定済みです。"
# # fi

# # CMD引数（php-fpm）をフォアグラウンドで実行
# # exec "$@"

# php-fpm8.1 -F
