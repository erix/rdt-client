# TrueNAS SCALE 24.10 Deployment Guide

Guide for deploying rdt-client-manual-download on TrueNAS SCALE 24.10 (Dragonfish and later).

**Note:** TrueNAS SCALE 24.10 uses the new app system without custom catalogs. Use the "Custom App" feature instead.

## Prerequisites

- TrueNAS SCALE 24.10 or later
- Docker image published: `erix12/rdt-client-manual-download:latest`
- Storage pool created (e.g., `/mnt/pool`)
- Datasets created for downloads and app data (recommended)

## Method 1: Custom App via Web UI (Recommended)

This is the easiest method for TrueNAS SCALE 24.10.

### Step 1: Prepare Storage

Create datasets for better organization (optional but recommended):

```bash
# SSH into TrueNAS or use Shell
zfs create pool/downloads
zfs create pool/appdata
zfs create pool/appdata/rdt-client

# Set permissions (TrueNAS apps user is 568)
chown -R 568:568 /mnt/pool/downloads
chown -R 568:568 /mnt/pool/appdata/rdt-client
```

### Step 2: Open Custom App

1. Open TrueNAS SCALE web interface
2. Navigate to **Apps**
3. Click **Discover Apps**
4. Click **Custom App** button (top right)

### Step 3: Basic Configuration

**Application Name:**
```
rdt-client
```

**Version:** (leave default or enter)
```
1.0.0
```

### Step 4: Image Configuration

**Image repository:**
```
erix12/rdt-client-manual-download
```

**Image Tag:**
```
latest
```

**Image Pull Policy:**
```
Always
```

### Step 5: Container Configuration

**Container Port:**
- Port: `6500`
- Protocol: `TCP`

**Node Port:** (the port on your TrueNAS)
- Port: `6500`

### Step 6: Storage Configuration

Click **Add** under "Storage" section for each volume:

**Volume 1 - Downloads:**
- **Type:** `Host Path`
- **Host Path:** `/mnt/pool/downloads` (adjust "pool" to your pool name)
- **Mount Path:** `/data/downloads`
- **Read Only:** `No` (unchecked)

**Volume 2 - Database:**
- **Type:** `Host Path`
- **Host Path:** `/mnt/pool/appdata/rdt-client` (adjust "pool" to your pool name)
- **Mount Path:** `/data/db`
- **Read Only:** `No` (unchecked)

### Step 7: Environment Variables (Optional)

Click **Add** under "Environment Variables":

**Variable 1:**
- **Name:** `LOG_LEVEL`
- **Value:** `Warning`

### Step 8: Advanced Settings

Expand "Advanced Settings" if available:

**Security Context:**
- **Run as User:** `568`
- **Run as Group:** `568`
- **FS Group:** `568`

**Restart Policy:**
- Select: `unless-stopped` or `always`

**Hostname:**
```
rdt-client
```

### Step 9: Deploy

1. Review all settings
2. Click **Install** (or **Save**)
3. Wait for deployment (1-2 minutes)
4. Check status in **Apps** → **Installed**

### Step 10: Verify Deployment

1. Look for **rdt-client** in installed apps
2. Status should show as **Running** (green)
3. Click on the app to see logs
4. Access web UI: **http://TRUENAS_IP:6500**

---

## Method 2: Docker Compose via CLI

For advanced users who prefer command line.

### Step 1: SSH into TrueNAS

```bash
ssh root@TRUENAS_IP
```

### Step 2: Create Directory

```bash
mkdir -p /mnt/pool/docker/rdt-client
cd /mnt/pool/docker/rdt-client
```

### Step 3: Create docker-compose.yml

```bash
nano docker-compose.yml
```

Paste this content:

```yaml
version: '3.8'

services:
  rdt-client:
    image: erix12/rdt-client-manual-download:latest
    container_name: rdt-client-manual-download
    restart: unless-stopped

    ports:
      - "6500:6500"

    volumes:
      # Adjust these paths to match your TrueNAS pool
      - /mnt/pool/downloads:/data/downloads
      - /mnt/pool/appdata/rdt-client:/data/db

    environment:
      - LOG_LEVEL=Warning

    # Run as TrueNAS apps user
    user: "568:568"

    hostname: rdt-client

    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6500"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
```

