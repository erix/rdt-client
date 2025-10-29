# Testing Manual Download Feature on Mac

## Prerequisites

### 1. Install .NET 9 SDK

**Option A: Using Homebrew (Recommended)**
```bash
brew install dotnet@9
```

**Option B: Direct Download**
Download from: https://dotnet.microsoft.com/download/dotnet/9.0
- Choose "macOS Installer" for your architecture (Intel x64 or Apple Silicon arm64)

**Verify Installation:**
```bash
dotnet --version
# Should show: 9.0.x
```

### 2. Verify Node.js
You already have Node.js v23.10.0 installed ✓

## Running the Application

### Step 1: Build and Run Backend (.NET)

```bash
# Navigate to server directory
cd ~/github/rdt-client/server

# Restore dependencies
dotnet restore RdtClient.sln

# Build the solution
dotnet build RdtClient.sln

# Run tests (optional but recommended)
dotnet test

# Run the backend server
dotnet run --project RdtClient.Web/RdtClient.Web.csproj
```

The backend will start on **http://localhost:6500**

⚠️ **Note:** On first run, you'll need to:
1. Set up authentication credentials
2. Configure your debrid provider API key (Real-Debrid, AllDebrid, etc.)

### Step 2: Build and Run Frontend (Angular)

Open a **new terminal window** and:

```bash
# Navigate to client directory
cd ~/github/rdt-client/client

# Install dependencies (first time only)
npm install

# Start development server
npm start
```

The frontend will start on **http://localhost:4200** (or next available port)

**Note:** For testing, the dev server is better than building because:
- Hot reload for changes
- Better error messages
- Faster iteration

Alternatively, to build for production:
```bash
npm run build
# This builds to ../server/RdtClient.Web/wwwroot
# Then access via http://localhost:6500
```

## Testing the Manual Download Feature

### Part 1: Enable the Feature

1. Open browser to **http://localhost:4200** (dev) or **http://localhost:6500** (production)
2. Login with your credentials
3. Navigate to **Settings** (gear icon in navbar)
4. Scroll down to find the new setting:
   - **"Automatic downloads"**
   - Description: "When enabled, downloads will start automatically after torrent finishes..."
5. **Uncheck** the "Automatic downloads" option
6. Click **Save Settings**

### Part 2: Test Manual Download Trigger

#### Test 1: Add a New Torrent

1. Click **"Add Torrent"** button
2. Add a magnet link or torrent file
3. Wait for the torrent to:
   - Get added to your debrid provider
   - Download on the provider
   - Finish on the provider
4. **Expected Result:**
   - Status should show **"Ready to Download"** (not downloading to your host)
   - Torrent should remain visible in the list

#### Test 2: Individual Torrent Detail Page

1. Click on the torrent from the list
2. You should see a **green "Start Download" button** next to "Delete Torrent" and "Retry Torrent"
3. Click **"Start Download"**
4. Confirm in the modal
5. **Expected Result:**
   - Modal closes
   - Downloads should begin (status changes to "Queued for downloading")
   - Files start downloading to your host

#### Test 3: Row Action in Table

1. Go back to the main torrent list
2. Add another test torrent (or delete downloads and retry the previous one)
3. Wait for it to reach "Ready to Download" status
4. Look for the **green download icon button** in the new "Actions" column
5. Click the download icon
6. Confirm in the modal
7. **Expected Result:**
   - Downloads start immediately

#### Test 4: Bulk Action

1. Add multiple torrents (2-3 is enough)
2. Wait for them to reach "Ready to Download" status
3. Check the checkboxes next to multiple torrents
4. Click the **"Start Download" button** in the action bar below the table
5. Confirm in the modal
6. **Expected Result:**
   - All selected torrents start downloading simultaneously

### Part 3: Verify Backward Compatibility

1. Go back to **Settings**
2. **Enable** "Automatic downloads"
3. Save settings
4. Add a new torrent
5. **Expected Result:**
   - Torrent should automatically start downloading to host when finished on provider
   - This is the original behavior (no manual intervention needed)

## Troubleshooting

### Backend Issues

**Port already in use:**
```bash
# Find process using port 6500
lsof -ti:6500 | xargs kill -9

# Or change port in appsettings.json
```

**Database issues:**
```bash
# Delete and recreate database
rm -rf ~/github/rdt-client/server/RdtClient.Web/rdtclient.db
# Restart backend
```

### Frontend Issues

**Build errors:**
```bash
# Clear node_modules and reinstall
cd ~/github/rdt-client/client
rm -rf node_modules package-lock.json
npm install
```

**Port conflict:**
```bash
# Angular CLI will automatically use next available port
# Check console output for actual port
```

### Feature Not Working

**Setting doesn't appear:**
- Database might need reset (delete rdtclient.db)
- Check browser console for errors (F12 → Console)

**"Start Download" button doesn't appear:**
- Verify torrent status is exactly "Ready to Download"
- Check: `torrent.rdStatus === 4` and `torrent.downloads.length === 0`
- Open browser DevTools (F12) → Console for errors

**API errors:**
- Check backend logs in terminal
- Look for errors with `StartDownload` in the message

## Quick Test Without Debrid Provider

If you don't have a debrid provider set up, you can still verify the UI changes:

1. Run backend and frontend
2. Complete initial setup (even with fake API key)
3. Check Settings page for new "Automatic downloads" option
4. The UI components (buttons, modals) can be verified even without real torrents

## Clean Up After Testing

```bash
# Stop servers (Ctrl+C in both terminal windows)

# Optional: Reset database
rm ~/github/rdt-client/server/RdtClient.Web/rdtclient.db

# Optional: Remove build artifacts
cd ~/github/rdt-client/server && dotnet clean
cd ~/github/rdt-client/client && rm -rf dist
```

## Alternative: Docker Testing

If you prefer Docker:

```bash
cd ~/github/rdt-client
docker build --tag rdtclient-test .
docker run -p 6500:6500 rdtclient-test

# Access at http://localhost:6500
```

## Questions?

If you encounter any issues:
1. Check the browser console (F12 → Console)
2. Check backend terminal for .NET errors
3. Verify all files were saved correctly
4. Make sure both backend and frontend are running
