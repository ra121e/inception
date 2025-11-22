FROM alpine:3.18 

# パッケージのインストール: PHP、PHP-FPM、および必要なPHP拡張機能 (MariaDB/MySQL接続用など)
RUN apk update && \
    apk add php php-fpm php-mysqli php-json php-session php-curl php-dom php-xml php-mbstring php-zlib \
    wget bash

# PHP-FPM設定をコピー (例: www.conf)
COPY ./conf/www.conf /etc/php8/php-fpm.d/www.conf

# WordPressのダウンロードとインストール
RUN wget https://wordpress.org/latest.tar.gz -P /tmp && \
    tar -xzf /tmp/latest.tar.gz -C /var/www/html/ && \
    rm /tmp/latest.tar.gz && \
    chown -R nobody:nobody /var/www/html/wordpress

# WordPress設定スクリプトをコピー
COPY ./tools/setup_wordpress.sh /usr/local/bin/setup_wordpress.sh

# スクリプトを実行可能にし、セットアップを実行
RUN chmod +x /usr/local/bin/setup_wordpress.sh

# /var/www/html/wordpressをWordPressファイルのボリュームとして定義 [cite: 90]
VOLUME /var/www/html/wordpress

# PID 1のベストプラクティスに従い、php-fpmをフォアグラウンドで実行 [cite: 105]
ENTRYPOINT ["/usr/local/bin/setup_wordpress.sh"]
CMD ["/usr/sbin/php-fpm8", "-F"]