# Real-Debrid Torrent Client (Manual Download Fork)

[![GitHub](https://img.shields.io/badge/GitHub-erix%2Frdt--client-blue?logo=github)](https://github.com/erix/rdt-client)
[![Docker Pulls](https://img.shields.io/docker/pulls/erix/rdt-client-manual-download)](https://hub.docker.com/r/erix/rdt-client-manual-download)

A web interface to manage torrents on Real-Debrid, AllDebrid, Premiumize, TorBox, and DebridLink with **manual download control**.

## Key Features

- 🎯 **Manual Download Control** - Choose when to download files from debrid providers to your local machine
- ⏸️ **Pause/Resume/Cancel** - Full control over active downloads
- 🔄 **Auto Download** - Automatic downloading and unpacking of files
- 🎬 **Sonarr/Radarr Integration** - qBittorrent API emulation for seamless integration
- 🌐 **Multi-Provider Support** - Real-Debrid, AllDebrid, Premiumize, TorBox, DebridLink
- 📦 **Smart Unpacking** - Automatic extraction of RAR/ZIP archives
- 💾 **Multiple Downloaders** - Built-in, Aria2c, Synology DownloadStation, or Symlink

## Supported Architectures

Multi-platform images for `amd64` (Intel/AMD) and `arm64` (Raspberry Pi 4/5, Apple Silicon).

## Quick Start

### Docker Compose (Recommended)

```yaml
version: '3.3'
services:
  rdt-client:
    image: erix/rdt-client-manual-download:latest
    container_name: rdt-client
    ports:
      - 6500:6500
    volumes:
      - ./data/db:/data/db
      - ./data/downloads:/data/downloads
    environment:
      - TZ=Europe/London
    restart: unless-stopped
```

### Docker CLI

```bash
docker run -d \
  --name=rdt-client \
  -p 6500:6500 \
  -v $(pwd)/data/db:/data/db \
  -v $(pwd)/data/downloads:/data/downloads \
  -e TZ=Europe/London \
  --restart unless-stopped \
  erix/rdt-client-manual-download:latest
```

## Configuration

| Parameter | Description |
|-----------|-------------|
| `-p 6500` | Web UI port |
| `-v /data/db` | Database and configuration |
| `-v /data/downloads` | Download directory |
| `-e TZ` | Timezone (e.g., `America/New_York`) |

## First Run

1. Navigate to `http://localhost:6500`
2. Create admin account on first login
3. Configure your debrid provider (API key required)
4. Add torrents via magnet links or files
5. Select files and choose to download automatically or manually

## What's Different in This Fork?

This fork adds **manual download control** - you can now:
- Add torrents to your debrid provider without automatically downloading to your host
- Review files and choose when to start downloads
- Pause, resume, or cancel active downloads
- Use the "Start Download" button when you're ready

Perfect for managing storage space and bandwidth!

## Sonarr/Radarr Integration

Configure as qBittorrent download client:
- **Host**: `<rdt-client-ip>`
- **Port**: `6500`
- **Username/Password**: Your rdt-client credentials
- **Category**: Optional (creates subfolders)

## Tech Stack

Built with Angular 20+ and .NET 9 for modern performance and reliability.

## Support

- 📖 [Documentation](https://github.com/erix/rdt-client)
- 🐛 [Report Issues](https://github.com/erix/rdt-client/issues)
- 💬 [Discussions](https://github.com/erix/rdt-client/discussions)

## Updating

```bash
docker-compose pull
docker-compose up -d
```

Or with Docker CLI:

```bash
docker pull erix/rdt-client-manual-download:latest
docker stop rdt-client
docker rm rdt-client
# Run the docker run command again
```

## License

Based on [rogerfar/rdt-client](https://github.com/rogerfar/rdt-client) - forked to add manual download features.
