#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

RET=$(aws_local logs describe-log-groups --log-group-name-prefix /ecs/checkout-worker \
  --query "logGroups[?logGroupName=='/ecs/checkout-worker'].retentionInDays|[0]" --output text 2>/dev/null || true)
if [ "$RET" != "14" ]; then
  echo "The log group /ecs/checkout-worker is missing or lost its 14-day retention (retention now: ${RET:-none}). Keep the existing group."
  exit 1
fi
TD=$(aws_local ecs describe-services --cluster marigold --services checkout-worker --query 'services[0].taskDefinition' --output text 2>/dev/null || true)
CFG=$(aws_local ecs describe-task-definition --task-definition "$TD" --query 'taskDefinition.containerDefinitions[0].logConfiguration' --output json)
CFG="$CFG" python3 -c '
import json, os, sys
cfg = json.loads(os.environ["CFG"] or "null") or {}
driver = cfg.get("logDriver")
opts = cfg.get("options", {})
if driver != "awslogs":
    print("The running revision logs with driver %r. Fargate can only ship logs through awslogs (or splunk/awsfirelens)." % driver); sys.exit(1)
if opts.get("awslogs-group") != "/ecs/checkout-worker":
    print("awslogs-group is %r; the dashboard reads /ecs/checkout-worker." % opts.get("awslogs-group")); sys.exit(1)
for needed in ("awslogs-region", "awslogs-stream-prefix"):
    if not opts.get(needed):
        print("awslogs needs the option %s on Fargate." % needed); sys.exit(1)
' || exit 1

arrived() {
  aws_local logs filter-log-events --log-group-name /ecs/checkout-worker --filter-pattern '"checkout-worker ready"' \
    --query 'events[0].message' --output text | grep -q ready
}
if ! wait_for "checkout-worker log lines in /ecs/checkout-worker" 60 arrived; then
  echo "The configuration looks right, but no log line has arrived in /ecs/checkout-worker yet. Is a task of the new revision running?"
  exit 1
fi
echo "checkout-worker's output now reaches /ecs/checkout-worker. The dashboard lives again."
