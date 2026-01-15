#!/bin/bash
# =============================================================================
# Hytale Game Files Downloader
# =============================================================================
# Downloads Hytale server files for local Docker builds.
#
# Prerequisites:
#   - Create credentials file first:
#     echo '{"access_token":"...", "refresh_token":"..."}' > .hytale-downloader-credentials.json
#
# Usage:
#   ./scripts/download-game.sh
#
# This script will:
#   1. Download the Hytale downloader
#   2. Download game files using your credentials
#   3. Extract them to ./game-files/
#   4. Export HYTALE_VERSION for docker-compose
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
GAME_FILES_DIR="$PROJECT_DIR/game-files"
DOWNLOADER_DIR="$PROJECT_DIR/.hytale-downloader"
CREDENTIALS_FILE="$PROJECT_DIR/.hytale-downloader-credentials.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          Hytale Game Files Downloader                         ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check credentials
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo -e "${RED}Error: Credentials file not found!${NC}"
    echo ""
    echo "Please create the credentials file first:"
    echo "  echo '{\"access_token\":\"...\", \"refresh_token\":\"...\"}' > .hytale-downloader-credentials.json"
    echo ""
    echo "Or use the hytale-auth.sh script to authenticate:"
    echo "  ./scripts/hytale-auth.sh"
    exit 1
fi

echo -e "${GREEN}✓ Credentials file found${NC}"

# Download the Hytale downloader if not present
if [ ! -f "$DOWNLOADER_DIR/hytale-downloader-linux-amd64" ]; then
    echo -e "${YELLOW}Downloading Hytale downloader...${NC}"
    mkdir -p "$DOWNLOADER_DIR"
    curl -fsSL https://downloader.hytale.com/hytale-downloader.zip -o "$DOWNLOADER_DIR/hytale-downloader.zip"
    unzip -q "$DOWNLOADER_DIR/hytale-downloader.zip" -d "$DOWNLOADER_DIR"
    rm "$DOWNLOADER_DIR/hytale-downloader.zip"
    chmod +x "$DOWNLOADER_DIR/hytale-downloader-linux-amd64"
    echo -e "${GREEN}✓ Hytale downloader ready${NC}"
else
    echo -e "${GREEN}✓ Hytale downloader already present${NC}"
fi

# Get current version
echo -e "${YELLOW}Checking Hytale version...${NC}"
HYTALE_VERSION=$("$DOWNLOADER_DIR/hytale-downloader-linux-amd64" -print-version)
echo -e "${GREEN}✓ Hytale version: ${CYAN}$HYTALE_VERSION${NC}"

# Check if we need to download
if [ -d "$GAME_FILES_DIR" ] && [ -f "$GAME_FILES_DIR/.version" ]; then
    CURRENT_VERSION=$(cat "$GAME_FILES_DIR/.version")
    if [ "$CURRENT_VERSION" == "$HYTALE_VERSION" ]; then
        echo -e "${GREEN}✓ Game files are up to date${NC}"
        echo ""
        echo -e "HYTALE_VERSION=${CYAN}$HYTALE_VERSION${NC}"
        echo ""
        echo "To force re-download, delete the game-files directory:"
        echo "  rm -rf game-files"
        exit 0
    else
        echo -e "${YELLOW}New version available: $CURRENT_VERSION → $HYTALE_VERSION${NC}"
        rm -rf "$GAME_FILES_DIR"
    fi
fi

# Download game files
echo -e "${YELLOW}Downloading game files...${NC}"
cd "$DOWNLOADER_DIR"
cp "$CREDENTIALS_FILE" .hytale-downloader-credentials.json
./hytale-downloader-linux-amd64 -download-path "$PROJECT_DIR/game.zip"
rm -f .hytale-downloader-credentials.json
cd "$PROJECT_DIR"

# Extract game files
echo -e "${YELLOW}Extracting game files...${NC}"
mkdir -p "$GAME_FILES_DIR"
unzip -q game.zip -d "$GAME_FILES_DIR"
rm game.zip

# Save version
echo "$HYTALE_VERSION" > "$GAME_FILES_DIR/.version"

echo -e "${GREEN}✓ Game files downloaded and extracted${NC}"
echo ""
echo -e "HYTALE_VERSION=${CYAN}$HYTALE_VERSION${NC}"
echo ""
echo "You can now build the Docker image:"
echo "  HYTALE_VERSION=$HYTALE_VERSION docker compose -f docker-compose.build.yml build"
echo ""
echo "Or run directly:"
echo "  HYTALE_VERSION=$HYTALE_VERSION docker compose -f docker-compose.build.yml up -d"
