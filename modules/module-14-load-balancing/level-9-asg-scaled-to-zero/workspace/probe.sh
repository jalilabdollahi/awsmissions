#!/usr/bin/env bash
# Request the thumbnail API through lumen-alb and show who answered.
#   bash probe.sh          -> GET /
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
BOXN="awsmissions-floci"
[ "$PORT" = "4566" ] || BOXN="awsmissions-floci-$PORT"
NAMEOFLB=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names lumen-alb --query 'LoadBalancers[0].DNSName' --output text)
docker exec "$BOXN" bash -c \
  'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" "$2" >&3; cat <&3' \
  _ "${1:-/}" "$NAMEOFLB"
echo
