# Dockerfile
FROM gocd/gocd-server:v25.4.0

USER root

RUN apk update && \
    apk add --no-cache \
    uuidgen \
    gosu \
    libxml2-utils \
    jq \
    curl \
    xz \
    libstdc++ \
    apache2-utils

# Install Node.js 18 LTS binary directly from nodejs.org.
RUN curl -fsSL https://nodejs.org/dist/v18.20.4/node-v18.20.4-linux-x64.tar.xz \
    | tar -xJ -C /usr/local --strip-components=1 && \
    node --version && \
    npm --version

# Copy scripts
COPY Scripts/entrypoint.js /usr/local/bin/entrypoint.js

RUN chmod +x /usr/local/bin/entrypoint.js
RUN chown -R 1000:1000 /godata

ENTRYPOINT ["node", "/usr/local/bin/entrypoint.js"]