#!/bin/bash
# Scripts/entrypoint.sh
set -e # Exit on error

# Forcefully remove the entire config directory to ensure a clean start.
# This is the most reliable way to prevent serverId conflicts.
rm -rf /godata/config

# Check if the password file already exists to avoid re-hashing on container restarts
if [ ! -f /godata/config/password.properties ]; then
  echo "Creating initial admin user and password file with BCrypt hash..."
  
  # Ensure the config directory exists before writing to it.
  mkdir -p /godata/config
  
  # Use the standard 'htpasswd' utility to generate a BCrypt hash.
  hashed_password=$(htpasswd -nbB admin "${GOCD_ADMIN_PASSWORD}" | sed -e 's/admin://')
  
  # Create the password file in the format GoCD expects: username=hashed_password
  echo "admin=${hashed_password}" > /godata/config/password.properties
  
  echo "Admin user created successfully."
else
  echo "Password file already exists, skipping user creation."
fi

# Execute the original GoCD server startup process.
exec /docker-entrypoint.sh "$@"