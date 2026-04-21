#!/bin/bash
# setup.sh — Install GSD and configure the Cloudera AI provider.
#
# This script runs automatically as an AMP build step on project creation,
# and can also be re-run manually at any time.
#
# What it does:
#   1. Installs Node.js 22 via NVM (user-local, no sudo)
#   2. Installs GSD (gsd-pi) globally
#   3. Writes the Cloudera AI provider config to ~/.gsd/agent/models.json
#   4. Optionally loads your API token from token.txt (skipped if placeholder)
#   5. Generates launch-gsd.sh (blocks AWS Bedrock auto-discovery)
#
# After this runs, you still need to:
#   1. Edit models.json — replace CAII_ENDPOINT_URL with your endpoint
#   2. Paste your token into token.txt
#   3. Run: bash refresh-token.sh
#   4. Run: bash launch-gsd.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOKEN_FILE="$SCRIPT_DIR/token.txt"
MODELS_TEMPLATE="$SCRIPT_DIR/models.json"

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[setup]${NC} $1"; }
warn()  { echo -e "${YELLOW}[setup]${NC} $1"; }
error() { echo -e "${RED}[setup]${NC} $1"; }

# ── Step 1: Node.js via NVM ────────────────────────────────────────────────
info "Checking Node.js..."
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

if ! nvm ls 22 &>/dev/null; then
    info "Installing Node.js 22..."
    nvm install 22
fi
nvm use 22 --silent 2>/dev/null || true
info "Node.js $(node --version) ready."

# ── Step 2: Install GSD ────────────────────────────────────────────────────
if ! command -v gsd &>/dev/null; then
    info "Installing GSD (gsd-pi)..."
    npm install -g gsd-pi@latest
else
    info "GSD already installed: $(gsd --version 2>/dev/null || echo 'unknown version')"
fi

# ── Step 3: Write models.json (Cloudera AI provider) ───────────────────────
info "Configuring Cloudera AI provider..."

if [ ! -f "$MODELS_TEMPLATE" ]; then
    error "models.json not found in repo root. Cannot configure provider."
    exit 1
fi

# Check if the user has customized the endpoint URL
ENDPOINT_CHECK=$(grep -c "CAII_ENDPOINT_URL" "$MODELS_TEMPLATE" || true)
if [ "$ENDPOINT_CHECK" -gt 0 ]; then
    warn "models.json still contains the placeholder CAII_ENDPOINT_URL."
    warn "Provider config written as-is. You must edit models.json with your"
    warn "actual endpoint URL, then re-run: bash setup.sh"
fi

for DIR in ~/.gsd/agent ~/.pi/agent; do
    mkdir -p "$DIR"
    cp "$MODELS_TEMPLATE" "$DIR/models.json"
done
info "Provider config written to ~/.gsd/agent/models.json and ~/.pi/agent/models.json"

# ── Step 4: Attempt token load (skip if placeholder) ──────────────────────
PLACEHOLDER="first_remove_this_entire_message_then_place_my_token_here"

if [ -f "$TOKEN_FILE" ]; then
    NEW_TOKEN=$(cat "$TOKEN_FILE" | tr -d '[:space:]')
    if [ -n "$NEW_TOKEN" ] && [ "$NEW_TOKEN" != "$PLACEHOLDER" ]; then
        info "Loading API token from token.txt..."
        # Protect from accidental git commits
        git -C "$SCRIPT_DIR" update-index --skip-worktree token.txt 2>/dev/null || true
        for DIR in ~/.gsd/agent ~/.pi/agent; do
            cat > "$DIR/auth.json" << EOF
{
  "cloudera-ai": {
    "type": "api_key",
    "key": "$NEW_TOKEN"
  }
}
EOF
        done
        info "Token loaded into auth.json."
    else
        warn "token.txt contains placeholder or is empty — skipping token load."
        warn "Paste your CDP/UMS token into token.txt, then run: bash refresh-token.sh"
    fi
else
    warn "token.txt not found — skipping token load."
fi

# ── Step 5: Generate launch-gsd.sh ────────────────────────────────────────
info "Generating launch-gsd.sh..."
cat > "$SCRIPT_DIR/launch-gsd.sh" << 'LAUNCHER'
#!/bin/bash
# launch-gsd.sh — Start GSD with the private Cloudera AI model.
#
# Blocks AWS Bedrock auto-discovery so GSD only sees the cloudera-ai provider.
#
# Usage:
#   bash launch-gsd.sh        # new session
#   bash launch-gsd.sh -c     # resume last session

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 22 --silent 2>/dev/null || true

# Block Bedrock auto-discovery
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
unset AWS_PROFILE AWS_DEFAULT_REGION AWS_REGION

RESUME_FLAG=""
if [ "$1" = "-c" ] || [ "$1" = "--continue" ]; then
    RESUME_FLAG="-c"
fi

exec gsd $RESUME_FLAG --provider cloudera-ai --model "nvidia/llama-3.3-nemotron-super-49b-v1.5"
LAUNCHER
chmod +x "$SCRIPT_DIR/launch-gsd.sh"

# ── Done ───────────────────────────────────────────────────────────────────
echo ""
info "=========================================="
info "  Setup complete."
info "=========================================="
echo ""
if [ "$ENDPOINT_CHECK" -gt 0 ]; then
    warn "NEXT STEPS:"
    echo "  1. Edit models.json — replace CAII_ENDPOINT_URL with your endpoint"
    echo "  2. Paste your API token into token.txt"
    echo "  3. Run: bash setup.sh          (re-run to pick up endpoint + token)"
    echo "  4. mkdir my-project && cd my-project && git init"
    echo "  5. Run: bash ../launch-gsd.sh"
else
    echo "  To launch GSD:"
    echo "    mkdir my-project && cd my-project && git init"
    echo "    bash ../launch-gsd.sh"
    echo ""
    warn "  Token expires ~1 hour. When it does:"
    echo "    1. Paste new token into token.txt"
    echo "    2. Run: bash refresh-token.sh"
    echo "    3. Ctrl+C GSD, then: bash launch-gsd.sh -c"
fi