**Important:** Edit the volume paths to match your pool name!

### Step 4: Deploy

```bash
# Start the container
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

### Step 5: Manage

```bash
# Stop
docker compose stop

# Restart
docker compose restart

# Update to latest image
docker compose pull
docker compose up -d

# Remove
docker compose down
```

---

## Initial Configuration

After deployment, configure the application:

### Step 1: Access Web UI

Open browser to: **http://TRUENAS_IP:6500**

### Step 2: Set Credentials

On first access, set username and password (these are saved for future logins).

### Step 3: Configure Debrid Provider

1. Click **Settings** (gear icon)
2. Scroll to **Provider** section
3. Select your provider (Real-Debrid, AllDebrid, etc.)
4. Enter your **API Key**
5. Save

### Step 4: Configure Paths

In Settings:

**Download Client Settings:**
- **Download path:** `/data/downloads`
- **Mapped path:** `/data/downloads` (for TrueNAS, keep same)

Or if you want it to show the TrueNAS path:
- **Download path:** `/data/downloads`
- **Mapped path:** `/mnt/pool/downloads` (your actual TrueNAS path)

### Step 5: Enable Manual Download Mode

**Important:** To enable manual download control:

1. In Settings, find **"Automatic downloads"** checkbox
2. **Uncheck** this option
3. Click **Save**

Now torrents will show "Ready to Download" status instead of auto-downloading!

---

## Integration with Sonarr/Radarr

### Configure Download Client

1. In Sonarr/Radarr: **Settings** → **Download Clients**
2. Click **Add** → **qBittorrent**
3. Configure:
   - **Name:** `rdt-client`
   - **Host:** `TRUENAS_IP` (or container name if in same network)
   - **Port:** `6500`
   - **Username:** Your rdt-client username
   - **Password:** Your rdt-client password
   - **Category:** `sonarr` or `radarr` (optional)
4. Click **Test** → Should show success
5. Click **Save**

---

## Troubleshooting

### App Won't Start

**Check container status:**
```bash
docker ps -a | grep rdt-client
```

**View logs:**
```bash
# If deployed via UI:
# Apps → Installed → rdt-client → View Logs

