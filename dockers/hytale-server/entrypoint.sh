#!/bin/bash
set -e

# =============================================================================
#                    Hytale Dedicated Server - EverHytale
#                    Protocol: QUIC/UDP (Port 5520)
# =============================================================================
# Directory structure:
#   /opt/hytale-server/  - Game files (read-only, from image)
#   /server/             - Server data (persistent, mounted volume)
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Game files location
HYTALE_HOME="${HYTALE_HOME:-/opt/hytale-server}"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║          🎮  Hytale Dedicated Server - EverHytale  🎮         ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# =============================================================================
# Configuration with defaults
# =============================================================================
MIN_MEMORY="${MIN_MEMORY:-4G}"
MAX_MEMORY="${MAX_MEMORY:-8G}"
SERVER_PORT="${SERVER_PORT:-5520}"
SERVER_BIND="${SERVER_BIND:-0.0.0.0}"
AUTH_MODE="${AUTH_MODE:-authenticated}"
DISABLE_SENTRY="${DISABLE_SENTRY:-false}"
USE_AOT_CACHE="${USE_AOT_CACHE:-true}"
BACKUP_ENABLED="${BACKUP_ENABLED:-false}"
BACKUP_DIR="${BACKUP_DIR:-/server/backups}"
BACKUP_FREQUENCY="${BACKUP_FREQUENCY:-30}"
BACKUP_MAX_COUNT="${BACKUP_MAX_COUNT:-5}"

# Token authentication (alternative to /auth login device)
OWNER_NAME="${OWNER_NAME:-}"
OWNER_UUID="${OWNER_UUID:-}"
SESSION_TOKEN="${SESSION_TOKEN:-}"
IDENTITY_TOKEN="${IDENTITY_TOKEN:-}"

# =============================================================================
# Display configuration
# =============================================================================
echo -e "${GREEN}${BOLD}Server Configuration:${NC}"
echo -e "  • Game Files      : ${YELLOW}${HYTALE_HOME}${NC}"
echo -e "  • Server Data     : ${YELLOW}/server${NC}"
echo -e "  • Memory          : ${YELLOW}${MIN_MEMORY} - ${MAX_MEMORY}${NC}"
echo -e "  • Bind Address    : ${YELLOW}${SERVER_BIND}:${SERVER_PORT}${NC}"
echo -e "  • Protocol        : ${YELLOW}QUIC/UDP${NC}"
echo -e "  • Auth Mode       : ${YELLOW}${AUTH_MODE}${NC}"
echo -e "  • AOT Cache       : ${YELLOW}${USE_AOT_CACHE}${NC}"
echo -e "  • Sentry Disabled : ${YELLOW}${DISABLE_SENTRY}${NC}"
echo -e "  • Auto Backup     : ${YELLOW}${BACKUP_ENABLED}${NC}"

# Display token authentication status
if [ -n "$SESSION_TOKEN" ] && [ -n "$IDENTITY_TOKEN" ]; then
    echo -e "  • Token Auth      : ${GREEN}Configured ✓${NC}"
    if [ -n "$OWNER_NAME" ]; then
        echo -e "  • Owner           : ${YELLOW}${OWNER_NAME}${NC}"
    fi
else
    echo -e "  • Token Auth      : ${YELLOW}Not configured (use /auth login device)${NC}"
fi
echo ""

# =============================================================================
# Validate required files in HYTALE_HOME
# =============================================================================
if [ ! -f "${HYTALE_HOME}/HytaleServer.jar" ]; then
    echo -e "${RED}Error: HytaleServer.jar not found in ${HYTALE_HOME}/${NC}"
    exit 1
fi

if [ ! -f "${HYTALE_HOME}/Assets.zip" ]; then
    echo -e "${RED}Error: Assets.zip not found in ${HYTALE_HOME}/${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Game files found in ${HYTALE_HOME}${NC}"

# =============================================================================
# Check machine-id for encrypted authentication
# =============================================================================
check_machine_id() {
    if [ ! -f "/etc/machine-id" ] || [ ! -s "/etc/machine-id" ]; then
        echo -e "${YELLOW}⚠ /etc/machine-id not found or empty${NC}"

        if [ -w "/etc" ]; then
            echo -e "${YELLOW}  Generating machine-id...${NC}"
            hostname | md5sum | cut -d' ' -f1 > /etc/machine-id 2>/dev/null || true
        fi

        if [ -f "/var/lib/dbus/machine-id" ] && [ -s "/var/lib/dbus/machine-id" ]; then
            echo -e "${GREEN}  ✓ Using /var/lib/dbus/machine-id${NC}"
        else
            echo -e "${YELLOW}  ⚠ No machine-id available!${NC}"
            echo -e "${YELLOW}    Encrypted authentication may not work.${NC}"
            echo -e "${YELLOW}    Solutions:${NC}"
            echo -e "${YELLOW}    1. Mount /etc/machine-id from host${NC}"
            echo -e "${YELLOW}    2. Use 'auth persistence Memory' instead of 'Encrypted'${NC}"
        fi
    else
        echo -e "${GREEN}✓ Machine-ID available for encrypted authentication${NC}"
    fi
}

