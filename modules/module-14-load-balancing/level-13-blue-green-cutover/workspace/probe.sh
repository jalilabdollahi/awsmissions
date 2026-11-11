#!/usr/bin/env bash
# Send 10 requests through saffron-alb and count which release answers.
#   bash probe.sh
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
EMUC="awsmissions-floci"
[ "$PORT" = "4566" ] || EMUC="awsmissions-floci-$PORT"
LBNAME=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names saffron-alb --query 'LoadBalancers[0].DNSName' --output text)
for i in 1 2 3 4 5 6 7 8 9 10; do
  docker exec "$EMUC" bash -c \
    'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET / HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" >&3; cat <&3' _ "$LBNAME" | tr -d '\r' | tail -1
  echo
done | sort | uniq -c
