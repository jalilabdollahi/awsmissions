#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

cat > /tmp/awsm-nightly-$$.json <<'JSON'
{
  "family": "nightly-report",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [{
    "name": "report",
    "image": "alpine:3.21",
    "essential": true,
    "command": ["sh", "-c", "echo generating ledger report; sleep 900"]
  }]
}
JSON
aws_local ecs register-task-definition --cli-input-json "file:///tmp/awsm-nightly-$$.json" >/dev/null
rm -f /tmp/awsm-nightly-$$.json
# A look-alike cluster that is NOT the one the cron job names.
aws_local ecs create-cluster --cluster-name ledgerly-staging >/dev/null
echo "nightly-report is registered; the cluster ledgerly-batch is gone."
