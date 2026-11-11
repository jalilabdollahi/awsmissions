#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

enc() { printf '%s' "$1" | base64; }
good1='{"ride_id":"r-5001","fare_cents":1875,"currency":"USD","pickup":{"lat":40.71,"lon":-74.0},"rider_phone":"+15550100"}'
good2='{"ride_id":"r-5002","fare_cents":420,"currency":"USD","pickup":{"lat":40.73,"lon":-73.99},"rider_phone":"+15550101"}'
bad='{"ride_id":"r-5003","currency":"USD","pickup":{"lat":40.7,"lon":-74.1},"rider_phone":"+15550102"}'

# Gate 1: the Firehose transformation contract, exercised directly (fast, precise feedback).
out="$(mktemp)"
trap 'rm -f "$out" "$out.meta" "$out.in" "$out.obj"' EXIT
call_shaper() {
  printf '%s' "$1" > "$out.in"
  aws_local lambda invoke --function-name ride-event-shaper --cli-binary-format raw-in-base64-out \
    --payload "file://$out.in" "$out" > "$out.meta" 2>&1 || true
}

# 1a: a batch of healthy events.
call_shaper "$(jq -cn --arg a "$(enc "$good1")" --arg b "$(enc "$good2")" \
  '{records:[{recordId:"id-1",data:$a},{recordId:"id-2",data:$b}]}')"
if grep -q FunctionError "$out.meta"; then
  echo "ride-event-shaper crashed on healthy events: $(jq -r '.errorMessage // "unknown"' "$out")"
  exit 1
fi
if [ "$(jq '.records | length' "$out" 2>/dev/null || echo 0)" != "2" ]; then
  echo "The function must return exactly one output record per input record (got $(jq '.records | length' "$out" 2>/dev/null || echo none) for 2)."
  exit 1
fi
for id in id-1 id-2; do
  if ! jq -e --arg id "$id" '[.records[].recordId] | index($id) != null' "$out" >/dev/null; then
    echo "Output is missing recordId '$id'. Firehose matches results to inputs by recordId, so each must be returned unchanged."
    exit 1
  fi
done
res() { jq -r --arg id "$1" '.records[] | select(.recordId == $id) | .result' "$out"; }
for id in id-1 id-2; do
  if [ "$(res "$id")" != "Ok" ]; then
    echo "A valid event came back with result '$(res "$id")'. The accepted values are Ok, Dropped and ProcessingFailed."
    exit 1
  fi
done
decoded="$(jq -r '.records[] | select(.recordId == "id-1") | .data' "$out" | jq -R -r '@base64d' 2>/dev/null || true)"
if [ -z "$decoded" ]; then
  echo "The data field of a result must be base64-encoded; it did not decode."
  exit 1
fi
if [ "$(jq -r '.records[] | select(.recordId == "id-1") | .data' "$out" | jq -R -r '@base64d | endswith("\n")')" != "true" ]; then
  echo "Each transformed record must end with a newline: Firehose concatenates records, so without it several events end up on one line in the lake."
  exit 1
fi
shaped="$(printf '%s' "$decoded" | jq -c '.' 2>/dev/null || true)"
if [ -z "$shaped" ] || [ "$(printf '%s' "$shaped" | jq -r '.ride_id + "|" + (.fare_usd|tostring) + "|" + .currency')" != "r-5001|18.75|USD" ] \
   || [ "$(printf '%s' "$shaped" | jq 'has("rider_phone")')" != "false" ] || [ "$(printf '%s' "$shaped" | jq '.pickup.lat')" != "40.71" ]; then
  echo "A transformed record must be {ride_id, fare_usd, currency, pickup} with the fare in dollars and without rider_phone. Got: $decoded"
  exit 1
fi

# 1b: a batch where one event has no fare.
call_shaper "$(jq -cn --arg a "$(enc "$good1")" --arg c "$(enc "$bad")" \
  '{records:[{recordId:"id-1",data:$a},{recordId:"id-3",data:$c}]}')"
