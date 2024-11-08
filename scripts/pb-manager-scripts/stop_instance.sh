#!/bin/bash

# Check if instance name is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <instance_name>"
    exit 1
fi

instance_name=$1

# Check if the instance exists in docker ps
if ! docker ps | grep -q "pb-${instance_name}"; then
    echo "Instance '${instance_name}' is not running or doesn't exist."
    exit 1
fi

# Go to the project root directory
cd ../../

# Stop the container using the service name (without pb- prefix)
docker compose stop "${instance_name}"

# Verify the container has stopped
if docker ps | grep -q "pb-${instance_name}"; then
    echo "Failed to stop instance '${instance_name}'"
    exit 1
fi

echo "PocketBase instance '${instance_name}' has been stopped."

