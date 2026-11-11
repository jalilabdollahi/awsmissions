#!/usr/bin/env bash
# One GET through corallo-alb port 80, printing status line, headers and body.
#   bash probe.sh /api/orders
#   bash probe.sh /api/admin/users
# The listener runs inside the emulator container, so the request is sent from there.
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
CTR="awsmissions-floci"
[ "$PORT" = "4566" ] || CTR="awsmissions-floci-$PORT"
LBHOST=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names corallo-alb --query 'LoadBalancers[0].DNSName' --output text)
docker exec "$CTR" bash -c \
  'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" "$2" >&3; cat <&3' \
  _ "${1:-/}" "$LBHOST"
echo
