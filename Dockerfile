FROM php:7.3.14-fpm-buster

RUN set -x && apt-get -y update \
    && apt-get -y install --no-install-recommends libicu-dev libzip-dev libpng-dev \
        nginx supervisor git openssh-client libssh-dev librabbitmq-dev unzip \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash \
    && docker-php-ext-configure intl && docker-php-ext-configure calendar \
    && docker-php-ext-install intl calendar zip gd bcmath sockets pdo_mysql opcache mysqli pcntl \
    && pecl install mongodb amqp && docker-php-ext-enable mongodb amqp \
    && mkdir /root/.ssh/ && echo "Host bitbucket.org\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/lastlog /var/log/faillog /usr/share/doc

RUN rm /etc/nginx/sites-enabled/default

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer global require hirak/prestissimo brianium/paratest

COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY config/stop-supervisor.sh /usr/local/bin/stop-supervisor.sh

WORKDIR /var/www/
EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
