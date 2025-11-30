# MeshCore Web App

The MeshCore Companion App - a web-based interface for connecting to and managing MeshCore Companion Radio devices.

## About

This is the web version of the MeshCore Companion App, built with Flutter. It allows you to connect to MeshCore devices via Bluetooth Low Energy (BLE) or USB Serial directly from your web browser, enabling you to send messages, manage contacts, and interact with your MeshCore mesh network.

## Version

Current version: **v1.34.0** (build 58)

## Original Files

Original app files are available at [https://files.liamcottle.net/MeshCore](https://files.liamcottle.net/MeshCore), including:
- **Web builds** (this repository)
- **macOS builds**
- **Android builds**
- **Windows builds**

**Latest web version (v1.34.0)**: [MeshCore-v1.34.0+58-8ff274c-web.zip](https://files.liamcottle.net/MeshCore/v1.34.0/MeshCore-v1.34.0+58-8ff274c-web.zip)

## Features

- Connect to MeshCore Companion devices via BLE or USB Serial
- Send and receive messages on the mesh network
- Manage contacts and channels
- View network topology and node information
- Real-time mesh network interaction

## Browser Requirements

- Modern browser with Web Bluetooth API support (Chrome/Edge on desktop, Android Chrome)
- Web Serial API support (Chrome/Edge) for USB connections
- HTTPS or localhost (required for Web Bluetooth/Serial APIs)

## Docker Deployment

Docker configuration to run the MeshCore webapp in a container using nginx on a lightweight Alpine Linux base image.

Pre-built Docker images are available from GitHub Container Registry: `ghcr.io/axistem-dev/meshcore-web:latest`

### Quick Start

#### Using Docker Compose (Recommended)

```bash
# Start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

The app will be available at http://localhost:8080

#### Using Docker directly

```bash
# Run the container using the pre-built image
docker run -d -p 8080:80 --name meshcore-web ghcr.io/axistem-dev/meshcore-web:latest

# View logs
docker logs -f meshcore-web

# Stop the container
docker stop meshcore-web
docker rm meshcore-web
```

### Configuration

#### Change Port

To change the port, modify the `ports` section in `docker-compose.yml`:

```yaml
ports:
  - "3000:80"  # Change 8080 to your desired port
```

Or when using Docker directly:

```bash
docker run -d -p 3000:80 --name meshcore-web ghcr.io/axistem-dev/meshcore-web:latest
```

### Production Considerations

For production deployment:

1. **HTTPS**: Add SSL/TLS certificates and configure nginx for HTTPS
2. **Reverse Proxy**: Consider using a reverse proxy (Traefik, Caddy, etc.)
3. **Resource Limits**: Add resource limits in docker-compose.yml

## License

See the original MeshCore project for license information.

