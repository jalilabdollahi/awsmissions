#!/usr/bin/env bash
# Sends one HTTP GET through pageturn-alb, the way a visitor's browser would.
# Floci's load balancers listen inside the emulator container, so we go in there.
#   bash probe.sh            -> GET /
#   bash probe.sh /health    -> GET /health
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
CONTAINER="awsmissions-floci"
[ "$PORT" = "4566" ] || CONTAINER="awsmissions-floci-$PORT"
DNS=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names pageturn-alb --query 'LoadBalancers[0].DNSName' --output text)
docker exec "$CONTAINER" bash -c \
  'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" "$2" >&3; cat <&3' \
  _ "${1:-/}" "$DNS"
echo
