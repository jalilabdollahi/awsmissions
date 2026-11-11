#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Leftovers from an earlier attempt must not block the stack name.
aws_local cloudformation delete-stack --stack-name harborlights-core >/dev/null 2>&1 || true

echo "Priya's template is in your workspace. Nothing has been deployed yet."
