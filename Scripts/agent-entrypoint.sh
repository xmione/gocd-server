#!/bin/sh
set -e

# Ensure agent registers with a unique hostname
export AGENT_AUTO_REGISTER_HOSTNAME=$(hostname)

# Update CA trust (in case certs were mounted/copied)
if [ -f /usr/local/share/ca-certificates/ca.crt ]; then
  update-ca-certificates
fi

# Hand off to the stock GoCD agent entrypoint
exec /docker-entrypoint.sh "$@"
