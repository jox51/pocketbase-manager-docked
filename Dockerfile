FROM php:8.2-fpm-alpine

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

# Fetch the latest PocketBase version
# ARG PB_VERSION
# RUN PB_VERSION=$(curl -s https://api.github.com/repos/pocketbase/pocketbase/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') && \
#     echo "PB_VERSION=${PB_VERSION}" > /etc/pb_version

# # Download and unzip PocketBase
# RUN PB_VERSION=$(cat /etc/pb_version | cut -d '=' -f 2) && \
#     curl -L -o /tmp/pb.zip https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip && \
#     unzip /tmp/pb.zip -d /pb/

WORKDIR /var/www/html

# Copy application files
COPY . .

# Copy the entrypoint script
# COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# RUN chmod +x /usr/local/bin/entrypoint.sh


# Install dependencies
RUN composer install
RUN npm install
RUN npm run build

EXPOSE 8000

# ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php", "artisan", "serve", "--host=0.0.0.0"] 