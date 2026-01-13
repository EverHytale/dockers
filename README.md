# 🐳 EverHytale Docker Images

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Official Docker images for EverHytale projects.

## 📦 Available Images

| Image | Description | Docker Hub |
|-------|-------------|------------|
| [hytale-server](./dockers/hytale-server) | Optimized Hytale dedicated server | [![Docker Pulls](https://img.shields.io/docker/pulls/everhytale/hytale-server)](https://hub.docker.com/r/everhytale/hytale-server) |

## 🏷️ Tag Strategy

All images follow the same tagging convention:

| Tag | Description | Example |
|-----|-------------|---------|
| `latest` | Latest stable release | `everhytale/hytale-server:latest` |
| `X.Y.Z` | Specific version | `everhytale/hytale-server:1.0.0` |
| `X.Y` | Minor version (latest patch) | `everhytale/hytale-server:1.0` |
| `X` | Major version (latest minor) | `everhytale/hytale-server:1` |
| `rc` | Latest release candidate | `everhytale/hytale-server:rc` |
| `X.Y.Z-rc.N` | Specific RC version | `everhytale/hytale-server:1.0.0-rc.1` |
| `dev` | Latest development build | `everhytale/hytale-server:dev` |
| `edge` | Latest build from main branch | `everhytale/hytale-server:edge` |

## 🚀 Quick Start

### Hytale Server

```bash
docker pull everhytale/hytale-server:latest

docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v hytale-data:/server/universe \
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
│       ├── entrypoint.sh
│       ├── scripts/
│       └── README.md
├── LICENSE
└── README.md
```

## 🔧 Building Locally

Each image can be built locally. See the individual image documentation for build instructions.

### Example: Hytale Server

```bash
cd dockers/hytale-server
docker build --build-arg HYTALE_CREDENTIALS="..." -t hytale-server:local .
```

## 🤝 Contributing

Contributions are welcome! Please read the [Contributing Guidelines](./dockers/hytale-server/CONTRIBUTING.md) before submitting a PR.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **GitHub**: [everhytale/dockers](https://github.com/everhytale/dockers)
- **Docker Hub**: [everhytale](https://hub.docker.com/u/everhytale)

---

Made with ❤️ by the EverHytale community
