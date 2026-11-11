#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

res="$(mktemp)"
trap 'rm -f "$res"' EXIT
payload='{"km":300,"pallets":4,"mode":"refrigerated"}'

# Behaviour: really call as each partner.
set +e
out="$(aws_as_user partner-shipright lambda invoke --function-name rate-quote-engine \
  --cli-binary-format raw-in-base64-out --payload "$payload" "$res" 2>&1)"
rc=$?
set -e
if [ "$rc" -ne 0 ]; then
  echo "partner-shipright is still refused: $(printf '%s' "$out" | tail -1)"
  exit 1
fi
if [ "$(jq -r '.price_eur' "$res")" != "852.0" ]; then
  echo "ShipRight got an unexpected answer: $(head -c 200 "$res")"
  exit 1
fi

# FastLane's contract ended: the grant must be specific to ShipRight.
if aws_as_user partner-fastlane lambda invoke --function-name rate-quote-engine \
     --cli-binary-format raw-in-base64-out --payload "$payload" "$res" >/dev/null 2>&1; then
  echo "partner-fastlane can invoke the function too. The permission is too broad: name partner-shipright as the principal, not everybody."
  exit 1
fi

# Least privilege: invoking is allowed, reading the configuration is not.
if aws_as_user partner-shipright lambda get-function-configuration --function-name rate-quote-engine >/dev/null 2>&1; then
  echo "partner-shipright can do more than invoke (it can read the function's configuration). Grant only lambda:InvokeFunction."
  exit 1
fi

echo "ShipRight can request quotes, FastLane and everyone else are still locked out, and nothing beyond invoke was granted."
