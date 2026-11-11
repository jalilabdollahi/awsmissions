#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

STREAM_ARN="arn:aws:kinesis:us-east-1:${ACCOUNT_ID}:stream/trade-ticks"

scorer="$(aws_local lambda list-event-source-mappings --function-name risk-scorer --output json | jq -c '.EventSourceMappings')"
n="$(printf '%s' "$scorer" | jq 'length')"
if [ "$n" = "0" ]; then
  echo "risk-scorer is not connected to any stream. It must keep scoring trades."
  exit 1
fi
if printf '%s' "$scorer" | jq -e 'any(.[]; .EventSourceArn == "'"$STREAM_ARN"'")' >/dev/null; then
  echo "risk-scorer still has a mapping directly on the stream, so it still shares the stream's read throughput with the other consumers."
  exit 1
fi
if [ "$n" != "1" ]; then
  echo "risk-scorer has $n event source mappings. Trades would be scored more than once."
  exit 1
fi
arn="$(printf '%s' "$scorer" | jq -r '.[0].EventSourceArn')"
case "$arn" in
  "$STREAM_ARN"/consumer/*) ;;
  *) echo "risk-scorer reads from $arn, which is not a dedicated consumer of trade-ticks."; exit 1 ;;
esac
if [ "$(printf '%s' "$scorer" | jq -r '.[0].State')" != "Enabled" ]; then
  echo "The risk-scorer mapping is not enabled yet (state: $(printf '%s' "$scorer" | jq -r '.[0].State'))."
  exit 1
fi
consumer_status="$(aws_local kinesis describe-stream-consumer --consumer-arn "$arn" --query 'ConsumerDescription.ConsumerStatus' --output text 2>/dev/null || true)"
if [ "$consumer_status" != "ACTIVE" ]; then
  echo "The consumer behind risk-scorer's mapping is not ACTIVE ('$consumer_status')."
  exit 1
fi
if [ "$(aws_local lambda list-event-source-mappings --function-name ledger-writer --query 'length(EventSourceMappings)' --output text)" != "1" ]; then
  echo "ledger-writer must keep exactly its existing mapping; it was not supposed to change."
  exit 1
fi

# Behaviour: new trades are booked once by the ledger and scored exactly once.
run="$(date +%s)"
for n in 1 2 3 4; do
  aws_local kinesis put-record --stream-name trade-ticks --partition-key "sym-$n" \
    --data "$(printf '{"trade_id":"tt-%s-%s","qty":%s}' "$run" "$n" "$((n * 10))" | base64)" >/dev/null
done

count() {
  aws_local dynamodb get-item --table-name "$1" --key "{\"trade_id\":{\"S\":\"tt-$run-$2\"}}" \
    --query "Item.$3.N" --output text 2>/dev/null || true
}
done_all=""
i=0
while [ "$i" -lt 30 ]; do
  all=1
  for n in 1 2 3 4; do
    [ "$(count risk-scores "$n" scored)" = "None" ] || [ -z "$(count risk-scores "$n" scored)" ] && all=""
    [ "$(count trade-ledger "$n" booked)" = "None" ] || [ -z "$(count trade-ledger "$n" booked)" ] && all=""
  done
  if [ -n "$all" ]; then done_all=1; break; fi
  sleep 2
  i=$((i + 1))
done
if [ -z "$done_all" ]; then
  echo "New trades were not scored and booked within about 60 seconds. Check that both mappings deliver."
  exit 1
fi
sleep 8
for n in 1 2 3 4; do
  s="$(count risk-scores "$n" scored)"; b="$(count trade-ledger "$n" booked)"
  if [ "$s" != "1" ]; then
    echo "Trade $n was scored $s times, expected exactly once. Two consumers are delivering the same trades to risk-scorer."
    exit 1
  fi
  if [ "$b" != "1" ]; then
    echo "Trade $n was booked $b times by ledger-writer, expected once."
    exit 1
  fi
done

echo "risk-scorer now reads through its own consumer; four new trades were scored exactly once and the ledger kept working."
