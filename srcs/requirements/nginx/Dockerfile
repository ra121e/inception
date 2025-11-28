FROM alpine:3.18 

# パッケージのインストール
RUN apk update && \
    apk add nginx openssl bash

# NGINX設定ファイルとSSL証明書生成スクリプトをコンテナにコピー
# 設定ファイルは、TLSv1.2またはTLSv1.3のみを使用するように構成されている必要があります [cite: 86]
COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY ./tools/init_ssl.sh /usr/local/bin/init_ssl.sh

# SSL証明書を生成するためのスクリプトを実行し、実行可能にします
RUN chmod +x /usr/local/bin/init_ssl.sh
RUN /usr/local/bin/init_ssl.sh

CMD ["nginx", "-g", "daemon off;"]