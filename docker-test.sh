#!/bin/bash

# Docker Test Script for Manual Download Feature
# Run this from the rdt-client root directory

set -e  # Exit on error

echo "🐳 Building Docker image..."
docker build --tag rdtclient-manual-download-test .

echo ""
echo "✅ Build complete!"
echo ""
echo "🚀 Starting container..."
echo "   - Web UI: http://localhost:6500"
echo "   - Data will persist in: ./docker-data/"
echo ""

# Create local data directories for persistence
mkdir -p ./docker-data/downloads
mkdir -p ./docker-data/db

# Stop and remove any existing container
docker stop rdtclient-test 2>/dev/null || true
docker rm rdtclient-test 2>/dev/null || true

# Run the container
docker run \
  --name rdtclient-test \
  -p 6500:6500 \
  -v "$(pwd)/docker-data/downloads:/data/downloads" \
  -v "$(pwd)/docker-data/db:/data/db" \
  rdtclient-manual-download-test

# Note: The container runs in foreground. Press Ctrl+C to stop it.
