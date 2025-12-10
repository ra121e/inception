FROM alpine:3.23

RUN apk update && \
    apk add --no-cache \
      php83 php83-fpm php83-cli php83-phar php83-mysqli php83-json \
      php83-session php83-curl php83-dom php83-xml php83-mbstring php83-zlib \
      php83-ctype \
      bash curl tar

# PHP セッション保存先 + メモリ制限
RUN mkdir -p /var/lib/php83/sessions && \
    chown -R nobody:nobody /var/lib/php83/sessions && \
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

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup_wordpress.sh"]
CMD ["php-fpm83", "-F"]




# FROM alpine:3.18

# # パッケージのインストール: PHP、PHP-FPM、および必要なPHP拡張機能 (MariaDB/MySQL接続用など)
# RUN apk update && \
#     apk add php81 php81-fpm php81-cli php81-phar php81-mysqli php81-json php81-session php81-curl \
#             php81-dom php81-xml php81-mbstring php81-zlib \
#             bash wget curl openssl

# # PHP-FPM設定をコピー (例: www.conf)
# COPY ./conf/www.conf /etc/php8.1/php-fpm.d/www.conf

# # # WordPressのダウンロードとインストール
# # RUN mkdir -p /var/www/html && \
# #     wget https://wordpress.org/latest.tar.gz -P /tmp && \
# #     tar -xzf /tmp/latest.tar.gz -C /tmp && \
# #     mv /tmp/wordpress /var/www/html/wordpress && \
# #     rm /tmp/latest.tar.gz && \
# #     chown -R nobody:nobody /var/www/html/wordpress

# # WordPress設定スクリプトをコピー
# COPY ./tools/setup_wordpress.sh /usr/local/bin/setup_wordpress.sh

# # スクリプトを実行可能にし、セットアップを実行
# RUN chmod +x /usr/local/bin/setup_wordpress.sh

# # PID 1のベストプラクティスに従い、php-fpmをフォアグラウンドで実行 [cite: 105]
# ENTRYPOINT ["/usr/local/bin/setup_wordpress.sh"]
# CMD ["/usr/sbin/php-fpm81", "-F"]
