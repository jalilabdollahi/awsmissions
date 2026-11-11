#!/usr/bin/env bash
# Ask quillstone-alb (port 80) for a URL and print the response headers.
#   bash probe.sh "/pricing?plan=pro"
# Look at the status line and at the Location header.
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
CNT="awsmissions-floci"
[ "$PORT" = "4566" ] || CNT="awsmissions-floci-$PORT"
ALB=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names quillstone-alb --query 'LoadBalancers[0].DNSName' --output text)
docker exec "$CNT" bash -c \
  'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" "$2" >&3; cat <&3' \
  _ "${1:-/}" "$ALB"
