#!/usr/bin/env bash

set -e

# stop the servers
echo "Stopping servers..."
docker stop aragok-prod-creative || true
docker stop aragok-prod-survival || true
docker stop aragok-prod-proxy || true

# start the servers
echo "Starting servers..."
docker start aragok-prod-creative || true
docker start aragok-prod-survival || true
docker start aragok-prod-proxy || true

echo "Complete!"
