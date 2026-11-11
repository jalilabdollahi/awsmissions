#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SM="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:harborview-refill-flow"

if ! aws_local stepfunctions describe-state-machine --state-machine-arn "$SM" >/dev/null 2>&1; then
  echo "harborview-refill-flow is gone. Update it rather than deleting it."
  exit 1
fi

exec_arn="$(aws_local stepfunctions start-execution --state-machine-arn "$SM" \
  --input '{"rx":"RX-5521","dose":2}' --query executionArn --output text)"

finished() {
  [ "$(aws_local stepfunctions describe-execution --execution-arn "$exec_arn" --query status --output text)" != "RUNNING" ]
}
wait_for "the refill execution to finish" 40 finished || { echo "The execution is still running after 40s."; exit 1; }

desc="$(aws_local stepfunctions describe-execution --execution-arn "$exec_arn" --output json)"
status="$(printf '%s' "$desc" | jq -r .status)"
if [ "$status" != "SUCCEEDED" ]; then
  echo "The refill execution ended as $status: $(printf '%s' "$desc" | jq -r '[.error // "", (.cause // "")] | join(" ")' | cut -c1-240)"
  exit 1
fi

approved="$(printf '%s' "$desc" | jq -r '.output | fromjson | .approved')"
ruleset="$(printf '%s' "$desc" | jq -r '.output | fromjson | .ruleset')"
case "$ruleset" in
  staging-*) echo "The refill went through, but it was decided by the STAGING eligibility function (ruleset $ruleset). Patients' refills must use production."; exit 1 ;;
esac
if [ "$approved" != "true" ] || [ "$ruleset" != "prod-2024.2" ]; then
  echo "The execution succeeded but the decision looks wrong (approved=$approved, ruleset=$ruleset)."
  exit 1
fi

echo "RX-5521 approved by the production ruleset ($ruleset). Patients can refill again."
