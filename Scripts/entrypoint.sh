#!/bin/bash
# Scripts/entrypoint.sh
set -e # Exit on error

# Ensure the config directory exists
mkdir -p /godata/config

# Always regenerate the main config file from the template to ensure it's up-to-date.
echo "Regenerating cruise-config.xml from template."
cp /tmp/cruise-config.xml.template /godata/config/cruise-config.xml

# Inject the GitHub token into the Git URL for private repository access.
if [ -n "$GITHUB_TOKEN" ]; then
  AUTHENTICATED_URL="https://${GITHUB_TOKEN}@github.com/xmione/badminton_court.git"
  echo "GITHUB_TOKEN found. Injecting credentials into cruise-config.xml..."
  sed -i "s#__GIT_REPO_URL_WITH_CREDENTIALS__#${AUTHENTICATED_URL}#g" /godata/config/cruise-config.xml
  echo "Credential injection complete."
else
  echo "ERROR: GITHUB_TOKEN not found in environment. Pipeline will not be able to clone the repository."
  exit 1
fi

# Always regenerate the password file to ensure it matches the current environment variable.
echo "Ensuring admin password is up-to-date..."
hashed_password=$(htpasswd -nbB admin "${GOCD_ADMIN_PASSWORD}" | sed -e 's/admin://')
echo "admin=${hashed_password}" > /godata/config/password.properties
echo "Admin password file created/updated."

# Execute the original GoCD server startup process.
exec /docker-entrypoint.sh "$@"