#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

STATUS=$(aws_local ecs describe-clusters --clusters ledgerly-batch --query 'clusters[0].status' --output text 2>/dev/null || true)
if [ "$STATUS" != "ACTIVE" ]; then
  echo "There is no ACTIVE ECS cluster named ledgerly-batch (describe-clusters says: ${STATUS:-nothing})."
  exit 1
fi
TASKS=$(aws_local ecs list-tasks --cluster ledgerly-batch --family nightly-report --desired-status RUNNING \
  --query 'taskArns[]' --output text 2>/dev/null || true)
if [ -z "$TASKS" ]; then
  echo "The cluster exists, but no nightly-report task is running in it yet."
  exit 1
fi
for arn in $TASKS; do
  id=${arn##*/}
  if docker inspect -f '{{.State.Running}}' "floci-aws-ecs-$id-report" 2>/dev/null | grep -q true; then
    echo "nightly-report is running in ledgerly-batch (task $id). The ledger report is being generated."
    exit 0
  fi
done
echo "ECS lists a nightly-report task but its container is not actually running."
exit 1
