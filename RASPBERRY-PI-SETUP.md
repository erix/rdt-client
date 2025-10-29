# Raspberry Pi Setup Guide

Your custom rdt-client with manual download feature fully supports Raspberry Pi!

## Supported Models

✅ **Raspberry Pi 5** (64-bit OS) - `linux/arm64`
✅ **Raspberry Pi 4** (64-bit OS) - `linux/arm64`
✅ **Raspberry Pi 3/3 B+** (64-bit OS) - `linux/arm64`

**Note:** This image requires a **64-bit OS** (Raspberry Pi OS Lite 64-bit or Ubuntu Server 64-bit).
For older 32-bit systems (Pi 2 or 32-bit OS), consider upgrading to 64-bit OS for better performance.

The Docker image automatically detects and uses the correct architecture!

## Prerequisites

- Raspberry Pi OS (Bullseye or Bookworm recommended)
- Docker installed
- At least 1GB RAM (2GB+ recommended)
- External storage recommended for downloads (USB drive, NAS mount, etc.)

## Quick Start

### Install Docker (if not already installed)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Reboot to apply group changes
sudo reboot
```

### Deploy with Docker Run

```bash
# Create directories
mkdir -p ~/rdt-client/downloads
mkdir -p ~/rdt-client/db

# Run the container
docker run -d \
  --name rdt-client-manual-download \
  --restart unless-stopped \
  -p 6500:6500 \
  -v ~/rdt-client/downloads:/data/downloads \
  -v ~/rdt-client/db:/data/db \
  erix12/rdt-client-manual-download:latest

# Check logs
docker logs -f rdt-client-manual-download
```

### Deploy with Docker Compose (Recommended)

**Step 1: Create docker-compose.yml**

```bash
mkdir -p ~/rdt-client
cd ~/rdt-client
nano docker-compose.yml
```

**Step 2: Add this content:**

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
      # Change these paths to match your setup
      - ./downloads:/data/downloads
      - ./db:/data/db

    environment:
      - LOG_LEVEL=Warning

    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6500"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
```

**Step 3: Start the container**

```bash
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

**Step 4: Access the Web UI**

Open browser to: **http://RASPBERRY_PI_IP:6500**

## Using External Storage

### USB Drive

```bash
# Find your USB drive
lsblk

# Mount it (example: /dev/sda1)
sudo mkdir -p /mnt/usb
sudo mount /dev/sda1 /mnt/usb

# Make mount permanent (add to /etc/fstab)
echo "/dev/sda1 /mnt/usb ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab

# Update docker-compose.yml volumes
volumes:
  - /mnt/usb/downloads:/data/downloads
  - ./db:/data/db
```

### NFS/SMB Share

```bash
# Install CIFS utils for SMB
sudo apt install cifs-utils

# Mount SMB share
sudo mkdir -p /mnt/nas
sudo mount -t cifs //NAS_IP/share /mnt/nas -o username=USER,password=PASS

# Or add to /etc/fstab for permanent mount
echo "//NAS_IP/share /mnt/nas cifs credentials=/root/.smbcredentials,uid=1000,gid=1000 0 0" | sudo tee -a /etc/fstab

# Update volumes in docker-compose.yml
volumes:
  - /mnt/nas/downloads:/data/downloads
  - ./db:/data/db
```

## Performance Optimization for Raspberry Pi

### Recommended Settings

After accessing the web UI (http://RASPBERRY_PI_IP:6500):

1. **Settings** → **Download Client**:
   - **Download speed**: `0` (unlimited) or limit based on your network
   - **Parallel connections per download**: `4` (lower than default to reduce CPU/RAM)
   - **Chunk Count**: `4` (lower for less memory usage)

2. **Settings** → **General**:
   - **Maximum parallel downloads**: `1-2` (Raspberry Pi has limited resources)
   - **Maximum unpack processes**: `1`

3. **Settings** → **Provider**:
   - **Check Interval**: `15` seconds (reduce API calls)

### Memory Considerations

If you have a Pi with limited RAM (1GB):

```yaml
# Add memory limits to docker-compose.yml
services:
  rdt-client:
    # ... existing config ...
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
```

### Use External Storage for Downloads

**Never download large files to SD card!** Always use:
- USB hard drive or SSD
- NAS/network share
- External storage

This prevents:
- SD card wear and corruption
- Performance issues
- Running out of space

## Initial Configuration

1. **Access Web UI**: http://RASPBERRY_PI_IP:6500
2. **Set credentials**: First login credentials are saved
3. **Configure Provider**:
   - Go to **Settings**
   - Add your Real-Debrid/AllDebrid API key
   - Set **Download path**: `/data/downloads`
   - Set **Mapped path**: `/data/downloads` (same for Pi)
4. **Enable Manual Download**:
   - Find **"Automatic downloads"** in Settings
   - **Uncheck** to enable manual download mode
   - Save settings

## Managing the Container

### Start/Stop/Restart

```bash
cd ~/rdt-client

# Stop
docker-compose stop

# Start
docker-compose start

# Restart
docker-compose restart

# Stop and remove
docker-compose down

