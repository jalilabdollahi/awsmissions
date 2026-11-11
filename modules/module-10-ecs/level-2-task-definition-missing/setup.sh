#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local ecs create-cluster --cluster-name harbor >/dev/null
echo "The harbor cluster is ready. No task definitions exist in this account."
