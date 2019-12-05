FROM php:7.3.11-fpm-alpine3.10

RUN apk --no-cache add nginx supervisor composer mysql-client git openssh-client bash \
        libzip-dev rabbitmq-c-dev libpng-dev icu-libs tzdata \
    && apk add --no-cache --virtual .build-deps zlib-dev icu-dev g++ autoconf make \
    && docker-php-ext-configure intl && docker-php-ext-configure calendar \
    && docker-php-ext-install intl calendar zip gd bcmath sockets pdo_mysql opcache mysqli \
    && pecl install mongodb amqp && docker-php-ext-enable mongodb amqp \
    && composer global require hirak/prestissimo brianium/paratest \
    && mkdir /root/.ssh/ && echo -e "Host bitbucket.org\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config \
    && apk del .build-deps \
    && rm -rf /tmp/* /usr/local/lib/php/doc/* /var/cache/apk/*

RUN rm /etc/nginx/conf.d/default.conf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY config/stop-supervisor.sh /usr/local/bin/stop-supervisor.sh

WORKDIR /var/www/
EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]