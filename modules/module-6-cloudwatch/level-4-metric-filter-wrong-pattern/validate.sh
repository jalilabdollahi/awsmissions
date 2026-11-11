#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

group="/ledgerbox/payments"
tx="$(aws_local logs describe-metric-filters --log-group-name "$group" --filter-name-prefix payment-failures \
  --query "metricFilters[?filterName=='payment-failures'].metricTransformations[0].[metricName,metricNamespace]" \
  --output text 2>/dev/null || true)"
if [ -z "$tx" ]; then
  echo "The metric filter payment-failures is gone from $group. Fix it; do not delete it."
  exit 1
fi
if [ "$tx" != "$(printf 'PaymentFailures\tLedgerbox')" ]; then
  echo "The filter no longer feeds Ledgerbox/PaymentFailures (it feeds: $tx). Dashboards depend on that exact metric."
  exit 1
fi

total_sum() {
  aws_local cloudwatch get-metric-statistics --namespace Ledgerbox --metric-name PaymentFailures \
    --start-time "$(date -u -v-30M +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '-30 min' +%Y-%m-%dT%H:%M:%SZ)" \
    --end-time "$(date -u -v+5M +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '+5 min' +%Y-%m-%dT%H:%M:%SZ)" \
    --period 3600 --statistics Sum --query 'Datapoints[].Sum' --output text 2>/dev/null \
    | tr '\t' '\n' | awk '{s += $1} END {printf "%d", s}'
}
before="$(total_sum)"

# Three real failures among ordinary traffic. One INFO line even contains the word "error".
stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
now_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
events="$(mktemp)"
trap 'rm -f "$events"' EXIT
STAMP="$stamp" NOW="$now_ms" python3 - > "$events" <<'PY'
import json, os
t, n = os.environ["STAMP"], int(os.environ["NOW"])
lines = [
    "%s INFO gateway authorised order=1" % t,
    "%s ERROR gateway timeout order=2" % t,
    "%s INFO gateway batch finished, 0 errors" % t,
    "%s ERROR card declined order=3" % t,
    "%s INFO gateway authorised order=4" % t,
    "%s ERROR ledger write failed order=5" % t,
    "%s WARN gateway slow response order=6" % t,
]
print(json.dumps([{"timestamp": n + i, "message": m} for i, m in enumerate(lines)]))
PY
aws_local logs put-log-events --log-group-name "$group" --log-stream-name gateway-1 \
  --log-events "file://$events" >/dev/null

moved() { [ "$(( $(total_sum) - before ))" -ge 1 ]; }
if ! wait_for "metric to move" 15 moved; then
  echo "Three ERROR lines were logged but Ledgerbox/PaymentFailures did not move. The filter pattern does not match the lines the service really writes (patterns are case-sensitive)."
  exit 1
fi
sleep 3
delta="$(( $(total_sum) - before ))"
if [ "$delta" -ne 3 ]; then
  echo "Logged 3 ERROR lines among 4 other lines, but the metric counted $delta. The pattern must match failures and nothing else."
  exit 1
fi

echo "Exactly the three ERROR lines were counted in Ledgerbox/PaymentFailures. The chart will move again."
