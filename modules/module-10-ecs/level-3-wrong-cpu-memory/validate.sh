#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TD=$(aws_local ecs describe-task-definition --task-definition thumbnailer --query taskDefinition --output json 2>/dev/null || true)
if [ -z "$TD" ]; then
  echo "No ACTIVE task definition for the family thumbnailer is registered yet."
  exit 1
fi
TD="$TD" python3 -c '
import json, os, sys
td = json.loads(os.environ["TD"])
cpu, mem = int(td["cpu"]), int(td["memory"])
need = sum(c.get("memory", 0) for c in td["containerDefinitions"])
if mem < need:
    print("Task memory %d MiB is below the container hard limit of %d MiB; the task would be killed (OOM)." % (mem, need)); sys.exit(1)
if cpu > 1024 or mem > 4096:
    print("%d CPU units / %d MiB is oversized. Pick the smallest valid Fargate size that fits (max 1 vCPU, 4 GiB)." % (cpu, mem)); sys.exit(1)
if cpu == 256 and mem > 2048:
    print("256 CPU only supports up to 2048 MiB on Fargate."); sys.exit(1)
if td.get("revision", 0) < 1:
    sys.exit(1)
' || exit 1

NET="awsvpcConfiguration={subnets=[subnet-default-us-east-1-a]}"
ARN=$(aws_local ecs run-task --cluster snapwell --task-definition thumbnailer --launch-type FARGATE \
  --network-configuration "$NET" --query 'tasks[0].taskArn' --output text)
running() { [ "$(aws_local ecs describe-tasks --cluster snapwell --tasks "$ARN" --query 'tasks[0].lastStatus' --output text)" = RUNNING ]; }
if ! wait_for "the thumbnailer task to reach RUNNING" 40 running; then
  echo "A thumbnailer task was launched but did not reach RUNNING: $(aws_local ecs describe-tasks --cluster snapwell --tasks "$ARN" --query 'tasks[0].stoppedReason' --output text)"
  aws_local ecs stop-task --cluster snapwell --task "$ARN" >/dev/null 2>&1 || true
  exit 1
fi
aws_local ecs stop-task --cluster snapwell --task "$ARN" >/dev/null 2>&1 || true
echo "thumbnailer is registered with a valid, right-sized configuration and a test task started."
