#!/bin/bash
# Wrapper to launch GSD against Nemotron 49B on Cloudera AI Inference Service.
#
# TOKEN SOURCE: Paste your API token from the CAII model endpoint UI into token.txt
#
# Token expires ~1 hour after generation. When it expires:
#   1. Get a fresh token from the CAII model endpoint UI
#   2. Paste it into token.txt (or use: nano /home/cdsw/token.txt)
#   3. Re-run this script

set -e

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

TOKEN_FILE="/home/cdsw/token.txt"

if [ ! -f "$TOKEN_FILE" ]; then
    echo "ERROR: $TOKEN_FILE not found. Paste your CDP/UMS token into that file first."
    exit 1
fi

NEW_TOKEN=$(cat "$TOKEN_FILE" | tr -d '[:space:]')

if [ -z "$NEW_TOKEN" ]; then
    echo "ERROR: $TOKEN_FILE is empty."
    exit 1
fi

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

echo "[run-gsd] Token loaded. Launching GSD with Nemotron 49B..."
exec gsd --model "cloudera-ai/nvidia/llama-3.3-nemotron-super-49b-v1.5" "$@"
