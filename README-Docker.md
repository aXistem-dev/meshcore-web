# Docker Setup for MeshCore WebApp

Docker configuration to run the MeshCore webapp in a container using nginx on a lightweight Alpine Linux base image.

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Build and start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

The app will be available at http://localhost:8080

### Using Docker directly

```bash
# Build the image
docker build -t meshcore-web .

# Run the container
docker run -d -p 8080:80 --name meshcore-web meshcore-web

# View logs
docker logs -f meshcore-web

# Stop the container
docker stop meshcore-web
docker rm meshcore-web
```

## Configuration

### Change Port

To change the port, modify the `ports` section in `docker-compose.yml`:

```yaml
ports:
  - "3000:80"  # Change 8080 to your desired port
```

Or when using Docker directly:

```bash
docker run -d -p 3000:80 --name meshcore-web meshcore-web
```

## Production Considerations

For production deployment:

1. **HTTPS**: Add SSL/TLS certificates and configure nginx for HTTPS
2. **Reverse Proxy**: Consider using a reverse proxy (Traefik, Caddy, etc.)
3. **Resource Limits**: Add resource limits in docker-compose.yml

