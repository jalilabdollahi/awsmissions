#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=tidewater-pod-photos
URL="$AWS_ENDPOINT_URL/$B/pod/shipment-88213.jpg"
DASH="https://dashboard.tidewater.example"

preflight() { # origin method [request-headers]
  curl -s -i -X OPTIONS "$URL" -H "Origin: $1" -H "Access-Control-Request-Method: $2" \
    ${3:+-H "Access-Control-Request-Headers: $3"} | tr -d '\r'
}
status_of() { printf '%s' "$1" | head -1 | awk '{print $2}'; }
allow_origin_of() { printf '%s' "$1" | grep -i '^access-control-allow-origin:' | awk '{print $2}'; }

r="$(preflight "$DASH" PUT content-type)"
if [ "$(status_of "$r")" != "200" ] || [ "$(allow_origin_of "$r")" != "$DASH" ]; then
  echo "The dashboard's PUT preflight (with a Content-Type header) is rejected (HTTP $(status_of "$r"))."
  exit 1
fi
r="$(preflight "$DASH" GET)"
if [ "$(status_of "$r")" != "200" ]; then
  echo "The dashboard's GET preflight is rejected (HTTP $(status_of "$r"))."
  exit 1
fi

# A real cross-origin GET must expose ETag to the page's JavaScript.
exposed="$(curl -s -i "$URL" -H "Origin: $DASH" | tr -d '\r' | grep -i '^access-control-expose-headers:' || true)"
if ! printf '%s' "$exposed" | grep -qi 'etag'; then
  echo "Responses do not expose ETag to the browser, so the dashboard cannot confirm uploads."
  exit 1
fi

r="$(preflight "https://evil.example" PUT content-type)"
if [ "$(status_of "$r")" = "200" ]; then
  echo "A foreign origin (https://evil.example) also passes the preflight. Allow only the dashboard origin."
  exit 1
fi
r="$(preflight "$DASH" DELETE)"
if [ "$(status_of "$r")" = "200" ]; then
  echo "The dashboard may now send DELETE requests, which it never needs. Allow only GET and PUT."
  exit 1
fi
echo "The dashboard origin can GET and PUT with Content-Type and read ETag; everyone else is still blocked."
