#!/bin/bash

# Check if instance name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <instance_name>"
    exit 1
fi

instance_name=$1

# Validate instance name
if ! [[ $instance_name =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo "Error: Instance name should contain only alphanumeric characters and underscores."
    exit 1
fi

echo "Checking for container pb-${instance_name}..."

# Go to the project root directory
cd ../../

# Check if the container exists and its status
if docker ps -a --format '{{.Names}}' | grep -q "pb-${instance_name}$"; then
    echo "Container exists, starting it..."
    docker compose start "${instance_name}" || {
        echo "Failed to start container. Trying to recreate..."
        docker compose up -d "${instance_name}"
    }
else
    echo "Container doesn't exist, creating it..."
    docker compose up -d "${instance_name}"
fi

# Allow container to initialize
sleep 5

# Verify the instance is running
if ! docker ps --format '{{.Names}}' | grep -q "pb-${instance_name}$"; then
    echo "Error: Container failed to start"
    echo "Container logs:"
    docker logs "pb-${instance_name}"
    exit 1
fi

# Ensure Caddy is running and reload its config
if ! docker ps | grep -q "pb-manager-caddy-1"; then
    echo "Starting Caddy..."
    docker compose up -d caddy
    sleep 2
fi

# Reload Caddy configuration
docker exec pb-manager-caddy-1 caddy reload --config /etc/caddy/Caddyfile

echo "Container successfully started. Recent logs:"
docker logs --tail 10 "pb-${instance_name}"

echo "PocketBase instance '${instance_name}' has been restarted."
