#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local autoscaling delete-scheduled-action --auto-scaling-group-name lumen-api-asg \
  --scheduled-action-name nightly-shutdown
aws_local autoscaling update-auto-scaling-group --auto-scaling-group-name lumen-api-asg \
  --min-size 2 --max-size 6 --desired-capacity 2
