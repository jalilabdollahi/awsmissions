#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# The draft is too big for a user inline policy (2,048 bytes), but fits a managed policy.
policy_arn="$(aws_local iam create-policy --policy-name fleet-telemetry-read \
  --policy-document file://policy.json --query Policy.Arn --output text)"
aws_local iam attach-user-policy --user-name fleet-ops --policy-arn "$policy_arn"
