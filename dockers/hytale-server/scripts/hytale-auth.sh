#!/bin/bash
# =============================================================================
#                    Hytale Server Authentication Script
#                    OAuth2 Device Code Flow (RFC 8628)
# =============================================================================
# This script authenticates with Hytale's OAuth2 server and retrieves
# the necessary tokens to run a dedicated server.
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
ACCOUNTS_URL="https://account-data.hytale.com"
SESSIONS_URL="https://sessions.hytale.com"
OUTPUT_FILE="${1:-.hytale-credentials.json}"
ENV_FILE=".env"

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║          🔐  Hytale Server Authentication  🔐                 ║"
echo "║              Device Code Flow (RFC 8628)                      ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check dependencies
check_dependencies() {
    for cmd in curl jq; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}Error: '$cmd' is not installed.${NC}"
            echo "Install it with: sudo apt install $cmd"
            exit 1
        fi
    done
}

# Step 1: Request device code
request_device_code() {
    echo -e "${GREEN}${BOLD}Step 1: Requesting device code...${NC}"

    DEVICE_RESPONSE=$(curl -s -X POST "${OAUTH_URL}/oauth2/device/auth" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=${CLIENT_ID}" \
        -d "scope=openid offline auth:server")

    # Extract values
    DEVICE_CODE=$(echo "$DEVICE_RESPONSE" | jq -r '.device_code')
    USER_CODE=$(echo "$DEVICE_RESPONSE" | jq -r '.user_code')
    VERIFICATION_URI=$(echo "$DEVICE_RESPONSE" | jq -r '.verification_uri')
    VERIFICATION_URI_COMPLETE=$(echo "$DEVICE_RESPONSE" | jq -r '.verification_uri_complete')
    EXPIRES_IN=$(echo "$DEVICE_RESPONSE" | jq -r '.expires_in')
    INTERVAL=$(echo "$DEVICE_RESPONSE" | jq -r '.interval')

    if [ "$DEVICE_CODE" = "null" ] || [ -z "$DEVICE_CODE" ]; then
        echo -e "${RED}Error requesting device code:${NC}"
        echo "$DEVICE_RESPONSE" | jq .
        exit 1
    fi

    # Step 2: Display instructions
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}        AUTHORIZATION REQUIRED${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  1. Open this URL in your browser:"
    echo ""
    echo -e "     ${YELLOW}${BOLD}${VERIFICATION_URI}${NC}"
    echo ""
    echo -e "  2. Enter this code:"
    echo ""
    echo -e "     ${GREEN}${BOLD}    ${USER_CODE}    ${NC}"
    echo ""
    echo -e "  Or use the direct link:"
    echo -e "     ${CYAN}${VERIFICATION_URI_COMPLETE}${NC}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${YELLOW}Code expires in ${EXPIRES_IN} seconds.${NC}"
    echo ""
}

# Step 3: Poll for token
poll_for_token() {
    echo -e "${GREEN}${BOLD}Step 2: Waiting for authorization...${NC}"
    echo -e "  (Checking every ${INTERVAL} seconds)"
    echo ""

    local attempts=0
    local max_attempts=$((EXPIRES_IN / INTERVAL))

    while [ $attempts -lt $max_attempts ]; do
        TOKEN_RESPONSE=$(curl -s -X POST "${OAUTH_URL}/oauth2/token" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "client_id=${CLIENT_ID}" \
            -d "grant_type=urn:ietf:params:oauth:grant-type:device_code" \
            -d "device_code=${DEVICE_CODE}")

        ERROR=$(echo "$TOKEN_RESPONSE" | jq -r '.error // empty')

        if [ -z "$ERROR" ]; then
            # Success!
            ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')
            REFRESH_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.refresh_token')
            TOKEN_EXPIRES_IN=$(echo "$TOKEN_RESPONSE" | jq -r '.expires_in')

            echo -e "\r${GREEN}✓ Authorization received!${NC}                    "
            return 0
        elif [ "$ERROR" = "authorization_pending" ]; then
            printf "\r  ⏳ Waiting... (%d/%d)" $((attempts + 1)) $max_attempts
        elif [ "$ERROR" = "slow_down" ]; then
            INTERVAL=$((INTERVAL + 5))
            printf "\r  ⏳ Slowing down, interval: %ds" $INTERVAL
        elif [ "$ERROR" = "expired_token" ]; then
            echo -e "\r${RED}✗ Code expired. Please run the script again.${NC}"
            exit 1
        elif [ "$ERROR" = "access_denied" ]; then
            echo -e "\r${RED}✗ Access denied by user.${NC}"
            exit 1
        else
            echo -e "\r${RED}✗ Error: $ERROR${NC}"
            echo "$TOKEN_RESPONSE" | jq .
            exit 1
        fi

        sleep "$INTERVAL"
        attempts=$((attempts + 1))
    done

    echo -e "\r${RED}✗ Timeout exceeded.${NC}"
    exit 1
}

# Step 4: Get profiles
get_profiles() {
    echo ""
    echo -e "${GREEN}${BOLD}Step 3: Retrieving profiles...${NC}"

    PROFILES_RESPONSE=$(curl -s -X GET "${ACCOUNTS_URL}/my-account/get-profiles" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}")

    OWNER=$(echo "$PROFILES_RESPONSE" | jq -r '.owner')
    PROFILES=$(echo "$PROFILES_RESPONSE" | jq -r '.profiles')
    PROFILE_COUNT=$(echo "$PROFILES" | jq -r 'length')

    if [ "$PROFILE_COUNT" -eq 0 ]; then
        echo -e "${RED}No profiles found.${NC}"
        exit 1
    fi

    echo -e "  Owner: ${CYAN}${OWNER}${NC}"
    echo -e "  Available profiles:"
    echo ""

    for i in $(seq 0 $((PROFILE_COUNT - 1))); do
        UUID=$(echo "$PROFILES" | jq -r ".[$i].uuid")
        USERNAME=$(echo "$PROFILES" | jq -r ".[$i].username")
        echo -e "    [$i] ${BOLD}${USERNAME}${NC} (${UUID})"
    done

    echo ""

    # Select profile
    if [ "$PROFILE_COUNT" -eq 1 ]; then
        SELECTED_PROFILE=0
        echo -e "  ${YELLOW}Automatically selecting the only available profile.${NC}"
    else
        read -p "  Select a profile [0-$((PROFILE_COUNT - 1))]: " SELECTED_PROFILE
        if ! [[ "$SELECTED_PROFILE" =~ ^[0-9]+$ ]] || [ "$SELECTED_PROFILE" -ge "$PROFILE_COUNT" ]; then
            echo -e "${RED}Invalid selection.${NC}"
            exit 1
        fi
    fi

    PROFILE_UUID=$(echo "$PROFILES" | jq -r ".[$SELECTED_PROFILE].uuid")
    PROFILE_USERNAME=$(echo "$PROFILES" | jq -r ".[$SELECTED_PROFILE].username")

    echo ""
    echo -e "  ${GREEN}✓ Selected profile: ${BOLD}${PROFILE_USERNAME}${NC}"
}

# Step 5: Create game session
create_game_session() {
    echo ""
    echo -e "${GREEN}${BOLD}Step 4: Creating game session...${NC}"

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

# Save credentials
save_credentials() {
    echo ""
    echo -e "${GREEN}${BOLD}Step 5: Saving credentials...${NC}"

    # Create JSON file (for reference and future refresh)
    cat > "$OUTPUT_FILE" << EOF
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
    "created_at": "$(date -Iseconds)"
}
EOF

    chmod 600 "$OUTPUT_FILE"
    echo -e "  ${GREEN}✓ JSON credentials: ${BOLD}${OUTPUT_FILE}${NC}"

    # Backup existing .env if present
    if [ -f "$ENV_FILE" ]; then
        cp "$ENV_FILE" "${ENV_FILE}.bak"
    fi

    # Create .env file for docker-compose
    cat > "$ENV_FILE" << EOF
# =============================================================================
# Hytale Server Configuration - Generated by hytale-auth.sh
# Generated: $(date -Iseconds)
# =============================================================================

# Token Authentication
OWNER_NAME=${PROFILE_USERNAME}
OWNER_UUID=${PROFILE_UUID}
SESSION_TOKEN=${SESSION_TOKEN}
IDENTITY_TOKEN=${IDENTITY_TOKEN}

# OAuth2 (for automatic refresh)
ACCESS_TOKEN=${ACCESS_TOKEN}
REFRESH_TOKEN=${REFRESH_TOKEN}
EOF

    chmod 600 "$ENV_FILE"
    echo -e "  ${GREEN}✓ Environment file: ${BOLD}${ENV_FILE}${NC}"
}

# Show summary
show_summary() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}        ✓ AUTHENTICATION SUCCESSFUL!${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}Profile:${NC}       ${PROFILE_USERNAME}"
    echo -e "  ${BOLD}UUID:${NC}          ${PROFILE_UUID}"
    echo -e "  ${BOLD}Session exp:${NC}   ${SESSION_EXPIRES_AT}"
    echo ""
    echo -e "  ${BOLD}Files created:${NC}"
    echo -e "    • ${CYAN}.env${NC} - Variables for docker-compose"
    echo -e "    • ${CYAN}${OUTPUT_FILE}${NC} - Full credentials (JSON)"
    echo ""
    echo -e "${GREEN}${BOLD}Next steps:${NC}"
    echo -e "  1. Start the server: ${CYAN}docker-compose up -d${NC}"
    echo -e "  2. View logs:        ${CYAN}docker-compose logs -f${NC}"
    echo ""
    echo -e "${YELLOW}When tokens expire, refresh them with:${NC}"
    echo -e "  ${CYAN}./scripts/hytale-refresh.sh${NC}"
    echo ""
}

# Main
main() {
    check_dependencies
    request_device_code
    poll_for_token
    get_profiles
    create_game_session
    save_credentials
    show_summary
}

main "$@"
