#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudformation delete-stack --stack-name fernwood-orders >/dev/null 2>&1 || true
echo "The Fernwood order template is in your workspace. No stack exists yet."
