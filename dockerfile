FROM alpine:latest

RUN apk update && apk add nginx

RUN mkdir -p /run/nginx

COPY ./html /usr/share/nginx/html

CMD ["nginx", "-g", "daemon off;"]
