#!/usr/bin/env bash
# Send a request to helix-alb's listener pretending to be a browser that typed a given hostname.
#   bash probe.sh app.helixpay.example
#   bash probe.sh portal.helixpay.example /
# With no argument it uses the load balancer's own DNS name, which hits the default rule.
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
BOX="awsmissions-floci"
[ "$PORT" = "4566" ] || BOX="awsmissions-floci-$PORT"
OWN=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names helix-alb --query 'LoadBalancers[0].DNSName' --output text)
LISTEN=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-listeners \
  --load-balancer-arn "$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names helix-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)" --query 'Listeners[0].Port' --output text)
docker exec "$BOX" bash -c \
  'exec 3<>/dev/tcp/127.0.0.1/"$3"; printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$2" "$1" >&3; cat <&3' \
  _ "${1:-$OWN}" "${2:-/}" "$LISTEN"
echo
