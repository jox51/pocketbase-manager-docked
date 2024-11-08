#!/bin/sh

# Get instance name from container hostname
INSTANCE_NAME=$(hostname)

# If this is the main app container
if [ "$LARAVEL_SERVER" = "true" ]; then
    # Start Laravel server
    php artisan serve --host=0.0.0.0
    npm run dev
else
    # Start PocketBase with the correct data directory and port 8080
    /pb/pocketbase serve \
        --dir /pocketbase/${INSTANCE_NAME} \
        --http 0.0.0.0:8080
fi