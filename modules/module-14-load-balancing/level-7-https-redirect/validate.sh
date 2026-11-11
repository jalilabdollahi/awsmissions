#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

DNS=$(aws_local elbv2 describe-load-balancers --names quillstone-alb --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null || true)
if [ -z "$DNS" ] || [ "$DNS" = "None" ]; then
  echo "quillstone-alb does not exist any more."
  exit 1
fi

CNT="awsmissions-floci"
[ "${AWSMISSIONS_PORT:-4566}" = "4566" ] || CNT="awsmissions-floci-${AWSMISSIONS_PORT}"
request() {
  docker exec "$CNT" bash -c \
    'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" "$2" >&3; cat <&3' _ "$1" "$DNS" 2>/dev/null | tr -d '\r'
}

check_one() {
  local url_path="$1" want_path="$2" want_query="$3"
  local reply status location
  reply=$(request "$url_path")
  status=$(printf '%s' "$reply" | head -1 | awk '{print $2}')
  location=$(printf '%s' "$reply" | grep -i '^location:' | head -1 | sed 's/^[Ll]ocation: *//')
  if [ -z "$status" ]; then
    echo "No answer from the port-80 listener of quillstone-alb."
    exit 1
  fi
  if [ -z "$location" ]; then
    echo "GET $url_path gets HTTP $status and no Location header: the listener is not redirecting."
    exit 1
  fi
  python3 - "$status" "$location" "$DNS" "$want_path" "$want_query" "$url_path" <<'PY' || exit 1
import sys
from urllib.parse import urlsplit
status, location, dns, want_path, want_query, asked = sys.argv[1:7]
u = urlsplit(location)
problems = []
if status != "301":
    problems.append("status is %s, a permanent redirect must be 301" % status)
if u.scheme != "https":
    problems.append("target scheme is %s, not https" % u.scheme)
if u.port not in (None, 443):
    problems.append("target port is %s, expected the standard HTTPS port" % u.port)
if u.hostname != dns:
    problems.append("target host is %s, expected the host the visitor used (%s)" % (u.hostname, dns))
path = "/" + u.path.lstrip("/")
if path != want_path:
    problems.append("target path is %s but the visitor asked for %s" % (path, want_path))
if u.query != want_query:
    problems.append("target query is '%s' but the visitor sent '%s'" % (u.query, want_query))
if problems:
    print("GET %s -> %s" % (asked, location))
    for p in problems:
        print("  - " + p)
    sys.exit(1)
PY
}

check_one "/pricing?plan=pro" "/pricing" "plan=pro"
check_one "/authors/ada/books?page=2&sort=new" "/authors/ada/books" "page=2&sort=new"
check_one "/" "/" ""
echo "Every HTTP request is permanently redirected to https on 443 with its path and query intact."