# Update to latest image
docker-compose pull
docker-compose up -d
```

### View Logs

```bash
# Follow logs
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100

# Specific time range
docker-compose logs --since 10m
```

### Check Resource Usage

```bash
# Container stats
docker stats rdt-client-manual-download

# System resources
htop  # or: sudo apt install htop
```

## Troubleshooting

### Container Won't Start

Check logs:
```bash
docker-compose logs
```

Common issues:
- Port 6500 already in use: Change port in docker-compose.yml
- Volume permission errors: `sudo chown -R 1000:1000 ~/rdt-client`
- Out of memory: Add memory limits or reduce parallel downloads

### Slow Performance

1. **Reduce parallel downloads** in Settings
2. **Use external storage** (USB/NAS) instead of SD card
3. **Enable swap** if you have < 2GB RAM:
   ```bash
   sudo dphys-swapfile swapoff
   sudo nano /etc/dphys-swapfile
   # Set: CONF_SWAPSIZE=2048
   sudo dphys-swapfile setup
   sudo dphys-swapfile swapon
   ```

### Downloads Fail or Timeout

Increase timeout in Settings:
- **Connection Timeout**: `10000` ms (10 seconds)

### SD Card Full

Move downloads to USB:
```bash
# Stop container
docker-compose down

# Move data to USB
sudo mv ~/rdt-client/downloads /mnt/usb/
sudo ln -s /mnt/usb/downloads ~/rdt-client/downloads

# Start container
docker-compose up -d
```

### Can't Access Web UI

1. Check container is running: `docker ps`
2. Check firewall: `sudo ufw status`
3. Test locally: `curl http://localhost:6500`
4. Use Pi's IP, not `localhost`, from other devices

## Auto-Start on Boot

Docker Compose with `restart: unless-stopped` automatically starts on boot.

To ensure Docker starts on boot:
```bash
sudo systemctl enable docker
```

## Integration with Sonarr/Radarr on Raspberry Pi

If running Sonarr/Radarr on the same Pi:

1. **In Sonarr/Radarr**: Settings → Download Clients → Add → qBittorrent
2. Configure:
   - Host: `localhost` or Pi's IP
   - Port: `6500`
   - Username/Password: Your rdt-client credentials
   - Category: `sonarr` or `radarr`
3. Test and Save

## Backup

```bash
# Backup database
cp -r ~/rdt-client/db ~/rdt-client/db.backup

# Or create a compressed backup
tar czf rdt-client-backup-$(date +%Y%m%d).tar.gz ~/rdt-client/db
```

## Updating

```bash
cd ~/rdt-client

# Pull latest image
docker-compose pull

# Recreate container
docker-compose up -d

# Check logs
docker-compose logs -f
```

## Monitoring

### Simple Health Check

```bash
# Check if container is running
docker ps | grep rdt-client

# Check if web UI responds
curl -f http://localhost:6500 && echo "OK" || echo "FAIL"
```

### Set up Automatic Monitoring

Create a simple monitoring script:

```bash
cat > ~/check-rdt-client.sh << 'EOF'
#!/bin/bash
if ! curl -sf http://localhost:6500 > /dev/null; then
    echo "rdt-client is down, restarting..."
    cd ~/rdt-client && docker-compose restart
fi
EOF

chmod +x ~/check-rdt-client.sh

# Add to crontab (check every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * ~/check-rdt-client.sh") | crontab -
```

## Architecture Detection

To verify which architecture is being used:

```bash
# Check Docker image architecture
docker inspect erix12/rdt-client-manual-download:latest | grep Architecture

# Check system architecture
uname -m
# armv7l = 32-bit ARM (linux/arm/v7)
# aarch64 = 64-bit ARM (linux/arm64)
```

## Performance Expectations

### Raspberry Pi 5 (2GB+)
- ✅ Excellent performance
- ✅ Multiple parallel downloads
- ✅ Can run multiple *arr apps alongside

### Raspberry Pi 4 (2GB+)
- ✅ Good performance
- ✅ 2-3 parallel downloads recommended
- ✅ Can run *arr apps with moderate loads

### Raspberry Pi 3 B+
- ⚠️ Moderate performance
- ⚠️ 1-2 parallel downloads recommended
- ⚠️ Consider using external downloader (Aria2c)

### Raspberry Pi 2/3 (1GB RAM)
- ⚠️ Limited performance
- ⚠️ 1 parallel download only
- ⚠️ Best for lightweight usage

## Additional Tips

1. **Use quality SD card**: Class 10 or better, preferably A1/A2 rated
2. **Regular updates**: Keep Raspberry Pi OS updated
3. **Cooling**: Ensure good ventilation or use heatsinks/fan
4. **Power supply**: Use official power supply or quality 3A+ adapter
5. **Network**: Ethernet preferred over WiFi for better performance
6. **Storage**: SSD via USB is much faster than SD card for downloads

## Support

For issues specific to this custom version:
- GitHub: https://github.com/erix/rdt-client/issues

For general rdt-client questions:
- Original project: https://github.com/rogerfar/rdt-client
