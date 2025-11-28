#!/bin/sh

set -e

CERT_DIR="/etc/ssl/mycerts"

# ディレクトリ作成
mkdir -p $CERT_DIR

# 証明書生成
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout $CERT_DIR/server.key \
  -out $CERT_DIR/server.crt \
  -days 365 \
  -subj "/C=JP/ST=Tokyo/L=Tokyo/O=Example/OU=Dev/CN=$DOMAIN_NAME"

chmod 600 $CERT_DIR/server.key
chmod 644 $CERT_DIR/server.crt