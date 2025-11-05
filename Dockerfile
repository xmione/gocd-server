# Dockerfile
FROM gocd/gocd-server:v25.3.0

# Switch to root to install dependencies
USER root
RUN apk add --no-cache curl apache2-utils bash uuidgen gosu

# Generate a unique server ID at build time
RUN echo "SERVER_ID=$(uuidgen)" > /etc/server-id

# Copy the new entrypoint script
COPY Scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint to our custom script
ENTRYPOINT ["entrypoint.sh"]