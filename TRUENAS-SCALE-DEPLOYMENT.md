# TrueNAS SCALE Deployment Guide

Your rdt-client with manual download feature can be deployed on TrueNAS SCALE using either Docker Compose or Helm.

## Method 1: Docker Compose (Easiest)

TrueNAS SCALE supports docker-compose through the command line.

### Step 1: Copy Files to TrueNAS

```bash
# On your Mac, copy docker-compose.yml to TrueNAS
scp docker-compose.yml root@TRUENAS_IP:/mnt/pool/appdata/rdt-client/

# Or use TrueNAS web UI: System Settings → Shell
```

### Step 2: Edit Paths

SSH into TrueNAS and edit the compose file:

```bash
ssh root@TRUENAS_IP
cd /mnt/pool/appdata/rdt-client
nano docker-compose.yml
```

Update the volume paths to match your TrueNAS datasets:
```yaml
volumes:
  - /mnt/pool/downloads:/data/downloads          # Your downloads path
  - /mnt/pool/appdata/rdt-client/db:/data/db    # Database path
```

### Step 3: Deploy

```bash
# Install docker-compose if not already installed
apt update && apt install docker-compose

# Deploy the stack
cd /mnt/pool/appdata/rdt-client
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f
```

### Step 4: Access

Open browser to: **http://TRUENAS_IP:6500**

### Managing the Container

```bash
# Stop
docker-compose down

# Restart
docker-compose restart

# View logs
docker-compose logs -f

# Update image
docker-compose pull
docker-compose up -d
```

---

## Method 2: Helm Chart (Advanced - Kubernetes Native)

TrueNAS SCALE uses Kubernetes (k3s) under the hood. You can install via Helm.

### Option A: Install from Local Chart

**Step 1: Copy Helm chart to TrueNAS**

```bash
# On your Mac
cd ~/github/rdt-client
tar czf rdt-client-helm.tar.gz helm-chart/

# Copy to TrueNAS
scp rdt-client-helm.tar.gz root@TRUENAS_IP:/tmp/
```

**Step 2: Install via Helm (on TrueNAS)**

```bash
ssh root@TRUENAS_IP

# Extract
cd /tmp
tar xzf rdt-client-helm.tar.gz

# Install with Helm
helm install rdt-client-manual ./helm-chart/rdt-client-manual-download \
  --set persistence.downloads.hostPath=/mnt/pool/downloads \
  --set persistence.database.hostPath=/mnt/pool/appdata/rdt-client \
  --set service.type=LoadBalancer
```

**Step 3: Access**

```bash
# Get the service IP
kubectl get svc

# Access at http://SERVICE_IP:6500
```

### Option B: Create Custom App Catalog

This allows installing via TrueNAS web UI.

**Step 1: Create GitHub Repository for Catalog**

1. Create a new GitHub repo: `truenas-apps` (or any name)
2. Add the helm chart:
   ```
   truenas-apps/
   └── charts/
       └── rdt-client-manual-download/
           ├── Chart.yaml
           ├── values.yaml
           └── templates/
               └── (all template files)
   ```

**Step 2: Add Catalog in TrueNAS**

1. TrueNAS UI → **Apps** → **Manage Catalogs**
2. Click **Add Catalog**
3. Configure:
   - Name: `my-apps`
   - Repository: `https://github.com/YOUR_USERNAME/truenas-apps`
   - Branch: `main`
   - Preferred Trains: `charts`
4. Save and wait for sync

**Step 3: Install from UI**

1. **Apps** → **Discover Apps**
2. Search for "rdt-client-manual-download"
3. Click **Install**
4. Configure paths and settings
5. Click **Save**

---

## Method 3: TrueNAS SCALE Custom App (UI)

If you don't want to use command line, use the TrueNAS UI directly:

### Step 1: Navigate to Apps

1. TrueNAS UI → **Apps**
2. Click **Discover Apps**
3. Click **Custom App** (top right)

### Step 2: Configure Application

**Application Name:**
```
rdt-client-manual-download
```

**Image Configuration:**
```
Repository: erix12/rdt-client-manual-download
Tag: latest
Pull Policy: Always
```

**Container Environment Variables:**
Add these if needed:
```
Name: LOG_LEVEL, Value: Warning
```

