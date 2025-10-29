# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Real-Debrid Torrent Client (rdt-client) is a web interface to manage torrents on Real-Debrid, AllDebrid, Premiumize, TorBox, or DebridLink. It supports automatic downloading to local machines, unpacking files, and implements a fake qBittorrent API for integration with Sonarr, Radarr, and similar applications.

**Tech Stack:**
- Backend: .NET 9.0 (ASP.NET Core, Entity Framework Core, SignalR)
- Frontend: Angular 20+ with RxJS
- Database: SQLite
- Real-time communication: SignalR WebSockets

## Development Commands

### Frontend (Angular)

```bash
cd client
npm install                    # Install dependencies
npm start                      # Start dev server (ng serve)
npm run build                  # Production build
npm run watch                  # Development build with watch mode
npm run lint                   # Run ESLint
npm run prettier               # Format code with Prettier
npm run update                 # Update Angular packages
```

The Angular build outputs to `../server/RdtClient.Web/wwwroot` by default.

### Backend (.NET)

```bash
cd server

# Build and run
dotnet restore RdtClient.sln
dotnet build RdtClient.sln
dotnet run --project RdtClient.Web/RdtClient.Web.csproj

# Testing
dotnet test                    # Run all tests
dotnet test --logger "console;verbosity=detailed"  # Verbose test output

# Publishing
dotnet publish -c Release -o out
```

**Note:** When debugging, run `RdtClient.Web.dll` directly, not IISExpress.

### Docker

```bash
docker build --tag rdtclient .
docker run --publish 6500:6500 --detach --name rdtclientdev rdtclient:latest
docker stop rdtclient
docker rm rdtclient
```

Or use the provided `docker-build.bat` script.

The Dockerfile is a multi-stage build:
1. Stage 1: Build Angular frontend with Node.js
2. Stage 2: Build .NET backend and run tests
3. Stage 3: Create runtime image with ASP.NET Core Runtime

## Architecture

### Backend Structure (.NET)

The solution (`server/RdtClient.sln`) contains four projects:

#### 1. RdtClient.Web (API Layer)
- **Location:** `server/RdtClient.Web/`
- **Responsibility:** HTTP API endpoints, SignalR hub, authentication middleware, and SPA hosting
- **Key Controllers:**
  - `TorrentsController` - Main torrent CRUD operations
  - `QBittorrentController` - qBittorrent API v4.3.2+ emulation for Sonarr/Radarr integration
  - `AuthController` - User authentication and provider setup
  - `SettingsController` - Application settings and path testing
- **SignalR Hub:** `RdtHub` at `/hub` endpoint broadcasts torrent updates every 1 second

#### 2. RdtClient.Service (Business Logic)
- **Location:** `server/RdtClient.Service/`
- **Responsibility:** Core orchestration, provider integration, download management, and background services

**Core Services:**
- `Torrents` - Main orchestrator for torrent operations, delegates to provider clients
- `Downloads` - Download lifecycle and state management
- `TorrentRunner` - Main background service running on 1-second tick, manages active downloads and unpacking
- `RemoteService` - Broadcasts updates via SignalR
- `QBittorrent` - Implements qBittorrent API compatibility
- `UnpackClient` - RAR/ZIP extraction using SharpCompress

**Torrent Provider Clients (ITorrentClient implementations):**
- `RealDebridTorrentClient` (uses RDNET library)
- `AllDebridTorrentClient`
- `PremiumizeTorrentClient`
- `TorBoxTorrentClient`
- `DebridLinkClient`

Each provider implements: `GetTorrents()`, `AddMagnet()`, `AddFile()`, `GetAvailableFiles()`, `SelectFiles()`, `Unrestrict()`, `UpdateData()`, `GetDownloadInfos()`

**Download Clients (IDownloader implementations):**
- `Aria2cDownloader` - External Aria2c RPC client (via Aria2NET)
- `DownloadStationDownloader` - Synology DownloadStation integration
- `SymlinkDownloader` - Creates symlinks instead of downloading (for mount scenarios)
- `BezzadDownloader` - Direct HTTP download with chunking

**Background Services:**
- `TaskRunner` - 1-second tick for torrent/download state management
- `WebsocketsUpdater` - 1-second tick for SignalR broadcasts
- `ProviderUpdater` - Periodic provider data refresh
- `WatchFolderChecker` - Monitors folders for new torrent files
- `UpdateChecker` - Checks for new application versions
- `Startup` - Initialization handler

#### 3. RdtClient.Data (Data Access)
- **Location:** `server/RdtClient.Data/`
- **Responsibility:** Entity Framework Core models, SQLite DbContext, and repositories
- **Key Components:**
  - `DataContext` - SQLite database context with ASP.NET Identity
  - Data Repositories: `TorrentData`, `DownloadData`, `SettingData`, `UserData`
  - Enums: `Provider`, `DownloadClient`, `TorrentStatus`, `TorrentDownloadAction`

**Data Model:**
```
Torrent (1:N) Download
├─ TorrentId (PK)
├─ Hash (provider torrent ID)
├─ ClientKind (Provider enum)
├─ DownloadClient (download client type)
├─ Downloads[]
    ├─ DownloadId (PK)
    ├─ Path, Link, FileName
    └─ State tracking (Queued → Started → Finished → Unpacking → Completed)
```

