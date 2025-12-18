FROM alpine:3.23

RUN apk update && \
    apk add --no-cache mariadb mariadb-client bash

# MariaDB 設定ファイルを /etc/my.cnf に配置（mysqld が必ず読む場所）
COPY ./conf/50-server.cnf /etc/my.cnf

# 初期化スクリプト
COPY ./tools/setup_db.sh /usr/local/bin/setup_db.sh
RUN chmod +x /usr/local/bin/setup_db.sh

VOLUME /var/lib/mysql

CMD ["/usr/local/bin/setup_db.sh"]
