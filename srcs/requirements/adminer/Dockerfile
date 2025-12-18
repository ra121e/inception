FROM alpine:3.23

# Install necessary packages: PHP and extensions for Adminer (MySQL/MariaDB driver)
# Adminer is a single PHP file, so we need PHP-FPM and a minimal web server.
RUN apk update && apk add --no-cache \
    nginx wget ca-certificates \
    php83 php83-fpm php83-mysqli php83-session php83-opcache \
    php83-iconv php83-json php83-ctype php83-curl php83-dom \
    php83-xml php83-zip php83-pdo_mysql

RUN mkdir -p /run/php

# Download Adminer single file (latest version at the time of writing)
RUN wget -O /var/www/adminer.php "https://www.adminer.org/latest.php"

# Set up NGINX and PHP-FPM configuration
RUN mkdir -p /etc/nginx/conf.d

# Copy configuration files and setup script
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/adminer.conf /etc/nginx/http.d/adminer.conf
COPY tools/setup.sh /usr/local/bin/setup.sh

# Cleanup default configuration
RUN rm -f /etc/nginx/conf.d/default.conf

# Set permissions
RUN chown -R nginx:nginx /var/www

# Give execution rights to the setup script
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 8080

CMD ["/usr/local/bin/setup.sh"]