# If deployed via CLI:
docker compose logs
```

**Common issues:**
- Port 6500 already in use → Change port in configuration
- Permission denied → Check directory ownership (should be 568:568)

### Permission Errors

Fix directory permissions:
```bash
chown -R 568:568 /mnt/pool/downloads
chown -R 568:568 /mnt/pool/appdata/rdt-client
chmod -R 755 /mnt/pool/downloads
chmod -R 755 /mnt/pool/appdata/rdt-client
```

### Can't Access Web UI

1. **Check firewall:** TrueNAS usually allows all by default
2. **Verify container is running:**
   ```bash
   docker ps | grep rdt-client
   ```
3. **Test locally:**
   ```bash
   curl http://localhost:6500
   ```
4. **Check port binding:**
   ```bash
   netstat -tulpn | grep 6500
   ```

### Database Locked Error

Stop container and delete database:
```bash
# Via Docker Compose
docker compose down
rm -rf /mnt/pool/appdata/rdt-client/*
docker compose up -d

# Via UI
# Stop app, delete files in dataset, restart app
```

### Container Restarts Constantly

Check logs for errors:
```bash
docker compose logs --tail=50
```

Common causes:
- Invalid volume paths
- Insufficient permissions
- Port conflict

---

## Updating

### Via UI (Custom App)

1. **Apps** → **Installed**
2. Find **rdt-client**
3. Click **Edit**
4. Change **Image Tag** to new version (or keep `latest`)
5. Click **Save** → Container will be recreated with new image

### Via CLI (Docker Compose)

```bash
cd /mnt/pool/docker/rdt-client

# Pull latest image
docker compose pull

# Recreate container with new image
docker compose up -d

# Check logs
docker compose logs -f
```

---

## Backup

### What to Backup

Only need to backup the database directory:
```
/mnt/pool/appdata/rdt-client
```

This contains:
- Settings and configuration
- Torrent metadata
- User credentials

### Backup Methods

**Method 1: ZFS Snapshot (Recommended)**
```bash
# Create snapshot
zfs snapshot pool/appdata/rdt-client@backup-$(date +%Y%m%d)

# List snapshots
zfs list -t snapshot pool/appdata/rdt-client

# Restore from snapshot
zfs rollback pool/appdata/rdt-client@backup-20251029
```

**Method 2: TrueNAS Cloud Sync**
1. **Data Protection** → **Cloud Sync Tasks**
2. Create task to backup `/mnt/pool/appdata/rdt-client`
3. Set schedule (e.g., daily)

**Method 3: Manual Copy**
```bash
# Create backup
tar czf rdt-client-backup-$(date +%Y%m%d).tar.gz /mnt/pool/appdata/rdt-client

# Restore
tar xzf rdt-client-backup-20251029.tar.gz -C /
```

---

## Performance Tuning

### Resource Limits

TrueNAS SCALE 24.10 apps don't have built-in resource limits in the UI. To add limits, edit the container manually:

```bash
docker update \
  --memory="1g" \
  --memory-swap="2g" \
  --cpus="1.0" \
  rdt-client-manual-download
```

Or add to docker-compose.yml:
```yaml
services:
  rdt-client:
    # ... existing config ...
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.25'
          memory: 256M
```

### Download Settings

After accessing web UI, optimize for TrueNAS:

**Settings → Download Client:**
- **Maximum parallel downloads:** `2-4` (depending on your hardware)
- **Parallel connections per download:** `8`
- **Download speed:** `0` (unlimited) or set limit

**Settings → General:**
- **Maximum unpack processes:** `1`
- **Check interval:** `15` seconds

---

## Uninstalling

### Via UI
1. **Apps** → **Installed**
2. Find **rdt-client**
3. Click **Delete**
4. Optionally delete data directories

### Via CLI

```bash
# Stop and remove container
docker compose down

# Remove images (optional)
docker rmi erix12/rdt-client-manual-download:latest

# Remove data (optional - be careful!)
rm -rf /mnt/pool/appdata/rdt-client
# Don't delete downloads unless you're sure!
```

---

## Advanced: Running Behind Reverse Proxy

If you want to access rdt-client at a subpath (e.g., `https://truenas.local/rdt`):

### Traefik Example

Add labels to docker-compose.yml:
```yaml
services:
  rdt-client:
    # ... existing config ...
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.rdt.rule=PathPrefix(`/rdt`)"
      - "traefik.http.services.rdt.loadbalancer.server.port=6500"
    environment:
      - BASE_PATH=/rdt
```

### Nginx Reverse Proxy

```nginx
location /rdt/ {
    proxy_pass http://localhost:6500/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

---

## Support

- **GitHub Issues:** https://github.com/erix/rdt-client/issues
- **Docker Hub:** https://hub.docker.com/r/erix12/rdt-client-manual-download
- **Original Project:** https://github.com/rogerfar/rdt-client
- **TrueNAS Forums:** https://www.truenas.com/community/

---

## Summary: Quick Deploy Checklist

- [ ] Create datasets: `/mnt/pool/downloads` and `/mnt/pool/appdata/rdt-client`
- [ ] Set permissions: `chown -R 568:568` on both directories
- [ ] Apps → Custom App → Configure with image `erix12/rdt-client-manual-download:latest`
- [ ] Add two host path volumes (`/data/downloads` and `/data/db`)
- [ ] Set port 6500
- [ ] Deploy and wait for "Running" status
- [ ] Access http://TRUENAS_IP:6500
- [ ] Set credentials and add debrid provider API key
- [ ] **Disable "Automatic downloads"** in settings to enable manual mode
- [ ] Test by adding a torrent and clicking "Start Download"

That's it! Your custom rdt-client with manual download control is ready to use on TrueNAS SCALE 24.10! 🎉
