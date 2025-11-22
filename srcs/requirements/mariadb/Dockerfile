FROM alpine:3.18 

# パッケージのインストール: MariaDBとクライアント
RUN apk update && \
    apk add mariadb mariadb-client bash

# MariaDB設定ファイル (例: my.cnf) をコピー
COPY ./conf/50-server.cnf /etc/my.cnf.d/50-server.cnf

# データベース初期化スクリプトをコピー
# このスクリプトは、データベース、ユーザー、および管理者ユーザーを作成します [cite: 106]
# 管理者ユーザー名には 'admin' や 'administrator' を含んではいけません [cite: 107]
COPY ./tools/setup_db.sh /usr/local/bin/setup_db.sh

# スクリプトを実行可能に
RUN chmod +x /usr/local/bin/setup_db.sh

# MariaDBデータディレクトリをデータベースボリュームとして定義 
VOLUME /var/lib/mysql

# PID 1のベストプラクティスに従い、デーモンが停止しないようにmariadbdをフォアグラウンドで実行 [cite: 105]
# 環境変数を利用して、初期セットアップ中にデータベースとユーザーを作成
CMD ["/usr/local/bin/setup_db.sh"]