FROM php:7.2-apache
MAINTAINER Rubens Takauti <rtakauti@hotmail.com>

RUN a2enmod rewrite expires

RUN set -xe \
    && apt-get update \
    && apt-get install -y libpng-dev libjpeg-dev libmcrypt-dev \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install gd mbstring mysqli zip \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-enable mcrypt

VOLUME /var/www/html

ENV OPENCART_URL https://github.com/opencart/opencart/archive/3.0.2.0.tar.gz
ENV OPENCART_FILE opencart.tar.gz

RUN set -xe \
    && curl -fSL ${OPENCART_URL} -o ${OPENCART_FILE} \
    && mkdir -p opencart \
    && tar -xzf ${OPENCART_FILE} -C opencart --strip-components 1 \
    && cd opencart/upload \
    && mv config-dist.php config.php \
    && mv admin/config-dist.php admin/config.php \
    && cp -a .  /usr/src/opencart \
    && cd ../.. \
    && rm ${OPENCART_FILE} \
    && rm -rf opencart \
    && chmod -R 777 /usr/src/opencart \
    && chown -R www-data:www-data /usr/src/opencart

COPY ./docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
