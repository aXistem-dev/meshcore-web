# MeshCore Web App

The MeshCore Companion App - a web-based interface for connecting to and managing MeshCore Companion LoRa devices.

### Version

Current version: [**v1.34.0**](https://files.liamcottle.net/MeshCore/v1.34.0/MeshCore-v1.34.0+58-8ff274c-web.zip) ([build 58](./version.json))

## About

This is the web version of the MeshCore Companion App, built with Flutter. It allows you to connect to MeshCore devices via Bluetooth Low Energy (BLE) or USB Serial directly from your web browser, enabling you to send messages, manage contacts, and interact with the MeshCore mesh network.

## Features

- Connect to MeshCore Companion devices via BLE or USB Serial
- Send and receive messages on the mesh network
- Manage contacts, channels and remote repeaters
- View network topology and node information
- Real-time mesh network interaction

## Original Files

Original app files are available at [https://files.liamcottle.net/MeshCore](https://files.liamcottle.net/MeshCore), including:
- **Web builds** (this repository)
- **macOS builds**
- **Android builds**
- **Windows builds**

## Updating from Source

Run `./update-from-source.sh` to automatically check for new versions, download the latest web build, and update the repository.

## Browser Requirements

Chrome/Edge (desktop or Android) via HTTPS or localhost access required for functionality.

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

