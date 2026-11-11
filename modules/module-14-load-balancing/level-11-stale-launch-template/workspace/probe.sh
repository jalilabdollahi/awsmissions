#!/usr/bin/env bash
# One request through parcelway-alb; the page says which release answered.
#   bash probe.sh
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
CNAME="awsmissions-floci"
[ "$PORT" = "4566" ] || CNAME="awsmissions-floci-$PORT"
LBDNS=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names parcelway-alb --query 'LoadBalancers[0].DNSName' --output text)
docker exec "$CNAME" bash -c \
  'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" "$2" >&3; cat <&3' \
  _ "${1:-/}" "$LBDNS"
echo
