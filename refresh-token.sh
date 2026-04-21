#!/bin/bash
# refresh-token.sh — Reload your CAII token without re-running full setup.
#
# Usage:
#   1. Paste new token into token.txt
#   2. Run: bash refresh-token.sh
#   3. Ctrl+C GSD, then: bash launch-gsd.sh -c

set -e

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 22 --silent 2>/dev/null || true

TOKEN_FILE="$(cd "$(dirname "$0")" && pwd)/token.txt"

if [ ! -f "$TOKEN_FILE" ]; then
    echo "ERROR: $TOKEN_FILE not found."
    exit 1
fi

NEW_TOKEN=$(cat "$TOKEN_FILE" | tr -d '[:space:]')

if [ -z "$NEW_TOKEN" ]; then
    echo "ERROR: $TOKEN_FILE is empty."
    exit 1
fi

PLACEHOLDER="first_remove_this_entire_message_then_place_my_token_here"
if [ "$NEW_TOKEN" = "$PLACEHOLDER" ]; then
    echo "ERROR: token.txt still contains the placeholder."
    exit 1
fi

git -C "$(dirname "$TOKEN_FILE")" update-index --skip-worktree token.txt 2>/dev/null || true

for DIR in ~/.gsd/agent ~/.pi/agent; do
    mkdir -p "$DIR"
    cat > "$DIR/auth.json" << EOF
{
  "cloudera-ai": {
    "type": "api_key",
    "key": "$NEW_TOKEN"
  }
}
EOF
done

echo "[refresh-token] Token loaded. Now restart GSD:"
echo ""
echo "  bash launch-gsd.sh       # fresh session"
echo "  bash launch-gsd.sh -c    # resume last session"
