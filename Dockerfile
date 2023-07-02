ARG ALPINE_VERSION=latest
FROM alpine:${ALPINE_VERSION}
WORKDIR /var/www/html
RUN apk add --no-cache \
  curl \
  nginx \
  php81 \
  php81-ctype \
  php81-fileinfo \
  php81-zip \
  php81-curl \
  php81-dom \
  php81-fpm \
  php81-gd \
  php81-intl \
  php81-mbstring \
  php81-opcache \
  php81-openssl \
  php81-phar \
  php81-session \
  php81-tokenizer \
  php81-xml \
  php81-xmlreader \
  php81-zlib \
  supervisor

# Create symlink so programs depending on `php` still function
RUN ln -s /usr/bin/php81 /usr/bin/php

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php81/php-fpm.d/www.conf
COPY config/php.ini /etc/php81/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Download 
ARG DIRECTORYLISTER_VERSION=3.12.3
ADD https://github.com/DirectoryLister/DirectoryLister/releases/download/$DIRECTORYLISTER_VERSION/DirectoryLister-$DIRECTORYLISTER_VERSION.tar.gz /tmp/DirectoryLister.tar.gz

RUN tar -xf /tmp/DirectoryLister.tar.gz -C /var/www/html/

RUN rm -Rf /tmp/DirectoryLister.tar.gz

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
