#!/bin/bash

# Docker Hub Publishing Script for rdt-client
# This script provides manual Docker builds. For production releases, use GitHub Actions workflow.
# GitHub Actions automatically builds and publishes when you push version tags (e.g., v2.0.120)

set -e # Exit on error

# Configuration - UPDATE THESE!
DOCKER_USERNAME="erix12" # Must match your Docker Hub username (same as DOCKERHUB_USERNAME secret in GitHub)
IMAGE_NAME="rdt-client-manual-download" # Must match APP_NAME_LEGACY in .github/workflows/build-docker-image.yml
VERSION="2.0.120" # Current version - update this for each release
PLATFORMS="linux/amd64,linux/arm64" # Build for Intel/AMD and ARM64 (Raspberry Pi 4/5, Apple Silicon)

echo "🐳 Docker Hub Multi-Platform Publishing Script"
echo "=============================================="
echo ""

# Check if Docker username is set
if [ "$DOCKER_USERNAME" = "YOUR_DOCKERHUB_USERNAME" ]; then
  echo "❌ Error: Please edit this script and set your DOCKER_USERNAME"
  echo "   Open docker-publish.sh and change DOCKER_USERNAME to your Docker Hub username"
  exit 1
fi

echo "📋 Configuration:"
echo "   Docker Hub User: $DOCKER_USERNAME"
echo "   Image Name: $IMAGE_NAME"
echo "   Version: $VERSION"
echo "   Platforms: $PLATFORMS"
echo ""

# Step 1: Login to Docker Hub
echo "🔐 Step 1: Login to Docker Hub"
docker login

echo ""
echo "🛠️  Step 2: Setting up buildx builder..."
# Create a new builder instance if it doesn't exist
if ! docker buildx inspect rdt-multiplatform >/dev/null 2>&1; then
  echo "   Creating new buildx builder 'rdt-multiplatform'..."
  docker buildx create --name rdt-multiplatform --driver docker-container --bootstrap --use
else
  echo "   Using existing builder 'rdt-multiplatform'..."
  docker buildx use rdt-multiplatform
fi

echo ""
echo "🏗️  Step 3: Building and pushing multi-platform images..."
echo "   This will take several minutes as it builds for multiple architectures..."
echo ""

docker buildx build \
  --platform $PLATFORMS \
  --tag $DOCKER_USERNAME/$IMAGE_NAME:$VERSION \
  --tag $DOCKER_USERNAME/$IMAGE_NAME:latest \
  --push \
  .

echo ""
echo "✅ Build and push complete!"

echo ""
echo "🎉 Success! Your image is now on Docker Hub:"
echo ""
echo "   https://hub.docker.com/r/$DOCKER_USERNAME/$IMAGE_NAME"
echo ""
echo "📝 Images tagged as:"
echo "   - $DOCKER_USERNAME/$IMAGE_NAME:$VERSION"
echo "   - $DOCKER_USERNAME/$IMAGE_NAME:latest"
echo ""
echo "💡 Note: For production releases, prefer using GitHub Actions:"
echo "   git tag -a v$VERSION -m \"Release v$VERSION\""
echo "   git push origin v$VERSION"
echo "   This will automatically build and publish to Docker Hub + GHCR"
echo ""
echo "🐳 To pull and run locally:"
echo "   docker pull $DOCKER_USERNAME/$IMAGE_NAME:$VERSION"
echo "   docker run -d -p 6500:6500 \\"
echo "     -v /path/to/downloads:/data/downloads \\"
echo "     -v /path/to/db:/data/db \\"
echo "     $DOCKER_USERNAME/$IMAGE_NAME:$VERSION"
echo ""
