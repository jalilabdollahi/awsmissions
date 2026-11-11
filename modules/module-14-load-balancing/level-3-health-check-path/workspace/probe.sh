#!/usr/bin/env bash
# Ask the API a question directly on an instance, bypassing the load balancer's opinion.
# Use it to find which route answers HTTP 200:
#   bash probe.sh /            -> prints status line and body for GET /
#   bash probe.sh /orders
# It targets brewline-api-1 over the emulator's Docker network.
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
EP="${AWS_ENDPOINT_URL:-http://localhost:$PORT}"
ID=$(aws --endpoint-url="$EP" ec2 describe-instances --filters "Name=tag:Name,Values=brewline-api-1" \
  "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text)
docker exec "floci-aws-ec2-$ID" sh -c \
  'wget -S -qO- "http://127.0.0.1:8080$1" 2>&1 || true' _ "${1:-/}"
echo
