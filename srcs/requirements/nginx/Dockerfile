FROM alpine:3.22

RUN apk update && \
    apk add --no-cache nginx openssl bash

RUN mkdir -p /run/nginx /etc/nginx/ssl

COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY ./tools/init_ssl.sh /usr/local/bin/init_ssl.sh
RUN chmod +x /usr/local/bin/init_ssl.sh

# ビルド時に自己署名証明書を生成（本番ではボリュームマウントを推奨）
RUN /usr/local/bin/init_ssl.sh

CMD ["nginx", "-g", "daemon off;"]
