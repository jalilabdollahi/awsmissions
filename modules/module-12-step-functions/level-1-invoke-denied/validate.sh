#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SM_ARN="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:tidewater-label-flow"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/tidewater-label-flow-role"
probe_name="awsm-probe-customs"
trap 'aws_local stepfunctions delete-state-machine --state-machine-arn "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:${probe_name}" >/dev/null 2>&1 || true' EXIT

# Runs one execution to completion and leaves its ARN in $EXEC.
run_to_end() {
  local sm="$1" input="$2" i=0 status
  EXEC="$(aws_local stepfunctions start-execution --state-machine-arn "$sm" --input "$input" \
    --query executionArn --output text)"
  while [ "$i" -lt 45 ]; do
    status="$(aws_local stepfunctions describe-execution --execution-arn "$EXEC" --query status --output text)"
    [ "$status" != "RUNNING" ] && break
    sleep 1; i=$((i + 1))
  done
}

if ! aws_local stepfunctions describe-state-machine --state-machine-arn "$SM_ARN" >/dev/null 2>&1; then
  echo "tidewater-label-flow no longer exists. Fix it, do not rebuild it."
  exit 1
fi
current_role="$(aws_local stepfunctions describe-state-machine --state-machine-arn "$SM_ARN" --query roleArn --output text)"
if [ "$current_role" != "$ROLE_ARN" ]; then
  echo "The state machine now runs as a different role. This mission is about repairing tidewater-label-flow-role."
  exit 1
fi

run_to_end "$SM_ARN" '{"shipmentId":"TF-1042"}'
status="$(aws_local stepfunctions describe-execution --execution-arn "$EXEC" --query status --output text)"
if [ "$status" != "SUCCEEDED" ]; then
  err="$(aws_local stepfunctions describe-execution --execution-arn "$EXEC" --query '[error,cause]' --output text | cut -c1-300)"
  echo "The execution ended as $status."
  echo "Step Functions reported: $err"
  exit 1
fi
label="$(aws_local stepfunctions describe-execution --execution-arn "$EXEC" --query output --output text | jq -r '.label // empty')"
if [ "$label" != "LBL-1042" ]; then
  echo "The execution succeeded but the label for TF-1042 is wrong or missing."
  exit 1
fi

# Least privilege: the same role must still be unable to run the customs function.
aws_local stepfunctions create-state-machine --name "$probe_name" --role-arn "$ROLE_ARN" \
  --definition "{\"StartAt\":\"C\",\"States\":{\"C\":{\"Type\":\"Task\",\"Resource\":\"arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:print-customs-form\",\"End\":true}}}" >/dev/null
run_to_end "arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:${probe_name}" '{"shipmentId":"TF-1"}'
status="$(aws_local stepfunctions describe-execution --execution-arn "$EXEC" --query status --output text)"
if [ "$status" = "SUCCEEDED" ]; then
  echo "Labels print again, but the role can now invoke print-customs-form as well. Allow only print-shipping-label."
  exit 1
fi

echo "tidewater-label-flow prints TF-1042's label, and the role still cannot touch print-customs-form."