**Networking:**
```
Container Port: 6500
Node Port: 6500 (or any available port)
Host Network: false
```

**Storage:**

**Volume 1 - Downloads:**
```
Type: Host Path
Host Path: /mnt/pool/downloads
Mount Path: /data/downloads
```

**Volume 2 - Database:**
```
Type: Host Path
Host Path: /mnt/pool/appdata/rdt-client
Mount Path: /data/db
```

**Security Context:**
```
Run As User: 568
Run As Group: 568
FS Group: 568
```

### Step 3: Deploy

Click **Save** and wait for deployment.

---

## Configuration

### Initial Setup

1. Open **http://TRUENAS_IP:6500**
2. Set username/password (saved for future logins)
3. Go to **Settings**:
   - Add debrid provider API key
   - Set **Download path**: `/data/downloads`
   - Set **Mapped path**: `/mnt/pool/downloads` (your TrueNAS path)
   - **Disable "Automatic downloads"** to enable manual mode
4. Save settings

### Testing Manual Download

1. Add a test torrent
2. Wait for status: **"Ready to Download"**
3. Click **"Start Download"** button
4. Verify files appear in `/mnt/pool/downloads`

---

## Troubleshooting

### Port Already in Use

Check what's using port 6500:
```bash
netstat -tulpn | grep 6500
```

Use a different port in configuration.

### Permission Denied

Set correct ownership:
```bash
chown -R 568:568 /mnt/pool/downloads
chown -R 568:568 /mnt/pool/appdata/rdt-client
```

### Container Won't Start

Check logs:
```bash
# Docker Compose
docker-compose logs -f

# Kubernetes
kubectl logs -l app.kubernetes.io/name=rdt-client-manual-download
```

### Database Locked

Stop the app and delete database:
```bash
rm -rf /mnt/pool/appdata/rdt-client/db/*
# Restart app - database will be recreated
```

### Can't Access Web UI

1. Check firewall (TrueNAS usually allows all by default)
2. Verify container is running:
   ```bash
   docker ps  # or kubectl get pods
   ```
3. Check service endpoints:
   ```bash
   kubectl get svc  # Helm/k8s
   docker-compose ps  # Docker Compose
   ```

---

## Updating

### Docker Compose Method

```bash
cd /mnt/pool/appdata/rdt-client
docker-compose pull
docker-compose up -d
```

### Helm Method

```bash
helm upgrade rdt-client-manual ./helm-chart/rdt-client-manual-download \
  --reuse-values
```

### TrueNAS UI Method

1. **Apps** → Find your app
2. Click **⋮** (menu) → **Update**

---

## Integration with *arr Apps

Your custom rdt-client works with Sonarr/Radarr on TrueNAS:

1. In Sonarr/Radarr: **Settings** → **Download Clients** → **Add** → **qBittorrent**
2. Configure:
   - Host: `rdt-client-manual-download` (or TrueNAS IP)
   - Port: `6500`
   - Username/Password: Your rdt-client credentials
   - Category: `sonarr` or `radarr`
3. Test and Save

---

## Backup

Backup these paths:
- `/mnt/pool/appdata/rdt-client/db` - Database and settings

Use TrueNAS snapshots or Cloud Sync tasks for automatic backups.

---

## Performance Tuning

### Resource Limits (Helm)

Edit values.yaml:
```yaml
resources:
  limits:
    cpu: 2000m      # 2 CPU cores
    memory: 2Gi     # 2GB RAM
  requests:
    cpu: 200m
    memory: 512Mi
```

### Download Parallelism

In rdt-client Settings:
- **Maximum parallel downloads**: `2-4` (adjust based on your network)
- **Parallel connections per download**: `8`

---

## Which Method Should I Use?

**Docker Compose** - If you:
- ✅ Are comfortable with command line
- ✅ Want simple, quick deployment
- ✅ Don't need advanced Kubernetes features

**Helm Chart** - If you:
- ✅ Want Kubernetes-native deployment
- ✅ Need advanced resource management
- ✅ Want integration with existing Helm workflows

**TrueNAS UI Custom App** - If you:
- ✅ Prefer GUI configuration
- ✅ Want point-and-click deployment
- ✅ Don't want to use command line

All three methods work equally well - choose what you're most comfortable with!
