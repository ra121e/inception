#!/bin/bash
set -e

SSL_DIR="/etc/nginx/ssl"
mkdir -p "${SSL_DIR}"

if [ ! -f "${SSL_DIR}/server.key" ] || [ ! -f "${SSL_DIR}/server.crt" ]; then
  openssl req -x509 -nodes -days 365 \
    -subj "/C=FR/ST=Paris/L=Paris/O=42School/OU=Inception/CN=${DOMAIN_NAME:-localhost}" \
    -newkey rsa:2048 \
    -keyout "${SSL_DIR}/server.key" \
    -out "${SSL_DIR}/server.crt"
fi
