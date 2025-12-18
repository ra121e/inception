FROM alpine:3.23

# Install NGINX
RUN apk update && apk add --no-cache nginx

# Set up static content directory
RUN mkdir -p /var/www/static

# Copy configuration, setup script, and static files
COPY conf/static.conf /etc/nginx/http.d/static.conf
COPY tools/setup.sh /usr/local/bin/setup.sh
COPY static_files /var/www/static/

# Cleanup default configuration
RUN rm -f /etc/nginx/conf.d/default.conf

# Set permissions
RUN chown -R nginx:nginx /var/www/static

# Give execution rights to the setup script
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 8081

CMD ["/usr/local/bin/setup.sh"]