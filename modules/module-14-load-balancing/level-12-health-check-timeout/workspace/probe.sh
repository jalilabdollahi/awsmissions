#!/usr/bin/env bash
# Time a request straight to the first instance, bypassing the load balancer.
#   bash probe.sh /health     -> how long does the deep check take?
#   bash probe.sh /livez
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
EP="${AWS_ENDPOINT_URL:-http://localhost:$PORT}"
IID=$(aws --endpoint-url="$EP" ec2 describe-instances --filters "Name=tag:Name,Values=fathomly-api-1" \
  "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text)
started=$(date +%s)
docker exec "floci-aws-ec2-$IID" sh -c 'wget -qO- "http://127.0.0.1:8080$1"' _ "${1:-/health}"
echo
echo "took $(( $(date +%s) - started ))s"
