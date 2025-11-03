#!/bin/bash
# Scripts/entrypoint.sh
set -e # Exit on error

# Substitute the password from the .env.docker file into the user config template
envsubst < /godata/config/go-users-config.xml.template > /godata/config/go-users-config.xml

# Execute the original GoCD server startup process
exec /docker-entrypoint.sh "$@"