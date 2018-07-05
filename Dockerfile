FROM php:7.2-apache
MAINTAINER Rubens Takauti <rtakauti@hotmail.com>

RUN a2enmod rewrite expires

# Install GD
RUN set -xe \
    && apt-get update \
    && apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng12-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd

# Install MCrypt
RUN set -xe \
    && apt-get update \
    && apt-get install -y libmcrypt-dev \
    && docker-php-ext-install mcrypt

# Install Intl
RUN set -xe \
    && apt-get update \
    && apt-get install -y libicu-dev \
    && docker-php-ext-install intl

ENV XDEBUG_ENABLE 0
RUN set -xe \
    && apt-get update \
    && pecl config-set preferred_state beta \
    && pecl install -o -f xdebug \
    && rm -rf /tmp/pear \
    && pecl config-set preferred_state stable

# Install Mysql
RUN docker-php-ext-install mysqli pdo_mysql

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# Install mbstring
RUN docker-php-ext-install mbstring

# Install soap
RUN set -xe \
    && apt-get update \
    && apt-get install -y libxml2-dev \
    && docker-php-ext-install soap

# Install opcache
RUN docker-php-ext-install opcache

# Install PHP zip extension
RUN docker-php-ext-install zip

# Install Git
RUN set -xe \
    && apt-get update \
    && apt-get install -y git

# Install xsl
RUN set -xe \
    && apt-get update \
    && apt-get install -y libxslt-dev \
    && docker-php-ext-install xsl

# Define PHP_TIMEZONE env variable
ENV PHP_TIMEZONE America/Sao_Paulo

# Configure Apache Document Root
ENV APACHE_DOC_ROOT /var/www/html

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Install ssmtp Mail Transfer Agent
RUN set -xe \
    && apt-get update \
    && apt-get install -y ssmtp \
    && apt-get clean \
    && echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf \
    && echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /usr/local/etc/php/conf.d/mail.ini

# Install MySQL CLI Client
RUN set -xe \
    && apt-get update \
    && apt-get install -y mysql-client

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
