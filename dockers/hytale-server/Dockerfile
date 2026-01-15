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
#
# Build:
#   Game files are provided via build-context from CI/CD pipeline.
#   For local builds, see docker-compose.build.yml
# =============================================================================

FROM eclipse-temurin:25-jre-noble

# =============================================================================
# Image Metadata
# =============================================================================
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
ARG HYTALE_VERSION

LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL hytale.version="${HYTALE_VERSION}"

# =============================================================================
# Create non-root user
# =============================================================================
# Fixed UID/GID for Kubernetes compatibility
# Ensures consistent permissions across pods and PVCs
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
# =============================================================================
# Game files are provided via build-context named "game" from CI/CD
# Using --chown in COPY to avoid extra layer and disk space

RUN mkdir -p ${HYTALE_HOME} /server \
    && chown hytale:hytale ${HYTALE_HOME} /server

# Copy server files from build-context (provided by CI/CD pipeline)
# The "game" context contains the extracted game files from hytale-downloader
COPY --from=game --chown=hytale:hytale /Server/ ${HYTALE_HOME}/
COPY --from=game --chown=hytale:hytale /Assets.zip ${HYTALE_HOME}/Assets.zip

# Copy entrypoint script
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

# =============================================================================
# Runtime Configuration
# =============================================================================

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
