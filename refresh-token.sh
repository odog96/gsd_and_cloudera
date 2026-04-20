#!/bin/bash
# Loads your API token from token.txt and writes it to GSD's auth config.
# Run this whenever your token expires, then launch GSD manually.
#
# TOKEN SOURCE: Paste your API token from the CAII model endpoint UI into token.txt
#
# Token expires ~1 hour after generation. When it expires:
#   1. Get a fresh token from the CAII model endpoint UI
#   2. Paste it into token.txt in this repo's root directory
#   3. Re-run this script
#   4. Launch GSD: gsd --provider cloudera-ai --model "nvidia/llama-3.3-nemotron-super-49b-v1.5"

set -e

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 22 --silent 2>/dev/null || true

TOKEN_FILE="$(cd "$(dirname "$0")" && pwd)/token.txt"

if [ ! -f "$TOKEN_FILE" ]; then
    echo "ERROR: $TOKEN_FILE not found. Paste your CDP/UMS token into that file first."
    exit 1
fi

NEW_TOKEN=$(cat "$TOKEN_FILE" | tr -d '[:space:]')

if [ -z "$NEW_TOKEN" ]; then
    echo "ERROR: $TOKEN_FILE is empty."
    exit 1
fi

PLACEHOLDER="first_remove_this_entire_message_then_place_my_token_here"
if [ "$NEW_TOKEN" = "$PLACEHOLDER" ]; then
    echo "ERROR: token.txt still contains the placeholder. Replace it with your real CDP/UMS token from the CAII model endpoint UI."
    exit 1
fi

# Protect the real token from accidental git commits on this clone
git -C "$(dirname "$TOKEN_FILE")" update-index --skip-worktree token.txt 2>/dev/null || true

# Sync token into auth.json for both gsd and pi agent dirs
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

export CLOUDERA_AI_API_KEY="$NEW_TOKEN"

echo "[refresh-token] Token loaded. Next steps:"
echo ""
echo "  1. Create and enter a project directory (GSD requires a git repo):"
echo "     mkdir my-project && cd my-project && git init"
echo ""
echo "  2. Launch GSD:"
echo "     gsd --provider cloudera-ai --model \"nvidia/llama-3.3-nemotron-super-49b-v1.5\""
