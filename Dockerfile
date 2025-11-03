# Dockerfile
FROM gocd/gocd-server:v25.3.0

# Switch to root to install curl and htpasswd
# The correct package for htpasswd on Alpine Linux is apache2-utils
USER root
RUN apk add --no-cache curl apache2-utils
USER go

# Copy the main config and the new entrypoint script
COPY --chown=go:go config/cruise-config.xml /godata/config/
COPY --chown=go:go Scripts/entrypoint.sh /usr/local/bin/

# Make the entrypoint script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint to our custom script
ENTRYPOINT ["entrypoint.sh"]