#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local ecs create-cluster --cluster-name ledgerly-batch >/dev/null
aws_local ecs run-task --cluster ledgerly-batch --task-definition nightly-report --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-a],assignPublicIp=ENABLED}" >/dev/null