if grep -q FunctionError "$out.meta"; then
  echo "ride-event-shaper crashes on a batch that contains an event without a fare: $(jq -r '.errorMessage // "unknown"' "$out"). One bad event must be reported, not take the whole batch down."
  exit 1
fi
if [ "$(res id-1)" != "Ok" ]; then
  echo "A valid event next to a bad one came back as '$(res id-1)'. Bad events must not affect their neighbours."
  exit 1
fi
if [ "$(res id-3)" != "ProcessingFailed" ]; then
  echo "The event without a fare came back as '$(res id-3)'; it should be marked ProcessingFailed so Firehose routes it to the error prefix."
  exit 1
fi

# Gate 2: end to end through Firehose into the lake.
run="$(date +%s)"
mk() { printf '{"ride_id":"%s","fare_cents":%s,"currency":"USD","pickup":{"lat":1.5,"lon":2.5},"rider_phone":"+1555"}' "$1" "$2"; }
nofare="$(jq -cn --arg id "nofare-$run" '{ride_id:$id,currency:"USD",pickup:{lat:1,lon:2}}')"
ok1="$(mk "ok1-$run" 1000)"; ok2="$(mk "ok2-$run" 2500)"
batch="$(jq -cn --arg a "$(enc "$ok1")" --arg b "$(enc "$ok2")" --arg c "$(enc "$nofare")" \
  '[{Data:$a},{Data:$b},{Data:$c}]')"
aws_local firehose put-record-batch --delivery-stream-name ride-events-to-lake --records "$batch" >/dev/null

lines=""; rejects=""
i=0
while [ "$i" -lt 18 ]; do
  lines=""; rejects=""
  for key in $(aws_local s3api list-objects-v2 --bucket swiftcab-lake --query 'Contents[].Key' --output text 2>/dev/null | tr '\t' '\n' | grep -v '^None$' || true); do
    aws_local s3api get-object --bucket swiftcab-lake --key "$key" "$out.obj" >/dev/null 2>&1 || continue
    case "$key" in
      rides/*) lines="$lines
$(cat "$out.obj")" ;;
      ride-rejects/*) rejects="$rejects
$(cat "$out.obj")" ;;
    esac
  done
  ok_n="$(printf '%s\n' "$lines" | grep -c -e "ok1-$run" -e "ok2-$run" || true)"
  rej_n="$(printf '%s\n' "$rejects" | grep -c . || true)"
  [ "$ok_n" -ge 2 ] && [ "$rej_n" -ge 1 ] && break
  sleep 2
  i=$((i + 1))
done

mine="$(printf '%s\n' "$lines" | grep -e "ok1-$run" -e "ok2-$run" || true)"
if [ "$(printf '%s\n' "$mine" | grep -c .)" != "2" ]; then
  echo "The two valid test events did not arrive as two separate lines under rides/ (found $(printf '%s\n' "$mine" | grep -c .) matching line(s))."
  exit 1
fi
if printf '%s\n' "$lines" | grep -q "nofare-$run"; then
  echo "The event without a fare was loaded into rides/. It should be rejected."
  exit 1
fi
if printf '%s\n' "$mine" | grep -q rider_phone; then
  echo "Personal data (rider_phone) reached the lake."
  exit 1
fi
bad_kept="0"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  raw="$(printf '%s' "$line" | jq -r '.rawData // empty' 2>/dev/null | jq -R -r '@base64d' 2>/dev/null || true)"
  case "$raw" in
    *"nofare-$run"*) bad_kept=1 ;;
    *"ok1-$run"*|*"ok2-$run"*) echo "A valid event was rejected into ride-rejects/."; exit 1 ;;
  esac
done <<EOF2
$rejects
EOF2
if [ "$bad_kept" != "1" ]; then
  echo "The event without a fare did not show up in ride-rejects/ within the time budget."
  exit 1
fi

echo "Valid rides arrive in the lake one JSON line each, and the ride without a fare is isolated in ride-rejects/."
