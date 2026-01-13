# 🎮 Hytale Dedicated Server - Docker Image

[![Build](https://github.com/everhytale/dockers/actions/workflows/hytale-server.yml/badge.svg)](https://github.com/everhytale/dockers/actions/workflows/hytale-server.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/everhytale/hytale-server)](https://hub.docker.com/r/everhytale/hytale-server)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An optimized, production-ready Docker image for running Hytale dedicated servers.

## ⚠️ Disclaimer

This is an unofficial community project. Hytale is a trademark of Hypixel Studios.

## 📦 Image Tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest stable release |
| `X.Y.Z` | Specific version (e.g., `1.0.0`) |
| `X.Y` | Minor version (e.g., `1.0`) |
| `rc` | Latest release candidate |
| `X.Y.Z-rc.N` | Specific RC version (e.g., `1.0.0-rc.1`) |
| `dev` | Latest development build |
| `edge` | Latest build from main branch |

## ✨ Features

- 🏗️ **Multi-architecture support**: `linux/amd64` and `linux/arm64`
- ☕ **Java 25** (Eclipse Temurin)
- 🔐 **Token-based authentication** via OAuth2 Device Flow
- 📦 **Automated builds** via GitHub Actions
- 🔄 **Automatic token refresh** scripts included
- 🛡️ **Security-first**: runs as non-root user
- 📊 **Health checks** built-in

## 📋 Requirements

- Docker 20.10+ and Docker Compose v2
- Minimum **4GB RAM** (8GB recommended)
- Hytale account with server access
- UDP port **5520** available (Hytale uses QUIC protocol)

## 🚀 Quick Start

### Option 1: Use Pre-built Image

```bash
# Pull the image (from Docker Hub)
docker pull everhytale/hytale-server:latest

# Create data directory
mkdir -p ./data

# Run the server
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v ./data:/server \
  -v /etc/machine-id:/etc/machine-id:ro \
  -e MIN_MEMORY=4G \
  -e MAX_MEMORY=8G \
  everhytale/hytale-server:latest
```

### Option 2: Using Docker Compose

1. **Clone the repository**
   ```bash
   git clone https://github.com/everhytale/dockers.git
   cd dockers/dockers/hytale-server
   ```

2. **Authenticate with Hytale**
   ```bash
   chmod +x scripts/hytale-auth.sh
   ./scripts/hytale-auth.sh
   ```
   Follow the instructions to complete OAuth2 authentication.

3. **Start the server**
   ```bash
   docker-compose up -d
   ```

4. **View logs**
   ```bash
   docker-compose logs -f
   ```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MIN_MEMORY` | `4G` | Minimum JVM heap size |
| `MAX_MEMORY` | `8G` | Maximum JVM heap size |
| `SERVER_PORT` | `5520` | Server port (UDP) |
| `SERVER_BIND` | `0.0.0.0` | Bind address |
| `AUTH_MODE` | `authenticated` | Authentication mode (`authenticated` or `offline`) |
| `DISABLE_SENTRY` | `false` | Disable crash reporting (for development) |
| `USE_AOT_CACHE` | `true` | Use AOT cache for faster startup |
| `BACKUP_ENABLED` | `false` | Enable automatic backups |
| `BACKUP_FREQUENCY` | `30` | Backup interval in minutes |

### Token Authentication

| Variable | Description |
|----------|-------------|
| `OWNER_NAME` | Server owner username |
| `OWNER_UUID` | Server owner UUID |
| `SESSION_TOKEN` | Session token from OAuth2 |
| `IDENTITY_TOKEN` | Identity token (JWT) |

## 📁 Directory Structure

The image separates game files (read-only) from server data (persistent):

```
/opt/hytale-server/          # Game files (read-only, in image)
├── HytaleServer.jar         # Server executable
├── HytaleServer.aot         # AOT cache (faster startup)
└── Assets.zip               # Game assets

/server/                     # Server data (persistent, mounted volume)
├── universe/                # Worlds and player data
├── mods/                    # Installed mods
├── logs/                    # Server logs
├── .cache/                  # Optimized cache
├── auth.enc                 # Encrypted authentication credentials
├── config.json              # Server configuration
├── permissions.json         # Permissions
├── whitelist.json           # Whitelisted players
└── bans.json                # Banned players
```

**Key benefits:**
- Game files are immutable and versioned with the image
- All server data is in a single `/server` volume
- Easy to backup: just backup the `/server` directory
- Easy to migrate: copy the data folder to a new server

## 🔒 Authentication

Hytale servers require authentication to communicate with Hytale's service APIs. There are two methods:

### Method 1: Interactive Console Authentication (Recommended for Docker)

1. **Start the server and attach to console**:
   ```bash
   docker-compose up -d
   docker attach hytale-server
   ```

2. **Authenticate via device code**:
   ```
   /auth login device
   ```

   You'll see output like:
   ```
   ===================================================================
   DEVICE AUTHORIZATION
   ===================================================================
   Visit: https://accounts.hytale.com/device
   Enter code: ABCD-1234
   ===================================================================
   ```

3. **Complete authorization** in your browser, then wait for confirmation:
   ```
   Authentication successful! Use '/auth status' to view details.
   WARNING: Credentials stored in memory only - they will be lost on restart!
   ```

4. **Persist credentials** to survive container restarts:
   ```
   /auth persistence Encrypted
   ```

   Output:
   ```
   Swapped credential store to: EncryptedAuthCredentialStoreProvider
   ```

5. **Detach from container** (without stopping it):
   Press `Ctrl+P` then `Ctrl+Q`

### The `auth.enc` File

When you use `/auth persistence Encrypted`, Hytale creates an encrypted file `auth.enc` that stores your authentication credentials. This file:

- Is encrypted using your machine's hardware ID
- Persists across server restarts
- Must be mounted as a volume to survive container recreation

**Important**: To use encrypted persistence in Docker, you must:

1. Mount the machine-id from the host
2. Mount the auth.enc file

**Quick setup with local files** (recommended):

```bash
# Create data directory and empty auth.enc
mkdir -p ./data
touch ./data/auth.enc

# Use the local configuration
docker-compose -f docker-compose.local.yml up -d
```

Or add to your `docker-compose.yml`:

```yaml
volumes:
  - /etc/machine-id:/etc/machine-id:ro
  - /var/lib/dbus/machine-id:/var/lib/dbus/machine-id:ro
  - ./data/auth.enc:/server/auth.enc  # Persist auth credentials
```

### Persistence Types

| Type | Command | Description |
|------|---------|-------------|
| `Memory` | `/auth persistence Memory` | Credentials lost on restart (default) |
| `Encrypted` | `/auth persistence Encrypted` | Credentials saved to `auth.enc`, encrypted with machine-id |

### Method 2: Token Authentication via Environment Variables

Use the included scripts to obtain tokens programmatically:

```bash
# Initial authentication
./scripts/hytale-auth.sh

# Refresh expired tokens
./scripts/hytale-refresh.sh
docker-compose restart
```

This method sets environment variables (`SESSION_TOKEN`, `IDENTITY_TOKEN`) that are passed to the server at startup.

## 🏗️ Building from Source

### Prerequisites

You'll need Hytale credentials stored as a GitHub Secret or environment variable.

### Local Build

```bash
# Create credentials file (or use scripts/hytale-auth.sh)
echo '{"access_token":"...", "refresh_token":"..."}' > .hytale-downloader-credentials.json

# Build the image (credentials passed securely as secret)
docker build \
  --secret id=hytale_credentials,src=.hytale-downloader-credentials.json \
  -t hytale-server:local .
```

Or using Docker Compose:

```bash
docker compose -f docker-compose.build.yml build
```

### Multi-architecture Build

```bash
# Create credentials file (or use scripts/hytale-auth.sh)
echo '{"access_token":"...", "refresh_token":"..."}' > .hytale-downloader-credentials.json

# Create buildx builder
docker buildx create --name multiarch --use

# Build for multiple platforms (credentials passed securely as secret)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --secret id=hytale_credentials,src=.hytale-downloader-credentials.json \
  -t hytale-server:local \
  --push .
```

> **Security Note:** Credentials are mounted as a Docker secret and never appear in build logs or image layers.

## 🔄 GitHub Actions CI/CD

The repository includes a GitHub Actions workflow that:

1. Builds multi-architecture images (amd64, arm64)
2. Pushes to GitHub Container Registry (ghcr.io)
3. Optionally pushes to Docker Hub
4. Runs security scans with Trivy

### Required Secrets

| Secret | Description |
|--------|-------------|
| `HYTALE_CREDENTIALS` | **Required**. JSON credentials for the Hytale downloader |
| `DOCKERHUB_USERNAME` | Optional. Docker Hub username |
| `DOCKERHUB_TOKEN` | Optional. Docker Hub access token |

### Setting up Secrets

1. Go to your repository settings
2. Navigate to **Secrets and variables** → **Actions**
3. Add the required secrets

## 🌐 Network Configuration

Hytale uses the **QUIC protocol over UDP** (not TCP).

### Firewall Rules

```bash
# Linux (ufw)
sudo ufw allow 5520/udp

# Linux (iptables)
sudo iptables -A INPUT -p udp --dport 5520 -j ACCEPT

# Windows PowerShell
New-NetFirewallRule -DisplayName "Hytale Server" -Direction Inbound -Protocol UDP -LocalPort 5520 -Action Allow
```

### Port Forwarding

If behind a router, forward **UDP port 5520** to your server. TCP is not required.

## 🔧 Troubleshooting

### Machine-ID Error

If you see "Failed to get Hardware UUID":

```yaml
# docker-compose.yml
volumes:
  - /etc/machine-id:/etc/machine-id:ro
```

Or use memory-based persistence:
```
/auth persistence Memory
```

### Token Expired

Refresh tokens using the included script:
```bash
./scripts/hytale-refresh.sh
docker-compose restart
```

### Server Won't Start

1. Check logs: `docker-compose logs -f`
2. Verify Assets.zip exists
3. Ensure minimum 4GB RAM available

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting a PR.

## 📚 Resources

- [Hytale Official Documentation](https://hytale.com)
- [Hytale Server Manual](https://support.hytale.com/hc/en-us/articles/hytale-server-manual)
- [Eclipse Temurin (Java)](https://adoptium.net/)
- [Docker Documentation](https://docs.docker.com/)

## 🔗 Links

- **Docker Hub**: [everhytale/hytale-server](https://hub.docker.com/r/everhytale/hytale-server)
- **GitHub Repository**: [everhytale/dockers](https://github.com/everhytale/dockers)
- **Issues**: [GitHub Issues](https://github.com/everhytale/dockers/issues)

