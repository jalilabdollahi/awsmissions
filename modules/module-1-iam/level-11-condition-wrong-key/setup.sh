#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local --region eu-west-1 sqs create-queue --queue-name patient-events-eu >/dev/null
aws_local --region us-east-1 sqs create-queue --queue-name patient-events-us >/dev/null

aws_local iam create-user --user-name meridian-eu-worker >/dev/null
aws_local iam put-user-policy --user-name meridian-eu-worker --policy-name eu-sqs-only \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "meridian-eu-worker is rolled out and locked out of its own queue."
