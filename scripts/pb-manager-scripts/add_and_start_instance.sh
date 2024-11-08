#!/bin/bash

# Check if instance name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <instance_name>"
    exit 1
fi

instance_name=$1


if [[ $instance_name == speedrun_* ]]; then
    echo "Setting up speedrun instance..."
    
    # Cleanup existing instance
    docker rm -f "pb-${instance_name}" 2>/dev/null || true
    docker network disconnect pb-manager_pbnet "pb-${instance_name}" 2>/dev/null || true
    
    # Use the same configuration as regular instances
    # Let Docker handle port mapping automatically
    docker-compose up -d --force-recreate "${instance_name}"
    
    # Wait for container to be ready
    sleep 2
    
    # Get the dynamically assigned port
    PORT=$(docker port "pb-${instance_name}" 8090 | cut -d ':' -f 2)
    echo "Instance running on port: ${PORT}"
fi

# Get current user
current_user=$(whoami)
echo "Current user: $current_user"

# Find next available PB number
next_pb=1
while grep -q "^PB${next_pb}=" .env 2>/dev/null; do
    ((next_pb++))
done

# Add new instance to .env file
echo "PB${next_pb}=\"${instance_name}\"" >> .env
echo "Added new PocketBase instance: PB${next_pb}=\"${instance_name}\""

# Regenerate docker-compose.yml and Caddyfile
./generate.sh

# Create instance directory if it doesn't exist
mkdir -p "./pocketbase/${instance_name}"

# Build and start the containers
cd ../..
docker compose up -d --build

 

# Explicitely connect to the new instance
docker network connect pb-manager_pbnet pb-${instance_name}

# Explicitly reload Caddy configuration
# docker exec pb-manager-scripts-caddy-1 caddy reload --config /etc/caddy/Caddyfile
docker exec pb-manager-caddy-1 caddy reload --config /etc/caddy/Caddyfile


echo "Error: PocketBase instance failed to start properly"
exit 1