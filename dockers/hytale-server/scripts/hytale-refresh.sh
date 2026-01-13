#!/bin/bash
# =============================================================================
#                    Hytale Token Refresh Script
#          Renews expired tokens using the refresh_token
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
CLIENT_ID="hytale-server"
OAUTH_URL="https://oauth.accounts.hytale.com"
SESSIONS_URL="https://sessions.hytale.com"
CREDENTIALS_FILE="${1:-.hytale-credentials.json}"
ENV_FILE=".env"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║          🔄  Hytale Token Refresh  🔄                         ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check dependencies
check_dependencies() {
    for cmd in curl jq; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}Error: '$cmd' is not installed.${NC}"
            exit 1
        fi
    done
}

# Load existing credentials
load_credentials() {
    echo -e "${GREEN}${BOLD}Loading credentials...${NC}"

    # Try loading from JSON file first
    if [ -f "$CREDENTIALS_FILE" ]; then
        REFRESH_TOKEN=$(jq -r '.oauth.refresh_token' "$CREDENTIALS_FILE")
        PROFILE_UUID=$(jq -r '.profile.uuid' "$CREDENTIALS_FILE")
        PROFILE_USERNAME=$(jq -r '.profile.username' "$CREDENTIALS_FILE")
        OWNER=$(jq -r '.owner' "$CREDENTIALS_FILE")
        echo -e "  ${GREEN}✓ Loaded from ${CREDENTIALS_FILE}${NC}"
    # Otherwise try .env
    elif [ -f "$ENV_FILE" ]; then
        # shellcheck disable=SC1090
        source "$ENV_FILE"
        PROFILE_UUID="$OWNER_UUID"
        PROFILE_USERNAME="$OWNER_NAME"
        echo -e "  ${GREEN}✓ Loaded from ${ENV_FILE}${NC}"
    else
        echo -e "${RED}Error: No credentials file found.${NC}"
        echo -e "Run first: ${YELLOW}./scripts/hytale-auth.sh${NC}"
        exit 1
    fi

    if [ -z "$REFRESH_TOKEN" ] || [ "$REFRESH_TOKEN" = "null" ]; then
        echo -e "${RED}Error: refresh_token not found.${NC}"
        echo -e "Run: ${YELLOW}./scripts/hytale-auth.sh${NC} to get new tokens."
        exit 1
    fi

    echo -e "  Profile: ${CYAN}${PROFILE_USERNAME}${NC} (${PROFILE_UUID})"
}

# Refresh access token
refresh_access_token() {
    echo ""
    echo -e "${GREEN}${BOLD}Refreshing access token...${NC}"

    TOKEN_RESPONSE=$(curl -s -X POST "${OAUTH_URL}/oauth2/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=${CLIENT_ID}" \
        -d "grant_type=refresh_token" \
        -d "refresh_token=${REFRESH_TOKEN}")

    ERROR=$(echo "$TOKEN_RESPONSE" | jq -r '.error // empty')

    if [ -n "$ERROR" ]; then
        echo -e "${RED}Error during refresh: ${ERROR}${NC}"
        ERROR_DESC=$(echo "$TOKEN_RESPONSE" | jq -r '.error_description // empty')
        if [ -n "$ERROR_DESC" ]; then
            echo -e "${RED}${ERROR_DESC}${NC}"
        fi
        echo -e "${YELLOW}The refresh_token may have expired. Run: ./scripts/hytale-auth.sh${NC}"
        exit 1
    fi

    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')
    NEW_REFRESH_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.refresh_token // empty')
    TOKEN_EXPIRES_IN=$(echo "$TOKEN_RESPONSE" | jq -r '.expires_in')

    # Update refresh_token if a new one was issued
    if [ -n "$NEW_REFRESH_TOKEN" ] && [ "$NEW_REFRESH_TOKEN" != "null" ]; then
        REFRESH_TOKEN="$NEW_REFRESH_TOKEN"
        echo -e "  ${GREEN}✓ New refresh_token received${NC}"
    fi

    echo -e "  ${GREEN}✓ Access token renewed (expires in ${TOKEN_EXPIRES_IN}s)${NC}"
}

