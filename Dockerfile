# Dockerfile
FROM gocd/gocd-server:v25.3.0

# Switch to root to install dependencies
USER root
RUN apk add --no-cache curl apache2-utils bash
USER go

# Explicitly disable git credential helper to allow cloning of public repos
RUN git config --global credential.helper ""

# Copy the config file to a temporary staging location.
# This prevents conflicts with the volume mount.
COPY --chown=go:go config/cruise-config.xml /tmp/cruise-config.xml.template
COPY --chown=go:go Scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

# Sanitize the script to remove Windows (CRLF) line endings and make it executable.
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint to our custom script
ENTRYPOINT ["entrypoint.sh"]