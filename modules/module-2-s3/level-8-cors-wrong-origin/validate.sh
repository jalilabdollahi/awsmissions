#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

URL="$AWS_ENDPOINT_URL/brightcart-media/banners/hero.jpg"
SHOP="https://shop.brightcart.example"
ADMIN="https://admin.brightcart.example"

code() { # origin method [headers]  -> HTTP status of the preflight
  curl -s -o /dev/null -w '%{http_code}' -X OPTIONS "$URL" -H "Origin: $1" \
    -H "Access-Control-Request-Method: $2" ${3:+-H "Access-Control-Request-Headers: $3"}
}

# The storefront must be untouched: GET works, writes do not.
if [ "$(code "$SHOP" GET)" != "200" ]; then
  echo "The storefront can no longer read media: its GET preflight fails. Keep its rule intact."
  exit 1
fi
if [ "$(code "$SHOP" PUT)" = "200" ] || [ "$(code "$SHOP" DELETE)" = "200" ]; then
  echo "The storefront origin can now write or delete. It must stay read-only."
  exit 1
fi

for method in PUT DELETE; do
  if [ "$(code "$ADMIN" "$method" content-type)" != "200" ]; then
    echo "The admin app's $method preflight is still rejected."
    exit 1
  fi
done

for stranger in "https://admin.brightcart.example.evil.test" "https://brightcart.example" "http://admin.brightcart.example"; do
  if [ "$(code "$stranger" PUT)" = "200" ]; then
    echo "The origin $stranger is allowed to write. Allow the exact admin origin only, not a pattern that matches look-alikes."
    exit 1
  fi
done
echo "The admin app can PUT and DELETE, the storefront is still read-only, and look-alike origins are refused."
