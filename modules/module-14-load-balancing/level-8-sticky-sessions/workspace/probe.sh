#!/usr/bin/env bash
# Make a few requests like one shopper's browser would, optionally re-sending a cookie.
#   bash probe.sh                      -> 6 requests without a cookie, shows which server answered
#   bash probe.sh -v                   -> also prints the response headers of the first request
# Which server answered each time is in the page body.
set -euo pipefail
PORT="${AWSMISSIONS_PORT:-4566}"
BOXNAME="awsmissions-floci"
[ "$PORT" = "4566" ] || BOXNAME="awsmissions-floci-$PORT"
ALB=$(aws --endpoint-url="${AWS_ENDPOINT_URL:-http://localhost:$PORT}" elbv2 describe-load-balancers \
  --names kestrel-alb --query 'LoadBalancers[0].DNSName' --output text)
ask() {
  docker exec "$BOXNAME" bash -c \
    'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET / HTTP/1.0\r\nHost: %s\r\n%b\r\n" "$1" "$2" >&3; cat <&3' _ "$ALB" "$1" | tr -d '\r'
}
first=$(ask "")
[ "${1:-}" = "-v" ] && printf '%s\n\n' "$first"
cookie=$(printf '%s' "$first" | grep -m1 '^Set-Cookie: AWSALB=' | sed 's/^Set-Cookie: //; s/;.*//' || true)
echo "cookie from the load balancer: ${cookie:-<none>}"
for i in 1 2 3 4 5 6; do
  if [ -n "$cookie" ]; then ask "Cookie: $cookie\r\n" | tail -1; else ask "" | tail -1; fi
  echo
done
