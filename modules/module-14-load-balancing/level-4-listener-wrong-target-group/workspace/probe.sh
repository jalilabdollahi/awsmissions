#!/usr/bin/env bash
# Visit maplewood-alb like a member's browser: one GET through the listener on port 80.
#   bash probe.sh          -> GET /
# The load balancer lives inside the emulator container, hence docker exec.
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
BOX="awsmissions-floci"
[ "$PORT" = "4566" ] || BOX="awsmissions-floci-$PORT"
NAME=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names maplewood-alb --query 'LoadBalancers[0].DNSName' --output text)
docker exec "$BOX" bash -c \
  'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" "$2" >&3; cat <&3' \
  _ "${1:-/}" "$NAME"
echo
