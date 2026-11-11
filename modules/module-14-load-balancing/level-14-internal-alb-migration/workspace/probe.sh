#!/usr/bin/env bash
# Request a path from a load balancer's first listener, by load balancer name, optionally pretending to be another hostname.
#   bash probe.sh <lb-name> [path] [host-header]
#   bash probe.sh nimbus-gateway /status
#   bash probe.sh my-new-lb / api.nimbusnotes.example
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
NODE="awsmissions-floci"
[ "$PORT" = "4566" ] || NODE="awsmissions-floci-$PORT"
LBN="${1:?usage: bash probe.sh <load-balancer-name> [path] [host-header]}"
OWNDNS=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names "$LBN" --query 'LoadBalancers[0].DNSName' --output text)
LPORT=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-listeners \
  --load-balancer-arn "$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names "$LBN" --query 'LoadBalancers[0].LoadBalancerArn' --output text)" --query 'Listeners[0].Port' --output text)
docker exec "$NODE" bash -c \
  'exec 3<>/dev/tcp/127.0.0.1/"$3"; printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" "$2" >&3; cat <&3' \
  _ "${2:-/}" "${3:-$OWNDNS}" "$LPORT"
echo
