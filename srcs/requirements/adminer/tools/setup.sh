#!/bin/sh

set -e
# Start both NGINX and PHP-FPM for Adminer
mkdir -p /run/php

# Ensure file permissions are correct
chown -R nginx:nginx /var/www

# Start PHP-FPM in the background
/usr/sbin/php-fpm83 -F &

# Start NGINX in the foreground
echo "Starting NGINX server for Adminer..."
exec /usr/sbin/nginx -g "daemon off;"
