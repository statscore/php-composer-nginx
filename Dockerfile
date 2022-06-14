FROM php:7.4-fpm-alpine

COPY --from=composer:2.2.3 /usr/bin/composer /usr/bin/composer
RUN apk --no-cache add nginx supervisor mysql-client git openssh-client bash \
    libzip-dev rabbitmq-c-dev libpng-dev icu-libs tzdata libssh-dev \
    && apk add --no-cache --virtual .build-deps zlib-dev icu-dev g++ autoconf make \
    && docker-php-ext-configure intl && docker-php-ext-configure calendar \
    && docker-php-ext-install intl calendar zip gd bcmath sockets pdo_mysql opcache mysqli pcntl \
    && pecl install mongodb amqp redis pcov && docker-php-ext-enable mongodb amqp redis pcov \
    && composer global require brianium/paratest \
    && mkdir /root/.ssh/ && echo -e "Host bitbucket.org\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config \
    && echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config \
    && apk del .build-deps \
    && rm -rf /tmp/* /usr/local/lib/php/doc/* /var/cache/apk/*

RUN mkdir /etc/cron.d/
RUN rm /etc/nginx/http.d/default.conf && mv /etc/nginx/http.d /etc/nginx/conf.d

COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY config/stop-supervisor.sh /usr/local/bin/stop-supervisor.sh

WORKDIR /var/www/
EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"] 
