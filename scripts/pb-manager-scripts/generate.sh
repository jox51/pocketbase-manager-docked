#!/bin/bash

# Load environment variables from .env file
source .env

# Initialize docker-compose.yml content
compose_file="
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - \"8000:8000\"
      - \"5173:5173\"
    volumes:
      - .:/var/www/html
      - /var/www/html/vendor
      - /var/www/html/node_modules
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - APP_ENV=local
      - VITE_APP_URL=http://localhost:8000
      - LARAVEL_SERVER=true
    privileged: true
    networks:
      - default
      - pbnet
"

# Initialize Caddyfile content
caddy_file=":80 {
"

# Loop through the environment variables
for var in $(compgen -A variable | grep '^PB[0-9]'); do
    # Extract just the name, removing any quotes
    pb_name=$(echo ${!var} | tr -d '"' | tr -d '\r')
    
    # Skip if name is empty
    if [ -z "$pb_name" ]; then
        continue
    fi
    
    # Add service to docker-compose.yml with fixed port 8080
    compose_file+="  ${pb_name}:
    build:
      context: ./scripts/pb-manager-scripts
      dockerfile: Dockerfile
    container_name: pb-${pb_name}
    user: root
    expose:
      - "8080"
    volumes:
      - ./scripts/pb-manager-scripts/pocketbase/${pb_name}:/pocketbase/${pb_name}
    networks:
      - pbnet
    command: ./pocketbase serve --http=0.0.0.0:8080
"

    # Add reverse proxy rule to Caddyfile (using standard port 8080)
    caddy_file+="  handle_path /${pb_name}* {
    reverse_proxy pb-${pb_name}:8080
  }

"
done

# Finalize docker-compose.yml content with caddy service
compose_file+="
  caddy:
    image: caddy:latest
    restart: always
    cap_add:
      - NET_ADMIN
    ports:
      - \"80:80\"
      - \"443:443\"
      - \"443:443/udp\"
    volumes:
      - ./scripts/pb-manager-scripts/caddy/Caddyfile.conf:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - pbnet
volumes:
  caddy_data:
  caddy_config:

networks:
  pbnet:
    name: pb-manager_pbnet
    driver: bridge
"

# Finalize Caddyfile content
caddy_file+="  route / {
      respond \"Hello, PocketBase Multi Instance !\" 200
  }

  file_server
}
"

# Write the generated content to the respective files
echo "$compose_file" > ../../docker-compose.yml
echo "$caddy_file" > ./caddy/Caddyfile.conf
echo "$caddy_file" > ./caddy/Caddyfile

echo "docker-compose.yml and Caddyfile have been generated."