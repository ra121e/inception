FROM alpine:3.23

RUN apk update && \
    apk add --no-cache \
      php83 php83-fpm php83-cli php83-phar php83-mysqli php83-json \
      php83-session php83-curl php83-dom php83-xml php83-mbstring php83-zlib \
      php83-ctype php83-tokenizer php83-gd \
      bash curl tar

# --- PHP-FPM 用ユーザー作成 ---
RUN addgroup -S www && adduser -S -G www www

# PHP セッション保存先 + メモリ制限
RUN mkdir -p /var/lib/php83/sessions && \
    chown -R www:www /var/lib/php83/sessions && \
    ln -s /usr/bin/php83 /usr/local/bin/php && \
    echo "session.save_path = /var/lib/php83/sessions" >> /etc/php83/php.ini && \
    echo "memory_limit = 256M" >> /etc/php83/php.ini

# PHP-FPM 設定
RUN mkdir -p /run/php83
COPY ./conf/www.conf /etc/php83/php-fpm.d/www.conf

# wp-cli 本体をインストール
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

# WordPress セットアップスクリプト
COPY ./tools/setup_wordpress.sh /usr/local/bin/setup_wordpress.sh
RUN chmod +x /usr/local/bin/setup_wordpress.sh

WORKDIR /var/www/html

ENTRYPOINT ["/usr/local/bin/setup_wordpress.sh"]
CMD ["php-fpm83", "-F"]
