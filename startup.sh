#!/bin/sh

# Start npm development server in background
echo "Starting npm development server..."
npm run dev &&

# Start Laravel server
echo "Starting Laravel server..."
php artisan serve --host=0.0.0.0