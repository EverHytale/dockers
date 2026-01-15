# 🐳 EverHytale Docker Images

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Official Docker images for EverHytale projects.

## 📦 Available Images

| Image | Description | Docker Hub |
|-------|-------------|------------|
| [hytale-server](./dockers/hytale-server) | Optimized Hytale dedicated server | [![Docker Pulls](https://img.shields.io/docker/pulls/everhytale/hytale-server)](https://hub.docker.com/r/everhytale/hytale-server) |

## 🏷️ Tag Strategy

All images use SemVer with Hytale version as build metadata:

| Tag | Description | Example |
|-----|-------------|---------|
| `latest` | Latest stable release | `everhytale/hytale-server:latest` |
| `X.Y.Z+HYTALE_VERSION` | Full version (image + Hytale) | `everhytale/hytale-server:1.0.0+2026.01.15-c04fdfe10` |
| `HYTALE_VERSION` | Latest image for this Hytale version | `everhytale/hytale-server:2026.01.15-c04fdfe10` |
| `X.Y` | Minor version (latest patch) | `everhytale/hytale-server:1.0` |
| `X` | Major version (latest minor) | `everhytale/hytale-server:1` |
| `rc` | Latest release candidate | `everhytale/hytale-server:rc` |
| `dev` | Latest development build | `everhytale/hytale-server:dev` |
| `edge` | Latest build from main branch | `everhytale/hytale-server:edge` |

### Automated Builds

The CI/CD pipeline automatically checks for new Hytale versions every 12 hours. When a new version is detected, a new Docker image is built and pushed with the appropriate tags.

## 🚀 Quick Start

### Hytale Server

```bash
# Latest stable release
docker pull everhytale/hytale-server:latest

# Specific Hytale version (latest image)
docker pull everhytale/hytale-server:2026.01.15-c04fdfe10

# Specific image + Hytale version
docker pull everhytale/hytale-server:1.0.0+2026.01.15-c04fdfe10

# Run the server
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/server \
  everhytale/hytale-server:latest
```

See [hytale-server documentation](./dockers/hytale-server/README.md) for detailed usage.

## 🏗️ Repository Structure

```
dockers/
├── .github/
│   └── workflows/
│       └── hytale-server.yml    # CI/CD for hytale-server
├── dockers/
│   └── hytale-server/           # Hytale server Docker image
│       ├── Dockerfile
│       ├── docker-compose.yml
│       ├── docker-compose.build.yml
│       ├── entrypoint.sh
│       ├── scripts/
│       │   ├── download-game.sh
│       │   ├── hytale-auth.sh
│       │   └── hytale-refresh.sh
│       └── README.md
├── LICENSE
└── README.md
```

## 🔧 Building Locally

Each image can be built locally. Game files must be downloaded first using the provided script.

### Example: Hytale Server

```bash
cd dockers/hytale-server

# 1. Create credentials file (see hytale-auth.sh for OAuth flow)
echo '{"access_token":"...", "refresh_token":"..."}' > .hytale-downloader-credentials.json

# 2. Download game files
./scripts/download-game.sh

# 3. Build the image
HYTALE_VERSION=$(cat game-files/.version) docker compose -f docker-compose.build.yml build

# 4. Run the server
docker compose -f docker-compose.build.yml up -d
```

## 🤝 Contributing

Contributions are welcome! Please read the [Contributing Guidelines](./CONTRIBUTING.md) before submitting a PR.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **GitHub**: [everhytale/dockers](https://github.com/everhytale/dockers)
- **Docker Hub**: [everhytale](https://hub.docker.com/u/everhytale)

---

Made with ❤️ by the EverHytale community
