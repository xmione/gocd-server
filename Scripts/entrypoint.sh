#!/bin/bash
# Scripts/entrypoint.sh
set -e # Exit on error

# --- PERSISTENT SERVER ID LOGIC ---
# The server ID file is stored in the persistent volume.
SERVER_ID_FILE="/godata/.server-id"
# The build-time ID is a fallback.
BUILD_TIME_ID_FILE="/etc/server-id"

if [ ! -f "$SERVER_ID_FILE" ]; then
    echo "No server ID found in persistent storage. Generating a new one..."
    if [ -f "$BUILD_TIME_ID_FILE" ]; then
        # Use the ID generated during the image build
        cat "$BUILD_TIME_ID_FILE" > "$SERVER_ID_FILE"
        echo "Using build-time server ID and saving to persistent storage."
    else
        # Fallback: generate a new one at runtime
        uuidgen > "$SERVER_ID_FILE"
        echo "Generated a new runtime server ID and saved to persistent storage."
    fi
else
    echo "Using existing server ID from persistent storage."
fi

# Read the persistent ID for use in this run
export SERVER_ID=$(cat "$SERVER_ID_FILE")
# --- END OF PERSISTENT SERVER ID LOGIC ---


# --- CONFIG FILE CUSTOMIZATION ---
# Ensure the config directory exists
mkdir -p /godata/config

# Only create the config file if it doesn't exist
if [ ! -f /godata/config/cruise-config.xml ]; then
    echo "Creating cruise-config.xml from template."
    # Use the mounted template file
    cp /tmp/cruise-config.xml.template /godata/config/cruise-config.xml
    
    # Replace the placeholder server ID with the actual UUID
    sed -i "s/__SERVER_ID__/$SERVER_ID/g" /godata/config/cruise-config.xml
    
    # Construct the Git URL using environment variables from .env.docker
    if [ -n "$GITHUB_TOKEN" ] && [ -n "$GIT_REPO_PROTOCOL" ] && [ -n "$GIT_REPO_DOMAIN" ] && [ -n "$GIT_REPO_USERNAME" ] && [ -n "$GIT_REPO_REPONAME" ]; then
        AUTHENTICATED_URL="${GIT_REPO_PROTOCOL}://${GITHUB_TOKEN}@${GIT_REPO_DOMAIN}/${GIT_REPO_USERNAME}/${GIT_REPO_REPONAME}.git"
        echo "Injecting Git URL into cruise-config.xml..."
        sed -i "s#__GIT_REPO_URL_WITH_CREDENTIALS__#${AUTHENTICATED_URL}#g" /godata/config/cruise-config.xml
        echo "Credential injection complete."
    else
        echo "ERROR: Required Git environment variables not found. Pipeline will not be able to clone the repository."
        exit 1
    fi
else
    echo "Using existing cruise-config.xml file."
fi

# --- PASSWORD CONFIGURATION ---
# Always regenerate the password file to ensure it matches the current environment variable.
if [ -n "$GOCD_ADMIN_PASSWORD" ]; then
    echo "Ensuring admin password is up-to-date..."
    hashed_password=$(htpasswd -nbB admin "${GOCD_ADMIN_PASSWORD}" | sed -e 's/admin://')
    echo "admin=${hashed_password}" > /godata/config/password.properties
    echo "Admin password file created/updated."
else
    echo "WARNING: GOCD_ADMIN_PASSWORD not set. Using default password."
fi

# --- FIX PERMISSIONS ---
# Ensure the 'go' user owns the configuration directory and all its contents.
# Using the numeric UID/GID is more robust than user/group names in containers.
echo "Setting correct permissions for /godata/config..."
chown -R 1000:1000 /godata/config

# Switch to the 'go' user and execute the base image's entrypoint,
# passing along any arguments. This is the standard, secure pattern.
exec gosu go /docker-entrypoint.sh "$@"