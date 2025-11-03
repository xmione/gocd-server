# Dockerfile
FROM gocd/gocd-server:v25.3.0

USER root
RUN apk add --no-cache gettext
USER go

# Copy the main config and the user config template
COPY --chown=go:go config/cruise-config.xml /godata/config/
COPY --chown=go:go config/go-users-config.xml.template /godata/config/
COPY --chown=go:go entrypoint.sh /usr/local/bin/

# Make the entrypoint script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint to our custom script
ENTRYPOINT ["entrypoint.sh"]