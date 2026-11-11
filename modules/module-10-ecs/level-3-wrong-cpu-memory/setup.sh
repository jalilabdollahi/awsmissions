#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local ecs create-cluster --cluster-name snapwell >/dev/null
echo "Cluster snapwell is ready; task-definition.json is not a valid Fargate size."
