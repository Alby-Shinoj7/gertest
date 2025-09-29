FROM debian:12.2-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg2 unzip git libicu72 libxml2 libzip4 libjpeg62-turbo libpng16-16 libfreetype6 libxslt1.1 libonig5 libwebp7 libmagickwand-6.q16-6 \
    && curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/sury.gpg \
    && echo "deb https://packages.sury.org/php/ bookworm main" > /etc/apt/sources.list.d/php.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends php8.3 php8.3-cli php8.3-fpm php8.3-bcmath php8.3-common php8.3-curl php8.3-gd php8.3-intl php8.3-mbstring php8.3-mysql php8.3-soap php8.3-xml php8.3-xsl php8.3-zip php8.3-opcache php8.3-sockets php8.3-simplexml php8.3-imagick php8.3-pcntl php8.3-fileinfo php8.3-readline php8.3-redis \
    && apt-get install -y --no-install-recommends supervisor cron openssh-client default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1000 clp \
    && useradd -u 1000 -g clp -m -s /bin/bash test-ssh

RUN mkdir -p /var/www/html /var/log/php8.3-fpm \
    && chown -R test-ssh:clp /var/www/html /var/log/php8.3-fpm

RUN sed -i 's|^user = www-data|user = test-ssh|' /etc/php/8.3/fpm/pool.d/www.conf \
    && sed -i 's|^group = www-data|group = clp|' /etc/php/8.3/fpm/pool.d/www.conf \
    && sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/8.3/fpm/pool.d/www.conf \
    && sed -i 's|^;listen.allowed_clients = 127.0.0.1|listen.allowed_clients = 0.0.0.0|' /etc/php/8.3/fpm/pool.d/www.conf

RUN sed -i 's|;daemonize = yes|daemonize = no|' /etc/php/8.3/fpm/php-fpm.conf

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY php.ini /etc/php/8.3/fpm/conf.d/99-magento.ini
COPY php.ini /etc/php/8.3/cli/conf.d/99-magento.ini
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /var/www/html

ENV PATH="/var/www/html/bin:$PATH"

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["php-fpm8.3", "-F"]
