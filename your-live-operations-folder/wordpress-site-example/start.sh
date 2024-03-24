#!/bin/bash

cd "$(dirname "$0")" || exit

mkdir -p "volumes" 2>/dev/null

# Create a unique container name based on current timestamp
TEMP_CONTAINER="temp_container_$(date +%s)"
IMAGE_NAME="wp-cubix:latest"
FILE_PATH_IN_CONTAINER="/var/www/html/composer.json"
DEST_PATH_ON_HOST="volumes/composer.json"

if [ ! -f "$DEST_PATH_ON_HOST" ]; then
    echo "Mount file for composer.json not found. Copying composer.json from container to create new file volume."

    echo "Creating temporary container from image '$IMAGE_NAME'..."
    docker create --name "$TEMP_CONTAINER" "$IMAGE_NAME" > /dev/null

    # Check if the container was created successfully
    if [ $? -ne 0 ]; then
        echo "Failed to create a temporary container from image '$IMAGE_NAME'."
        exit 1
    fi

    # Step 2: Copy the file from the container to the host
    echo "Copying '$FILE_PATH_IN_CONTAINER' from the container to '$DEST_PATH_ON_HOST'..."
    docker cp "$TEMP_CONTAINER":"$FILE_PATH_IN_CONTAINER" "$DEST_PATH_ON_HOST"

    # Check if the file was copied successfully
    if [ $? -ne 0 ]; then
        echo "Failed to copy the file from the container to the host."
        # Attempt to remove the temporary container before exiting
        docker rm "$TEMP_CONTAINER" > /dev/null
        exit 1
    fi

    # Step 3: Remove the temporary container
    echo "Removing temporary container..."
    docker rm "$TEMP_CONTAINER" > /dev/null
fi

echo "Executing docker-compose up -d. Launching container..."

docker-compose up -d