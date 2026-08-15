# Dockerized MeshCore Web App

<div align="center">
  <img src="logo.svg" alt="MeshCore Logo" width="200">
</div>

The MeshCore Companion App - a web-based interface for connecting to and managing MeshCore Companion LoRa devices.

### Version

Current version: [**v1.48.0**](https://files.liamcottle.net/MeshCore/v1.48.0/MeshCore-v1.48.0+76-c3cd531-web.zip) ([build 76](./version.json))

## About

This is the web version of the MeshCore Companion App, built with Flutter. It allows you to connect to MeshCore devices via Bluetooth Low Energy (BLE) or USB Serial directly from your web browser, enabling you to send messages, manage contacts, and interact with the MeshCore mesh network.

**To run it:** pull the pre-built Docker image `ghcr.io/axistem-dev/meshcore-web:latest`
This repo mainly publishes that image, hosts the static web build, and documents maintainer workflows.

## Features

- Connect to MeshCore Companion devices via BLE or USB Serial
- Send and receive messages on the mesh network
- Manage contacts, channels and remote repeaters
- View network topology and node information
- Real-time mesh network interaction
- Docker deployment for containerized hosting

## Browser Requirements

Chrome/Edge (desktop or Android) via HTTPS or localhost access required for functionality.

## MeshCore Companion App & Downloads

The MeshCore Companion App is the original application created by [Liam Cottle](https://liamcottle.com).

**App stores & hosted web:**
- **Android**: [Google Play Store](https://play.google.com/store/apps/details?id=com.liamcottle.meshcore.android)
- **iOS**: [App Store](https://apps.apple.com/us/app/meshcore/id6742354151?platform=iphone)
- **Web**: [MeshCore Web App](https://app.meshcore.io) (also this repo’s [Docker image](#docker-deployment))

**Desktop & web archives** on [files.liamcottle.net/MeshCore](https://files.liamcottle.net/MeshCore), per version:
- **Web** builds (this repository)
- **macOS**
- **Windows**
- **Linux** (x86_64 `.zip` and `.AppImage`)

## Docker Deployment

Run the MeshCore web app in a container (nginx on Alpine). **Use the published image**:

`ghcr.io/axistem-dev/meshcore-web:latest`

### Quick Start (recommended)

Pull and run the image directly (works on any machine with Docker):

```bash
docker run -d \
  -p 8080:80 \
  --restart unless-stopped \
  --name meshcore-web \
  ghcr.io/axistem-dev/meshcore-web:latest
```

Open http://localhost:8080

To use another port, change `-p` (e.g. `-p 3000:80` for http://localhost:3000).

### Docker Compose (optional)

Clone this repo only if you want the included `docker-compose.yml` (same image, plus health check and restart policy):

```bash
git clone https://github.com/aXistem-dev/meshcore-web.git
cd meshcore-web
docker compose up -d
```

### Building locally (optional)

Only if you need a custom image built from this repository’s files:

```bash
git clone https://github.com/aXistem-dev/meshcore-web.git
cd meshcore-web
docker build -t meshcore-web .
docker run -d -p 8080:80 --name meshcore-web meshcore-web
```

## Updating from Source

For maintainers refreshing this repository from upstream web builds.

### Automated Update Scripts

- **`./update-from-source.sh`** — Downloads and updates files locally only (does not commit changes)
- **`./update-from-source-and-push.sh`** — Downloads, updates README.md, commits, and pushes to this repository

For manual updates, see the Manual Update Workflow section below.

### Manual Update Workflow

When updating to a new version manually:

1. **Download the new version** from the [MeshCore releases](https://files.liamcottle.net/MeshCore) (e.g., `MeshCore-v1.44.0+70-86c0436-web.zip`)

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

## License & Privacy

The MeshCore Companion App is **closed source**, built with Flutter, and is free for anyone to use.

### Privacy Policy

Use of the app is subject to the [Privacy Policy](https://meshcore.liamcottle.net/privacy-policy.html).

### Official Resources

- **Official Website**: [meshcore.io](https://meshcore.io/)

### Attribution

This repository contains the web build files of the MeshCore Companion App, maintained by [aXistem](https://github.com/axistem-dev). The original MeshCore Companion App is developed by Liam Cottle ([Liam's GitHub page](https://github.com/liamcottle)). See the [Privacy Policy](https://meshcore.liamcottle.net/privacy-policy.html) for data practices.

