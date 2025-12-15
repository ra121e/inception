#!/bin/bash
set -e

WP_PATH="/var/www/html/wordpress"
PHP_FPM_USER="www"
PHP_FPM_GROUP="www"

# --- 追加: ボリュームマウント時に権限を PHP-FPM に合わせる ---
mkdir -p "${WP_PATH}"

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

# credentials.txt から管理者/一般ユーザのパスワードを取得（1 行目 admin, 2 行目 user）
CRED_FILE="/run/secrets/credentials"
WP_ADMIN_PASS=""
WP_USER_PASS=""
if [ -f "${CRED_FILE}" ]; then
  WP_ADMIN_PASS=$(sed -n '1p' "${CRED_FILE}")
  WP_USER_PASS=$(sed -n '2p' "${CRED_FILE}")
fi

# .env から WordPress 用の各種情報
WP_TITLE=${WP_TITLE:-"Inception Blog"}
WP_ADMIN_USER=${WP_ADMIN_USER:-"superboss"}
WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL:-"admin@example.com"}
WP_USER_NAME=${WP_USER:-"normaluser"}
WP_USER_EMAIL=${WP_USER_EMAIL:-"user@example.com"}

WP_URL="https://${DOMAIN_NAME}"

cd "${WP_PATH}"

# すでにインストール済みかどうか
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "[wp-setup] Downloading WordPress via wp-cli..."
  wp core download --allow-root

#  # ダウンロード直後に権限を PHP-FPM に合わせる
#  chown -R nobody:nobody "${WP_PATH}"
#  find "${WP_PATH}" -type d -exec chmod 755 {} \;
#  find "${WP_PATH}" -type f -exec chmod 644 {} \;

  echo "[wp-setup] Creating wp-config.php via wp-cli..."
  wp config create \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASSWORD}" \
    --dbhost="${DB_HOST}:${DB_PORT}" \
    --allow-root

  echo "[wp-setup] Running core install..."
  wp core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASS}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --allow-root

  if [ -n "${WP_USER_NAME}" ] && [ -n "${WP_USER_EMAIL}" ] && [ -n "${WP_USER_PASS}" ]; then
    echo "[wp-setup] Creating regular user ${WP_USER_NAME}..."
    wp user create "${WP_USER_NAME}" "${WP_USER_EMAIL}" \
      --user_pass="${WP_USER_PASS}" \
      --role=contributor \
      --allow-root
  fi

  # URL や HTTPS 関連は wp-cli で更新
  wp option update home "${WP_URL}" --allow-root
  wp option update siteurl "${WP_URL}" --allow-root

  # HTTPS を強制するための定数を wp-config.php に追記
  wp config set FORCE_SSL_ADMIN true --raw --type=constant --allow-root
  wp config set WP_HOME "${WP_URL}" --type=constant --allow-root
  wp config set WP_SITEURL "${WP_URL}" --type=constant --allow-root
  wp config set FS_METHOD direct --type=constant --allow-root

  # --- 所有者を PHP-FPM ユーザーに変更 ---
  chown -R ${PHP_FPM_USER}:${PHP_FPM_GROUP} "${WP_PATH}"
  find "${WP_PATH}" -type d -exec chmod 755 {} \;
  find "${WP_PATH}" -type f -exec chmod 644 {} \;
fi

echo "Starting php-fpm..."
exec "$@"
