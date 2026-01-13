# =============================================================================
# Hytale Dedicated Server - Docker Image
# Repository: https://github.com/everhytale/dockers
# Image: everhytale/hytale-server (Docker Hub)
# =============================================================================
# Multi-architecture support: amd64, arm64
# Protocol: QUIC/UDP on port 5520
#
# Directory structure:
#   /opt/hytale-server/  - Game files (read-only, from image)
#   /server/             - Server data (persistent, mounted volume)
# =============================================================================

# -----------------------------------------------------------------------------
# STAGE 1: Download Hytale Server Files (AMD64 only - downloader limitation)
# -----------------------------------------------------------------------------
FROM --platform=linux/amd64 debian:bookworm-slim AS downloader

LABEL stage="downloader"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR /download

# Download the Hytale downloader CLI
RUN curl -fsSL https://downloader.hytale.com/hytale-downloader.zip -o hytale-downloader.zip \
    && unzip -q hytale-downloader.zip -d hytale-downloader \
    && rm hytale-downloader.zip

WORKDIR /download/hytale-downloader

# Download game files using mounted secret (credentials never appear in logs/layers)
# The secret is mounted temporarily, copied to a writable location, used, then deleted
RUN --mount=type=secret,id=hytale_credentials,required=true \
    cp /run/secrets/hytale_credentials .hytale-downloader-credentials.json \
    && chmod +x ./hytale-downloader-linux-amd64 \
    && ./hytale-downloader-linux-amd64 -download-path /download/game.zip \
    && rm -f .hytale-downloader-credentials.json \
    && mkdir -p /game \
    && unzip -q /download/game.zip -d /game \
    && rm /download/game.zip

# -----------------------------------------------------------------------------
# STAGE 2: Hytale Server Runtime (Multi-architecture: amd64, arm64)
# -----------------------------------------------------------------------------
FROM eclipse-temurin:25-jre-noble AS runtime

# Image metadata
LABEL org.opencontainers.image.title="Hytale Dedicated Server"
LABEL org.opencontainers.image.description="Hytale dedicated server with Java 25"
LABEL org.opencontainers.image.vendor="EverHytale"
LABEL org.opencontainers.image.url="https://github.com/everhytale/dockers"
LABEL org.opencontainers.image.source="https://github.com/everhytale/dockers"
LABEL org.opencontainers.image.documentation="https://github.com/everhytale/dockers/tree/main/dockers/hytale-server"
LABEL org.opencontainers.image.licenses="MIT"

# Build arguments for versioning
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.version="${VERSION}"

# Create non-root user with fixed UID/GID for Kubernetes compatibility
# Fixed IDs ensure consistent permissions across pods and PVCs
ARG HYTALE_UID=1001
ARG HYTALE_GID=1001

RUN groupadd -r -g ${HYTALE_GID} hytale \
    && useradd -r -u ${HYTALE_UID} -g hytale -m -d /server hytale

# =============================================================================
# Environment Variables
# =============================================================================

# Game files location (read-only)
ENV HYTALE_HOME="/opt/hytale-server"

# JVM Flags - Recommended settings for Java 25 server applications
# Users can override JAVA_OPTS via environment variable if needed
ENV JAVA_OPTS="\
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:+DisableExplicitGC \
    -XX:+AlwaysPreTouch \
    -XX:+UseStringDeduplication \
    -XX:+OptimizeStringConcat \
    -Dfile.encoding=UTF-8"

# Memory Configuration (minimum 4GB recommended by Hytale)
ENV MIN_MEMORY="4G"
ENV MAX_MEMORY="8G"

# Network Configuration (Hytale uses QUIC/UDP protocol)
ENV SERVER_PORT="5520"
ENV SERVER_BIND="0.0.0.0"

# Server Configuration
ENV AUTH_MODE="authenticated"
ENV DISABLE_SENTRY="false"
ENV USE_AOT_CACHE="true"

# Backup Configuration
ENV BACKUP_ENABLED="false"
ENV BACKUP_FREQUENCY="30"

# Token Authentication (alternative to /auth login device)
# Obtained via OAuth2 Device Flow - see hytale-auth.sh
ENV OWNER_NAME=""
ENV OWNER_UUID=""
ENV SESSION_TOKEN=""
ENV IDENTITY_TOKEN=""

# Custom server arguments (appended to server command)
# Example: EXTRA_ARGS="--allow-op --accept-early-plugins"
ENV EXTRA_ARGS=""

# =============================================================================
# Install game files to /opt/hytale-server
# Using --chown in COPY to avoid extra layer and disk space
# =============================================================================
RUN mkdir -p ${HYTALE_HOME} /server \
    && chown hytale:hytale ${HYTALE_HOME} /server

# Copy server files with correct ownership (no extra chown layer needed)
COPY --from=downloader --chown=hytale:hytale /game/Server/ ${HYTALE_HOME}/
COPY --from=downloader --chown=hytale:hytale /game/Assets.zip ${HYTALE_HOME}/Assets.zip

# Copy entrypoint script
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

# Working directory is /server (mounted volume for persistent data)
WORKDIR /server

# Switch to non-root user
USER hytale

# Expose Hytale server port (QUIC uses UDP only)
EXPOSE 5520/udp

# Single volume mount point for all server data
VOLUME ["/server"]

# Start the server
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
