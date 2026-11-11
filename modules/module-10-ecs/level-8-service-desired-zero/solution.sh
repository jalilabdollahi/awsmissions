#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local ecs update-service --cluster sundial --service sundial-api --desired-count 2 >/dev/null
