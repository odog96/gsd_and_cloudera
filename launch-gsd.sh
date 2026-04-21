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