check_machine_id
echo ""

# =============================================================================
# Display Java version
# =============================================================================
echo -e "${GREEN}${BOLD}Java Runtime:${NC}"
java -version 2>&1 | head -n 1
echo ""

# =============================================================================
# Build server arguments
# =============================================================================
# Assets path points to the game files location
SERVER_ARGS="--assets ${HYTALE_HOME}/Assets.zip"
SERVER_ARGS="${SERVER_ARGS} --bind ${SERVER_BIND}:${SERVER_PORT}"
SERVER_ARGS="${SERVER_ARGS} --auth-mode ${AUTH_MODE}"

# Conditional options
if [ "${DISABLE_SENTRY}" = "true" ]; then
    SERVER_ARGS="${SERVER_ARGS} --disable-sentry"
    echo -e "${YELLOW}⚠ Sentry disabled (development mode)${NC}"
fi

if [ "${BACKUP_ENABLED}" = "true" ]; then
    SERVER_ARGS="${SERVER_ARGS} --backup"
    SERVER_ARGS="${SERVER_ARGS} --backup-dir ${BACKUP_DIR}"
    SERVER_ARGS="${SERVER_ARGS} --backup-frequency ${BACKUP_FREQUENCY}"
    SERVER_ARGS="${SERVER_ARGS} --backup-max-count ${BACKUP_MAX_COUNT}"
    echo -e "${GREEN}✓ Auto backup enabled (every ${BACKUP_FREQUENCY} min, max ${BACKUP_MAX_COUNT} backups, dir: ${BACKUP_DIR})${NC}"
fi

# Token authentication arguments
if [ -n "$OWNER_NAME" ]; then
    SERVER_ARGS="${SERVER_ARGS} --owner-name ${OWNER_NAME}"
fi

if [ -n "$OWNER_UUID" ]; then
    SERVER_ARGS="${SERVER_ARGS} --owner-uuid ${OWNER_UUID}"
fi

if [ -n "$SESSION_TOKEN" ]; then
    SERVER_ARGS="${SERVER_ARGS} --session-token ${SESSION_TOKEN}"
    echo -e "${GREEN}✓ Session token configured${NC}"
fi

if [ -n "$IDENTITY_TOKEN" ]; then
    SERVER_ARGS="${SERVER_ARGS} --identity-token ${IDENTITY_TOKEN}"
    echo -e "${GREEN}✓ Identity token configured${NC}"
fi

# Add custom extra arguments if provided
if [ -n "$EXTRA_ARGS" ]; then
    SERVER_ARGS="${SERVER_ARGS} ${EXTRA_ARGS}"
    echo -e "${GREEN}✓ Extra arguments: ${EXTRA_ARGS}${NC}"
fi

# =============================================================================
# Build JVM arguments
# =============================================================================
JVM_ARGS="-Xms${MIN_MEMORY} -Xmx${MAX_MEMORY} ${JAVA_OPTS}"

# Enable AOT cache if available (JEP-514)
if [ "${USE_AOT_CACHE}" = "true" ] && [ -f "${HYTALE_HOME}/HytaleServer.aot" ]; then
    JVM_ARGS="-XX:AOTCache=${HYTALE_HOME}/HytaleServer.aot ${JVM_ARGS}"
    echo -e "${GREEN}✓ AOT cache enabled for faster startup${NC}"
fi

echo ""
echo -e "${GREEN}${BOLD}Server Arguments:${NC}"
echo -e "  ${SERVER_ARGS}"
echo ""

# =============================================================================
# Signal handlers for graceful shutdown
# =============================================================================
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutdown signal received, stopping server gracefully...${NC}"
    if [ -n "$PID" ]; then
        kill -TERM "$PID" 2>/dev/null
        wait "$PID" 2>/dev/null
    fi
    echo -e "${GREEN}Server stopped.${NC}"
    exit 0
}
trap cleanup SIGTERM SIGINT

# =============================================================================
# Start the server
# =============================================================================
echo -e "${GREEN}${BOLD}Starting Hytale Server...${NC}"
echo -e "${GREEN}${BOLD}Working directory: $(pwd)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -z "$SESSION_TOKEN" ] || [ -z "$IDENTITY_TOKEN" ]; then
    echo -e "${CYAN}Note: After first startup, authenticate the server with:${NC}"
    echo -e "${YELLOW}  /auth login device${NC}"
    echo -e "${YELLOW}  /auth persistence Encrypted${NC}"
    echo ""
fi

# Ensure we're in /server directory (persistent data)
cd /server

# Start the server from /server, using JAR from HYTALE_HOME
# All generated files (universe, logs, config, auth.enc) will be in /server
# shellcheck disable=SC2086
exec java ${JVM_ARGS} -jar ${HYTALE_HOME}/HytaleServer.jar ${SERVER_ARGS} "$@"
