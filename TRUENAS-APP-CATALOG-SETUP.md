# TrueNAS SCALE App Catalog Setup

This guide shows you how to create your own TrueNAS SCALE app catalog to install your custom rdt-client through the TrueNAS web UI.

## Overview

By creating a custom app catalog, you can:
- Install your custom rdt-client directly from the TrueNAS UI
- Easily update the app when you push new versions
- Share your custom app with others
- Manage multiple custom apps in one catalog

## Step 1: Create GitHub Repository Structure

Create a new GitHub repository with this structure:

```
truenas-apps/                           # Your repo name (can be anything)
├── README.md
└── charts/                             # Must be named "charts"
    └── rdt-client-manual-download/     # Your app name
        ├── Chart.yaml
        ├── values.yaml
        ├── README.md
        ├── questions.yaml              # Optional: TrueNAS UI form
        ├── app-readme.md               # Optional: Shows in TrueNAS UI
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── pvc.yaml
            ├── ingress.yaml
            └── _helpers.tpl
```

## Step 2: Copy Your Helm Chart

Copy your existing helm chart to the new repository:

```bash
# Clone your new catalog repo
git clone https://github.com/YOUR_USERNAME/truenas-apps.git
cd truenas-apps

# Create charts directory
mkdir -p charts

# Copy your helm chart
cp -r ~/github/rdt-client/helm-chart/rdt-client-manual-download charts/

# Add a README
cat > README.md << 'EOF'
# My TrueNAS Apps Catalog

Custom TrueNAS SCALE applications.

## Apps

- **rdt-client-manual-download** - Real-Debrid Torrent Client with manual download feature

## Installation

1. TrueNAS SCALE → Apps → Manage Catalogs
2. Add Catalog:
   - Name: `my-apps`
   - Repository: `https://github.com/YOUR_USERNAME/truenas-apps`
   - Branch: `main`
   - Preferred Trains: `charts`
3. Save and wait for sync
4. Install apps from Discover Apps
EOF

# Commit and push
git add .
git commit -m "Initial catalog with rdt-client-manual-download"
git push
```

## Step 3: Add Catalog to TrueNAS

1. **Open TrueNAS UI** → **Apps** → **Manage Catalogs**

2. **Click "Add Catalog"**

3. **Configure the catalog:**
   - **Name:** `my-apps` (or any name you prefer)
   - **Repository:** `https://github.com/YOUR_USERNAME/truenas-apps`
   - **Branch:** `main`
   - **Preferred Trains:** `charts`

4. **Click "Save"**

5. **Wait for sync** - TrueNAS will clone your repo and index the apps (1-2 minutes)

6. **Verify sync:**
   - Check the catalog shows "Healthy" status
   - Look for any error messages

## Step 4: Install Your App

1. **Navigate to Apps** → **Discover Apps**

2. **Filter by your catalog:**
   - Click the filter dropdown
   - Select your catalog name (`my-apps`)

3. **Find your app:**
   - Search for "rdt-client-manual-download"
   - Or browse the list

4. **Click "Install"**

5. **Configure the app:**
   - **Application Name:** `rdt-client` (or any name)
   - **Version:** Select from dropdown
   - **Storage:**
     - Downloads path: `/mnt/pool/downloads`
     - Database path: `/mnt/pool/appdata/rdt-client`
   - **Networking:**
     - Port: `6500`
     - Service Type: `LoadBalancer` or `NodePort`

6. **Click "Install"** and wait for deployment

## Step 5: Access Your App

```bash
# Get the service IP/port
kubectl get svc -n ix-rdt-client

# Access in browser
http://TRUENAS_IP:6500
```

## Optional: Add TrueNAS UI Questions Form

Create `charts/rdt-client-manual-download/questions.yaml` for a better UI experience:

```yaml
groups:
  - name: "Configuration"
    description: "Application configuration"
  - name: "Storage"
    description: "Storage configuration"
  - name: "Networking"
    description: "Network configuration"

questions:
  # Image Configuration
  - variable: image.repository
    label: "Docker Image Repository"
    group: "Configuration"
    schema:
      type: string
      default: "erix12/rdt-client-manual-download"

  - variable: image.tag
    label: "Image Tag"
    group: "Configuration"
    schema:
      type: string
      default: "latest"

  # Storage Configuration
  - variable: persistence.downloads.hostPath
    label: "Downloads Directory"
    description: "Path on TrueNAS host for downloads"
    group: "Storage"
    schema:
      type: hostpath
      required: true
      default: "/mnt/pool/downloads"

  - variable: persistence.database.hostPath
    label: "Database Directory"
    description: "Path on TrueNAS host for database"
    group: "Storage"
    schema:
      type: hostpath
      required: true
      default: "/mnt/pool/appdata/rdt-client"

  # Networking
  - variable: service.type
    label: "Service Type"
    group: "Networking"
    schema:
      type: string
      default: "LoadBalancer"
      enum:
        - value: "ClusterIP"
          description: "ClusterIP (internal only)"
        - value: "NodePort"
          description: "NodePort (accessible via node IP)"
        - value: "LoadBalancer"
          description: "LoadBalancer (recommended)"

  - variable: service.port
    label: "Service Port"
    group: "Networking"
    schema:
      type: int
      default: 6500

  # Environment Variables
  - variable: env.LOG_LEVEL
    label: "Log Level"
    group: "Configuration"
    schema:
      type: string
      default: "Warning"
      enum:
        - value: "Error"
          description: "Errors only"
        - value: "Warning"
          description: "Warnings and errors"
        - value: "Information"
          description: "Info, warnings, and errors"
        - value: "Debug"
          description: "All logs (verbose)"

  # Security Context
  - variable: securityContext.runAsUser
    label: "Run as User ID"
    group: "Configuration"
    schema:
      type: int
      default: 568

  - variable: securityContext.runAsGroup
    label: "Run as Group ID"
    group: "Configuration"
    schema:
      type: int
      default: 568

  # Resources
  - variable: resources.limits.cpu
    label: "CPU Limit"
    group: "Configuration"
    schema:
      type: string
      default: "1000m"

  - variable: resources.limits.memory
    label: "Memory Limit"
    group: "Configuration"
    schema:
      type: string
      default: "1Gi"
```