#### 4. RdtClient.Service.Test (Unit Tests)
- **Location:** `server/RdtClient.Service.Test/`
- Tests for service layer logic

### Frontend Structure (Angular)

**Location:** `client/src/app/`

**Core Components:**
- `MainLayoutComponent` - Root layout with navbar
- `TorrentTableComponent` - Main torrent list view
- `TorrentComponent` - Individual torrent detail page
- `AddNewTorrentComponent` - Torrent upload/magnet entry
- `SettingsComponent` - Configuration UI
- `ProfileComponent` - Provider account display
- `LoginComponent` - Authentication
- `SetupComponent` - Initial setup flow

**Services:**
- `TorrentService` - HTTP API + SignalR WebSocket management
  - Exposes `update$` Subject for real-time updates
  - Methods: `getList()`, `get()`, `uploadMagnet()`, `uploadFile()`, `delete()`, etc.
- `AuthService` - Authentication and provider setup
- `SettingsService` - Settings CRUD and path testing

**Real-time Updates:**
1. `TorrentService.connect()` establishes SignalR connection
2. Backend broadcasts updates every 1 second via `RdtHub`
3. `TorrentService.update$` Subject emits new data
4. Components subscribe and update UI

### Request Flow

```
User Request → Controller (Web)
  → Torrents Service (orchestration)
  → ITorrentClient (provider-specific API)
  → TorrentRunner (lifecycle management)
  → IDownloader (download execution)
  → Downloads Service (state persistence)
  → DataContext (SQLite)

Background: TorrentRunner.Tick() (1 sec)
  → Checks download/unpack state
  → Updates progress
  → RemoteService.Update()
  → SignalR broadcast to all clients
```

### Download State Machine

```
Torrent Added
  ↓
Files Selected (auto/manual)
  ↓
Download Queued → Download Started → Download Finished
  ↓ (if packed)
Unpacking Queued → Unpacking Started → Unpacking Finished
  ↓
Completed
```

Each stage has timestamps in the `Download` entity. Errors trigger retry logic based on settings.

## Key Integration Points

### qBittorrent API Emulation

`QBittorrentController` implements qBittorrent v4.3.2+ API endpoints:
- `POST /api/v2/auth/login` - Authentication
- `GET /api/v2/app/version` - Returns "v4.3.2"
- `GET /api/v2/torrents/info` - Lists torrents
- `GET /api/v2/app/preferences` - Returns preferences

This allows Sonarr, Radarr, and similar tools to treat rdt-client as a standard qBittorrent instance.

**Category Mapping:** When Sonarr/Radarr set a category (e.g., "sonarr"), files download to `{DownloadPath}/{category}/`.

### Provider Abstraction

All debrid providers implement `ITorrentClient` interface. The `Torrents` service selects the active provider based on `Settings.Get.Provider.Provider` enum. This allows seamless switching between Real-Debrid, AllDebrid, Premiumize, TorBox, and DebridLink.

### Download Client Selection

Each torrent has a `DownloadClient` field. The `DownloadClient` class instantiates the appropriate `IDownloader` implementation. The `TorrentRunner` tracks active downloads in a `ConcurrentDictionary<Guid, DownloadClient>`.

### Dependency Injection Configuration

**Service Registration (DiConfig.cs):**
- All torrent clients registered as scoped services
- HTTP client factory with Polly retry policies (exponential backoff, max 5 retries)
- Background services registered as hosted services

## Development Guidelines

### Backend Development

- **Namespace Convention:** `RdtClient.{Project}.{Folder}`
- **Async/Await:** Use async methods for I/O operations
- **Logging:** Use `ILogger<T>` injected via constructor
- **HTTP Clients:** Use `IHttpClientFactory` with Polly retry policies
- **Enums:** Define in `RdtClient.Data/Enums/` for reuse across layers

### Frontend Development

- **Component Structure:** Follow Angular style guide
- **Services:** Injectable services for all HTTP communication
- **Real-time Updates:** Subscribe to `TorrentService.update$` for live data
- **Pipes:** Use custom pipes for formatting (filesize, status, etc.)
- **Routing:** Defined in `app-routing.module.ts`

### Testing

- Backend tests use xUnit framework
- Run tests with `dotnet test` from `server/` directory
- Docker build automatically runs tests before publishing
- Tests are located in `RdtClient.Service.Test/`

### Configuration

**appsettings.json:**
- `LogLevel.Path` - Log file location
- `Database.Path` - SQLite database path
- `BASE_PATH` - Optional base path for reverse proxy (e.g., `/rdt` instead of `/`)

**Windows Paths:** Escape slashes (e.g., `D:\\RdtClient\\db\\rdtclient.db`)

### Common Tasks

**Reset Database:**
Delete `rdtclient.db` and restart the service.

**Change Log Level:**
Update `appsettings.json` or set `LogLevel=Debug` environment variable.

**Running Behind Reverse Proxy:**
Set `BASE_PATH` environment variable or update `BasePath` in `appsettings.json`.

## Important Notes

- Default port: **6500**
- First login credentials are stored as admin credentials
- Angular build outputs directly to `server/RdtClient.Web/wwwroot/` for integrated deployment
- SignalR hub updates every 1 second; be mindful of performance when adding expensive operations
- Download progress in Sonarr/Radarr may not be accurate due to API emulation limitations
- When using symlink downloader, ensure rclone mount paths match exactly across all apps
