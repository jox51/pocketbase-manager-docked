# FROM php:8.2-fpm-alpine
FROM --platform=linux/am64 php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    nodejs \
    npm \
    git \
    zip \
    unzip \
    bash \
    docker \
    docker-compose \
    curl \
    ca-certificates

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html


# Copy composer files first
# COPY composer.json composer.lock ./
# RUN composer install --no-scripts

# Copy package.json files
# COPY package.json package-lock.json ./
# RUN npm install

# Copy the rest of the application
COPY . .

# Run composer scripts now that all files are present
# RUN composer dump-autoload --no-scripts

# Copy the entrypoint script
# COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# RUN chmod +x /usr/local/bin/entrypoint.sh


# Install dependencies
RUN composer install --no-scripts
RUN npm install
 # using npm run dev as npm run build was failing. Will debug later.
# RUN npm run dev
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh
EXPOSE 8000

# ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php", "artisan", "serve", "--host=0.0.0.0"] 
# Use it as the entry point
# CMD ["/usr/local/bin/startup.sh"]