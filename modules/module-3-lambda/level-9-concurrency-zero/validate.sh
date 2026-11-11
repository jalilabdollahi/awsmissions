#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

res="$(mktemp)"; hdr="$(mktemp)"
trap 'rm -f "$res" "$hdr"' EXIT

if ! aws_local lambda invoke --function-name coupon-redeemer --cli-binary-format raw-in-base64-out \
     --payload '{"code":"BRT-15-K7Q2ZD","cart_total":80}' "$res" >"$hdr" 2>&1; then
  echo "Checkout still cannot redeem coupons: $(tail -1 "$hdr")"
  if aws_local lambda get-function-concurrency --function-name coupon-redeemer --query ReservedConcurrentExecutions --output text 2>/dev/null | grep -qx 0; then
    echo "This function currently has no execution slots reserved for it."
  fi
  exit 1
fi
if [ "$(jq -r '.new_total // empty' "$res")" != "68.0" ]; then
  echo "Function answered, but not as expected: $(head -c 200 "$res")"
  exit 1
fi

reserved="$(aws_local lambda get-function-concurrency --function-name coupon-redeemer --query ReservedConcurrentExecutions --output text 2>/dev/null || true)"
if [ -z "$reserved" ] || [ "$reserved" = "None" ]; then
  echo "Redemptions work, but nothing limits the function any more. The post-mortem requires a cap so a retry storm cannot drain the 20-connection database budget."
  exit 1
fi
if [ "$reserved" -gt 20 ]; then
  echo "The cap is $reserved, above the 20 concurrent connections the database can serve."
  exit 1
fi

echo "coupon-redeemer works and is capped at $reserved concurrent executions."
