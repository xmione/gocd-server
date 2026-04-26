#!/bin/bash
# Scripts/entrypoint.sh
set -e

# --- INITIALIZATION ---
mkdir -p /godata/config
exec > >(tee -a /godata/config/init_debug.log) 2>&1

echo "--- BOOT SEQUENCE START: $(date) ---"

# --- PERSISTENT SERVER ID LOGIC ---
# The server ID file is stored in the persistent volume.
SERVER_ID_FILE="/godata/.server-id"
# The build-time ID is a fallback.
BUILD_TIME_ID_FILE="/etc/server-id"

if [ ! -f "$SERVER_ID_FILE" ]; then
    echo "No server ID found in persistent storage. Generating a new one..."
    if [ -f "$BUILD_TIME_ID_FILE" ]; then
        grep -oE '[0-9a-fA-F-]{36}' "$BUILD_TIME_ID_FILE" > "$SERVER_ID_FILE"
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
export SERVER_ID=$(grep -oE '[0-9a-fA-F-]{36}' "$SERVER_ID_FILE" | head -n 1)
echo "Using Server ID: $SERVER_ID"

# --- CONFIG FILE CUSTOMIZATION ---
# Only create the config file if it doesn't exist
if [ ! -f /godata/config/cruise-config.xml ]; then
    echo "Creating cruise-config.xml from template..."
    # Use the mounted template file
    cp /tmp/cruise-config.xml.template /godata/config/cruise-config.xml
    
    # # 1. AUTO-FIX SCHEMA VERSION (Targeting version 139 for v25.3.0 compatibility)
    # # We force it to 139 because the logs show the server doesn't recognize 151.
    # CURRENT_SCHEMA=$(sed -n 's/.*schemaVersion="\([^"]*\)".*/\1/p' /godata/config/cruise-config.xml)
    
    # echo "Current XML Schema: $CURRENT_SCHEMA"
    # if [ "$CURRENT_SCHEMA" != "139" ]; then
    #     echo "Patching schemaVersion to 139 for compatibility..."
    #     sed -i 's/schemaVersion="[0-9]*"/schemaVersion="139"/g' /godata/config/cruise-config.xml
    # fi

    # 2. INJECT SERVER ID
    sed -i "s/__SERVER_ID__/$SERVER_ID/g" /godata/config/cruise-config.xml
    
    # Construct the Git URL using environment variables from .env.docker
    if [ -n "$GITHUB_TOKEN" ] && [ -n "$GIT_REPO_PROTOCOL" ] && [ -n "$GIT_REPO_DOMAIN" ] && [ -n "$GIT_REPO_USERNAME" ] && [ -n "$GIT_REPO_REPONAME" ]; then
        AUTHENTICATED_URL="${GIT_REPO_PROTOCOL}://${GITHUB_TOKEN}@${GIT_REPO_DOMAIN}/${GIT_REPO_USERNAME}/${GIT_REPO_REPONAME}.git"
        
        # --- DYNAMIC APPS INJECTION (Expert Mode with jq) ---
        APPS_JSON="/tmp/apps.json"
        TARGET_FILE="/godata/config/cruise-config.xml"

        if [ -f "$APPS_JSON" ] && [ -f "$TARGET_FILE" ]; then
            echo "Processing dynamic app injections..."
            
            # Use jq to iterate through the apps array and output a tab-separated list: name|env_var|placeholder
            # This handles any JSON formatting (minified or pretty)
            jq -r '.apps[] | "\(.name)\t\(.env_var)\t\(.placeholder)"' "$APPS_JSON" | while IFS=$'\t' read -r APP_NAME ENV_VAR_NAME PLACEHOLDER; do
                
                # Get the actual repo name from the environment variable
                REPO_VAL=$(eval echo "\$$ENV_VAR_NAME")

                if [ -n "$REPO_VAL" ] && [ -n "$PLACEHOLDER" ]; then
                    # Construct the authenticated URL
                    RAW_URL="${GIT_REPO_PROTOCOL}://${GITHUB_TOKEN}@${GIT_REPO_DOMAIN}/${GIT_REPO_USERNAME}/${REPO_VAL}.git"
                    # Sanitize whitespace/newlines
                    AUTHENTICATED_URL=$(echo "$RAW_URL" | tr -d '\r\n ')

                    # Inject into cruise-config.xml
                    sed -i "s|${PLACEHOLDER}|${AUTHENTICATED_URL}|g" "$TARGET_FILE"
                    echo "Successfully injected: $APP_NAME"
                else
                    echo "Skipping $APP_NAME: $ENV_VAR_NAME is empty or placeholder missing."
                fi
            done
        else
            echo "Injection skipped: apps.json or cruise-config.xml not found."
        fi
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



# --- PERMISSIONS & HANDOVER ---
# --- FIX PERMISSIONS ---
# Ensure the 'go' user owns the configuration directory and all its contents.
# Using the numeric UID/GID is more robust than user/group names in containers.
echo "Setting correct permissions for /godata/config..."
echo "Setting permissions on GoCD data volume..."
chown -R 1000:1000 /godata
echo "--- BOOT SEQUENCE COMPLETE ---"
# Switch to the 'go' user and execute the base image's entrypoint,
# passing along any arguments. This is the standard, secure pattern.
exec gosu go /docker-entrypoint.sh "$@"