# Create new game session
create_game_session() {
    echo ""
    echo -e "${GREEN}${BOLD}Creating new game session...${NC}"

    SESSION_RESPONSE=$(curl -s -X POST "${SESSIONS_URL}/game-session/new" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"uuid\": \"${PROFILE_UUID}\"}")

    SESSION_TOKEN=$(echo "$SESSION_RESPONSE" | jq -r '.sessionToken')
    IDENTITY_TOKEN=$(echo "$SESSION_RESPONSE" | jq -r '.identityToken')
    SESSION_EXPIRES_AT=$(echo "$SESSION_RESPONSE" | jq -r '.expiresAt')

    if [ "$SESSION_TOKEN" = "null" ] || [ -z "$SESSION_TOKEN" ]; then
        echo -e "${RED}Error creating session:${NC}"
        echo "$SESSION_RESPONSE" | jq .
        exit 1
    fi

    echo -e "  ${GREEN}✓ Session created!${NC}"
    echo -e "  Expires: ${YELLOW}${SESSION_EXPIRES_AT}${NC}"
}

# Save new credentials
save_credentials() {
    echo ""
    echo -e "${GREEN}${BOLD}Saving new credentials...${NC}"

    # Update JSON file
    cat > "$CREDENTIALS_FILE" << EOF
{
    "owner": "${OWNER}",
    "profile": {
        "uuid": "${PROFILE_UUID}",
        "username": "${PROFILE_USERNAME}"
    },
    "oauth": {
        "access_token": "${ACCESS_TOKEN}",
        "refresh_token": "${REFRESH_TOKEN}",
        "expires_in": ${TOKEN_EXPIRES_IN}
    },
    "session": {
        "sessionToken": "${SESSION_TOKEN}",
        "identityToken": "${IDENTITY_TOKEN}",
        "expiresAt": "${SESSION_EXPIRES_AT}"
    },
    "refreshed_at": "$(date -Iseconds)"
}
EOF

    chmod 600 "$CREDENTIALS_FILE"
    echo -e "  ${GREEN}✓ ${CREDENTIALS_FILE}${NC}"

    # Update .env file
    if [ -f "$ENV_FILE" ]; then
        # Backup
        cp "$ENV_FILE" "${ENV_FILE}.bak"

        # Update tokens in .env
        sed -i "s|^SESSION_TOKEN=.*|SESSION_TOKEN=${SESSION_TOKEN}|" "$ENV_FILE"
        sed -i "s|^IDENTITY_TOKEN=.*|IDENTITY_TOKEN=${IDENTITY_TOKEN}|" "$ENV_FILE"
        sed -i "s|^ACCESS_TOKEN=.*|ACCESS_TOKEN=${ACCESS_TOKEN}|" "$ENV_FILE"
        sed -i "s|^REFRESH_TOKEN=.*|REFRESH_TOKEN=${REFRESH_TOKEN}|" "$ENV_FILE"

        echo -e "  ${GREEN}✓ ${ENV_FILE} updated${NC}"
    fi
}

# Show summary
show_summary() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}        ✓ TOKENS RENEWED!${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}Profile:${NC}       ${PROFILE_USERNAME}"
    echo -e "  ${BOLD}Session exp:${NC}   ${SESSION_EXPIRES_AT}"
    echo ""
    echo -e "${YELLOW}Restart the server to apply new tokens:${NC}"
    echo -e "  ${CYAN}docker-compose restart${NC}"
    echo ""
}

# Main
main() {
    check_dependencies
    load_credentials
    refresh_access_token
    create_game_session
    save_credentials
    show_summary
}

main "$@"
