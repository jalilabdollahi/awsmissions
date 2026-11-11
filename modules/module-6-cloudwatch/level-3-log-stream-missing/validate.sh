#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

group="/harvest/sensors"
streams="$(aws_local logs describe-log-streams --log-group-name "$group" \
  --query 'logStreams[].logStreamName' --output text 2>/dev/null || true)"
if [ -z "$streams" ]; then
  echo "The log group $group is missing or empty. Gateways 01 to 06 need it; only gateway 07's stream is the problem."
  exit 1
fi
for n in 01 02 03 04 05 06; do
  case " $(printf '%s' "$streams" | tr '\t' ' ') " in
    *" field-gateway-$n "*) ;;
    *) echo "The stream field-gateway-$n has disappeared. Leave the existing streams alone."; exit 1 ;;
  esac
done

# Gateway 07 now tries to ship a reading, exactly as its agent would.
reading="greenhouse-3 humidity=71 temp=22.4 run=$(date +%s)$$"
now_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
events="$(mktemp)"
trap 'rm -f "$events"' EXIT
printf '[{"timestamp":%s,"message":"%s"}]' "$now_ms" "$reading" > "$events"
if ! out="$(aws_local logs put-log-events --log-group-name "$group" --log-stream-name field-gateway-07 \
  --log-events "file://$events" 2>&1)"; then
  echo "Gateway 07 still cannot write: $(printf '%s' "$out" | tail -1)"
  exit 1
fi

shipped() {
  aws_local logs get-log-events --log-group-name "$group" --log-stream-name field-gateway-07 \
    --query 'events[].message' --output text 2>/dev/null | grep -qF "$reading"
}
if ! wait_for "reading to be readable" 6 shipped; then
  echo "The write succeeded, but the reading cannot be read back from field-gateway-07."
  exit 1
fi

echo "Gateway 07's reading is stored in /harvest/sensors/field-gateway-07. The other six streams are intact."
