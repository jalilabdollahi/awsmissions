#!/usr/bin/env bash
# Call the dispatch API as a rider app would: one GET through orbit-alb on port 80.
#   bash probe.sh
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
EMU="awsmissions-floci"
[ "$PORT" = "4566" ] || EMU="awsmissions-floci-$PORT"
DNSNAME=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names orbit-alb --query 'LoadBalancers[0].DNSName' --output text)
docker exec "$EMU" bash -c \
  'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" "$2" >&3; cat <&3' \
  _ "${1:-/}" "$DNSNAME"
echo
