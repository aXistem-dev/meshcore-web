# MeshCore Web App

<div align="center">
  <img src="logo.svg" alt="MeshCore Logo" width="200">
</div>

The MeshCore Companion App - a web-based interface for connecting to and managing MeshCore Companion LoRa devices.

### Version

Current version: [**v1.36.0**](https://files.liamcottle.net/MeshCore/v1.36.0/MeshCore-v1.36.0+60-c6748b6-web.zip) ([build 60](./version.json))

## About

This is the web version of the MeshCore Companion App, built with Flutter. It allows you to connect to MeshCore devices via Bluetooth Low Energy (BLE) or USB Serial directly from your web browser, enabling you to send messages, manage contacts, and interact with the MeshCore mesh network.

## Features

- Connect to MeshCore Companion devices via BLE or USB Serial
- Send and receive messages on the mesh network
- Manage contacts, channels and remote repeaters
- View network topology and node information
- Real-time mesh network interaction

## Browser Requirements

Chrome/Edge (desktop or Android) via HTTPS or localhost access required for functionality.

## Original Files

Original app files are available at [https://files.liamcottle.net/MeshCore](https://files.liamcottle.net/MeshCore), including:
- **Web builds** (this repository)
- **macOS builds**
- **Android builds**
- **Windows builds**

## Updating from Source

### Automated Update Scripts

- **`./update-from-source.sh`** - Downloads and updates files locally only (does not update README.md or commit changes)
- **`./update-from-source-and-push.sh`** - Complete automated workflow: downloads, updates README.md, commits, and pushes to this repository

For manual updates, see the Manual Update Workflow section below.

### Manual Update Workflow

When updating to a new version manually:

1. **Download the new version** from the [MeshCore releases](https://files.liamcottle.net/MeshCore) (e.g., `MeshCore-v1.36.0+60-c6748b6-web.zip`)

2. **Extract and replace files** in the repository:
   - Extract the zip file
   - Copy all files from the `web/` directory to the repository root

3. **Verify changes** by checking unstaged files:
   ```bash
   git status
   git diff
   ```

4. **Update README.md** with the new version:
   - Update the version number and build number in the "Current version" line
   - Update the download link URL to match the new version

5. **Stage and commit** all changes:
   ```bash
   git add -A
   git commit -m "Update to v1.XX.X (build XX)"
   ```

6. **Verify the commit** includes all necessary files:
   ```bash
   git log -1 --stat
   ```

## Docker Deployment

Docker configuration to run the MeshCore webapp in a container using nginx on a lightweight Alpine Linux base image.

Pre-built Docker images are available from GitHub Container Registry: `ghcr.io/axistem-dev/meshcore-web:latest`

### Quick Start

```bash
# Using Docker Compose (recommended)
docker compose up -d

# Or using Docker directly
docker run -d -p 8080:80 --name meshcore-web ghcr.io/axistem-dev/meshcore-web:latest
```

The app will be available at http://localhost:8080

### Building the docker image yourself

```bash
# Build the image
docker build -t meshcore-web .
```

### Configuration

Change the port by modifying `docker-compose.yml` or using `-p 3000:80` with `docker run`.

## License

TBD - See the original MeshCore project for license information.

