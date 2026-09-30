FROM php:8.3-fpm
RUN apt-get update && apt-get install -y git unzip libzip-dev libpng-dev \
    && docker-php-ext-install pdo_mysql zip gd bcmath
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /var/www
COPY . .
RUN composer install --no-dev --optimize-autoloader
RUN chown -R www-data:www-data storage bootstrap/cache
EXPOSE 9000
CMD ["php-fpm"]
