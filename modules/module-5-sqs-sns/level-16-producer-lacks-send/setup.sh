#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local sqs create-queue --queue-name gatehouse-intake >/dev/null
aws_local sqs create-queue --queue-name gatehouse-audit >/dev/null
aws_local iam create-user --user-name gatehouse-api >/dev/null
aws_local iam put-user-policy --user-name gatehouse-api --policy-name intake-writer \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "gatehouse-api has a policy named intake-writer. Registrations still fail."
