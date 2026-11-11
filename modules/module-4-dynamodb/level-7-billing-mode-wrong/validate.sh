#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

T=ticketflash-holds
if ! aws_local dynamodb describe-table --table-name "$T" >/dev/null 2>&1; then
  echo "$T is gone. It must be switched in place, not dropped."
  exit 1
fi

mode="$(aws_local dynamodb describe-table --table-name "$T" \
  --query 'Table.BillingModeSummary.BillingMode' --output text)"
if [ "$mode" != "PAY_PER_REQUEST" ]; then
  [ "$mode" = "None" ] && mode=PROVISIONED
  echo "The table is still billed in $mode mode, so you are still guessing a capacity number."
  exit 1
fi

n="$(aws_local dynamodb scan --table-name "$T" --select COUNT --query Count --output text)"
if [ "$n" != "6" ]; then
  echo "Expected the 6 seat holds to survive; found $n."
  exit 1
fi

seats="$(aws_local dynamodb query --table-name "$T" --index-name event-index \
  --key-condition-expression 'eventId = :e' --expression-attribute-values '{":e":{"S":"ev-roxy"}}' \
  --select COUNT --query Count --output text 2>&1 || true)"
if [ "$seats" != "3" ]; then
  echo "event-index no longer returns the 3 holds of ev-roxy (got: $seats). The index must still work after the switch."
  exit 1
fi

left="$(aws_local application-autoscaling describe-scalable-targets --service-namespace dynamodb \
  --resource-ids "table/$T" --query 'length(ScalableTargets)' --output text)"
if [ "$left" != "0" ]; then
  echo "An auto scaling target is still registered for $T. On-demand tables ignore it, but it is dead configuration that will confuse the next engineer."
  exit 1
fi

if ! aws_local dynamodb put-item --table-name "$T" \
  --item '{"holdId":{"S":"h-check"},"eventId":{"S":"ev-roxy"},"seat":{"S":"Z99"}}' >/dev/null 2>&1; then
  echo "A write after the switch failed."
  exit 1
fi
aws_local dynamodb delete-item --table-name "$T" --key '{"holdId":{"S":"h-check"}}' >/dev/null
echo "ticketflash-holds is on-demand, data and index intact, scaling leftovers removed."
