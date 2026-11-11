#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudformation delete-stack --stack-name granitepeak-intake >/dev/null 2>&1 || true
echo "The Granite Peak intake template is in your workspace; nothing is deployed."
