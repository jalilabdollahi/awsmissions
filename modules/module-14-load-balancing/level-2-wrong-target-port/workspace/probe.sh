#!/usr/bin/env bash
# One HTTP GET through tidewater-alb (port 80), like a customer's browser would send.
# The load balancer listens inside the emulator container, so we call it from there.
#   bash probe.sh          -> GET /
#   bash probe.sh /status  -> GET /status
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
NAME="awsmissions-floci"
[ "$PORT" = "4566" ] || NAME="awsmissions-floci-$PORT"
HOSTNAME_LB=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names tidewater-alb --query 'LoadBalancers[0].DNSName' --output text)
docker exec "$NAME" bash -c \
  'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" "$2" >&3; cat <&3' \
  _ "${1:-/}" "$HOSTNAME_LB"
echo