This creates a nice form-based UI in TrueNAS instead of editing YAML.

## Optional: Add App README

Create `charts/rdt-client-manual-download/app-readme.md`:

```markdown
# rdt-client Manual Download

Real-Debrid Torrent Client with manual download feature.

## Features

- Manual download control - decide when to download each torrent
- Works with Real-Debrid, AllDebrid, Premiumize, TorBox, DebridLink
- Compatible with Sonarr/Radarr/Lidarr
- Web UI on port 6500
- Multi-architecture support (AMD64, ARM64)

## Initial Setup

1. Access the web UI: http://TRUENAS_IP:6500
2. Set your username/password
3. Go to Settings and add your debrid provider API key
4. Disable "Automatic downloads" to enable manual mode
5. Add torrents and click "Start Download" when ready

## Support

- GitHub: https://github.com/YOUR_USERNAME/rdt-client
- Original Project: https://github.com/rogerfar/rdt-client
```

## Updating Your App

When you make changes to your app:

```bash
# Update version in Chart.yaml
cd truenas-apps/charts/rdt-client-manual-download
nano Chart.yaml
# Change version: 1.0.0 to 1.0.1

# Commit and push
git add .
git commit -m "Update to v1.0.1"
git push

# TrueNAS will auto-sync (or force refresh in Manage Catalogs)
```

Then in TrueNAS UI:
1. Apps → Installed
2. Find your app → Click menu (⋮)
3. Click "Update"
4. Select new version
5. Click "Update"

## Troubleshooting

### Catalog Won't Sync

**Check the catalog status:**
```bash
# SSH into TrueNAS
ssh root@TRUENAS_IP

# Check catalog logs
k3s kubectl logs -n ix deploy/catalog-sync
```

**Common issues:**
- Wrong branch name (use `main` not `master`)
- Wrong directory structure (must have `/charts/` directory)
- Invalid Chart.yaml syntax
- Repository is private (must be public or add credentials)

### App Won't Install

**Check Helm chart validity:**
```bash
# On your Mac, validate the chart
cd ~/github/truenas-apps
helm lint charts/rdt-client-manual-download
helm template charts/rdt-client-manual-download
```

**Check TrueNAS logs:**
```bash
# SSH into TrueNAS
tail -f /var/log/middlewared.log
```

### Force Catalog Refresh

In TrueNAS UI:
1. Apps → Manage Catalogs
2. Click "Refresh All" or menu (⋮) → "Refresh" for specific catalog

Or via CLI:
```bash
midclt call catalog.sync
```

## Example: Complete Workflow

```bash
# 1. Create and setup repo
git clone https://github.com/YOUR_USERNAME/truenas-apps.git
cd truenas-apps
mkdir -p charts
cp -r ~/github/rdt-client/helm-chart/rdt-client-manual-download charts/

# 2. Create README
cat > README.md << 'EOF'
# My TrueNAS Apps
Custom apps for TrueNAS SCALE.
EOF

# 3. Commit
git add .
git commit -m "Add rdt-client-manual-download"
git push

# 4. Add catalog in TrueNAS UI
# Apps → Manage Catalogs → Add Catalog
# Name: my-apps
# Repo: https://github.com/YOUR_USERNAME/truenas-apps
# Branch: main
# Train: charts

# 5. Install app
# Apps → Discover Apps → Filter by "my-apps" → Install
```

## Benefits of Custom Catalog

✅ **Easy updates** - Push to Git, TrueNAS auto-syncs
✅ **Version control** - Roll back to previous versions
✅ **Shareable** - Others can use your catalog URL
✅ **Professional** - Same experience as official TrueCharts
✅ **Multiple apps** - Add more custom apps to same catalog

## Alternative: Quick Install Without Catalog

If you just want to test quickly without setting up a catalog:

```bash
# SSH into TrueNAS
ssh root@TRUENAS_IP

# Clone your rdt-client repo
cd /tmp
git clone https://github.com/YOUR_USERNAME/rdt-client.git

# Install directly with Helm
helm install rdt-client ./rdt-client/helm-chart/rdt-client-manual-download \
  --set persistence.downloads.hostPath=/mnt/pool/downloads \
  --set persistence.database.hostPath=/mnt/pool/appdata/rdt-client \
  --set service.type=LoadBalancer
```

But using a catalog is much better for long-term use!
