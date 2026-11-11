#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

res="$(mktemp)"; hdr="$(mktemp)"
trap 'rm -f "$res" "$hdr"' EXIT

stg="$(aws_local lambda get-alias --function-name tax-calculator --name staging --query FunctionVersion --output text 2>/dev/null || true)"
if [ "$stg" != "3" ]; then
  echo "The staging alias now points at '${stg:-nothing}'. It must keep trialling version 3; only prod should change."
  exit 1
fi

target="$(aws_local lambda get-alias --function-name tax-calculator --name prod --query FunctionVersion --output text 2>/dev/null || true)"
if [ -z "$target" ]; then
  echo "The prod alias is gone. Checkout calls tax-calculator:prod, so keep the alias and fix where it points."
  exit 1
fi
if [ "$target" = '$LATEST' ]; then
  echo 'Prod points at $LATEST, which is whatever was uploaded last (here an unapproved experiment). Aliases exist to pin a published version.'
  exit 1
fi

# What checkout does: call the alias.
if ! aws_local lambda invoke --function-name tax-calculator:prod --cli-binary-format raw-in-base64-out \
     --payload '{"amount":123.45,"category":"books"}' "$res" >"$hdr" 2>&1; then
  echo "Checkout's call to tax-calculator:prod fails: $(tail -1 "$hdr")"
  exit 1
fi
if jq -e '.FunctionError' "$hdr" >/dev/null 2>&1; then
  echo "The alias resolves but the function fails: $(head -c 200 "$res")"
  exit 1
fi
calc="$(jq -r '.calc' "$res")"
if [ "$calc" != "2024-rates" ]; then
  echo "Prod answers with '$calc' (version $target). That is not the release finance approved; check the version descriptions."
  exit 1
fi
if [ "$(jq -r '.tax' "$res")" != "8.64" ]; then
  echo "Unexpected tax amount: $(head -c 100 "$res")"
  exit 1
fi

echo "tax-calculator:prod serves version $target (2024 rates). Staging still trials version 3."
