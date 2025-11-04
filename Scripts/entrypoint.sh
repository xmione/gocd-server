#!/bin/bash
# Scripts/entrypoint.sh
set -e # Exit on error

# Ensure the config directory exists
mkdir -p /godata/config

# Check if the main config file exists to ensure this is the first run.
if [ ! -f /godata/config/cruise-config.xml ]; then
  echo "Performing first-time initialization: copying cruise-config.xml template."
  cp /tmp/cruise-config.xml.template /godata/config/cruise-config.xml
fi

# Check if the password file already exists to avoid re-hashing on container restarts
if [ ! -f /godata/config/password.properties ]; then
  echo "Creating initial admin user and password file with BCrypt hash..."
  
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