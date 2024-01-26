#!/bin/bash

# Start Superset in the background
superset run -p 8088 -h 0.0.0.0 --with-threads --reload --debugger &

# Function to check if Superset is up
superset_is_up() {
    curl --silent --fail http://localhost:8088/health
}

# Wait for Superset to be up
echo "Waiting for Superset to start..."
until superset_is_up; do
    printf '.'
    sleep 5
done
echo "Superset is up and running!"

# Initialize the admin user and other configurations
superset fab create-admin \
          --username admin \
          --firstname Superset \
          --lastname Admin \
          --email admin@superset.com \
          --password admin

superset db upgrade
superset init

# Keep the script running to avoid container exit
tail -f /dev/null
