# Docker Hub Multi-Platform Publishing Guide

## Quick Start

### 1. Edit the Script
```bash
nano docker-publish.sh
```

Change line 9:
```bash
DOCKER_USERNAME="YOUR_DOCKERHUB_USERNAME"
```
to your actual Docker Hub username, e.g.:
```bash
DOCKER_USERNAME="eriksimko"
```

### 2. Run the Script
```bash
cd ~/github/rdt-client
./docker-publish.sh
```

## What the Script Does

The script will automatically:

1. ✅ **Login to Docker Hub** (prompts for password)
2. ✅ **Create a buildx builder** (if not exists) for multi-platform builds
3. ✅ **Build for both architectures:**
   - `linux/amd64` - Intel/AMD TrueNAS (most common)
   - `linux/arm64` - ARM-based TrueNAS (newer systems)
4. ✅ **Push to Docker Hub** with two tags:
   - `YOUR_USERNAME/rdt-client-manual-download:latest`
   - `YOUR_USERNAME/rdt-client-manual-download:2.0.120-manual-download`

## Build Time

- **First build:** ~10-15 minutes (builds both architectures)
- **Subsequent builds:** ~5-10 minutes (uses cache when possible)

## After Publishing

Your image will be available at:
```
https://hub.docker.com/r/YOUR_USERNAME/rdt-client-manual-download
```

## Using on TrueNAS

### Method 1: TrueNAS Apps (Easiest)

1. **Apps** → **Discover Apps** → Search "rdt-client"
2. Click **Install**
3. In **Image Configuration**:
   - Repository: `YOUR_USERNAME/rdt-client-manual-download`
   - Tag: `latest`
4. Configure storage and port
5. Launch!

### Method 2: Custom App

1. **Apps** → **Custom App**
2. Configure:
   ```
   Image: YOUR_USERNAME/rdt-client-manual-download:latest
   Port: 6500
   Volumes:
     - Host: /mnt/pool/downloads → Container: /data/downloads
     - Host: /mnt/pool/appdata/rdt-client → Container: /data/db
   ```
3. Launch!

## Troubleshooting

### "unauthorized: authentication required"
Run `docker login` manually first:
```bash
docker login
# Enter your Docker Hub username and password
```

### Builder errors
Reset the builder:
```bash
docker buildx rm rdt-multiplatform
./docker-publish.sh  # Will recreate
```

### Build fails for one architecture
The Dockerfile is configured to handle both architectures automatically. If one fails:
- Check your internet connection
- Try again (Microsoft's download servers can be temperamental)
- The retry logic in the Dockerfile should handle temporary failures

### "manifest unknown" error on TrueNAS
Make sure you're using the correct image name:
```
YOUR_DOCKERHUB_USERNAME/rdt-client-manual-download:latest
```
Not:
```
YOUR_DOCKERHUB_USERNAME/rdt-client-manual-download-test:latest  ❌
```

## Updating Your Image

When you make changes to the code:

1. Commit your changes:
   ```bash
   git add .
   git commit -m "Description of changes"
   git push
   ```

2. Rebuild and publish:
   ```bash
   ./docker-publish.sh
   ```

3. On TrueNAS:
   - Go to **Apps** → Your app → **⋮** → **Update**
   - Or delete and reinstall the app (settings in DB will persist if you keep volumes)

## Platform Support

The image supports:
- ✅ **Intel/AMD TrueNAS** (x86_64) - Most common
- ✅ **ARM TrueNAS** (arm64) - Newer systems, some custom builds
- ✅ **Mac** (both Intel and Apple Silicon)
- ✅ **Linux servers** (x86_64 and arm64)

## Verifying Multi-Platform Support

After publishing, check your image:
```bash
docker buildx imagetools inspect YOUR_USERNAME/rdt-client-manual-download:latest
```

You should see both platforms listed:
```
Name:      docker.io/YOUR_USERNAME/rdt-client-manual-download:latest
MediaType: application/vnd.docker.distribution.manifest.list.v2+json
Digest:    sha256:...

Manifests:
  Name:      docker.io/.../rdt-client-manual-download:latest@sha256:...
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/amd64

  Name:      docker.io/.../rdt-client-manual-download:latest@sha256:...
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/arm64
```

## Cost

Docker Hub free tier includes:
- ✅ Unlimited public repositories
- ✅ Unlimited pulls
- ✅ One private repository (not needed for this)

## Security Note

Your custom image is public by default. This is fine for personal use, but:
- Don't include API keys or credentials in the image
- All sensitive data should be configured at runtime via environment variables or settings

## Alternative: GitHub Container Registry

If you prefer GitHub over Docker Hub:

1. Edit `docker-publish.sh` line 53:
   ```bash
   # Change from:
   --tag $DOCKER_USERNAME/$IMAGE_NAME:latest \

   # To:
   --tag ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:latest \
   ```

2. Login to GitHub:
   ```bash
   docker login ghcr.io -u YOUR_GITHUB_USERNAME
   # Use a GitHub Personal Access Token as password
   ```

3. Run the script normally

## Next Steps

After publishing:
1. ✅ Verify image on Docker Hub
2. ✅ Test pull on TrueNAS
3. ✅ Configure automatic downloads setting
4. ✅ Test manual download feature
5. 🎉 Enjoy your improved rdt-client!
