#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local logs create-log-group --log-group-name /rivergate/payments
aws_local logs create-log-stream --log-group-name /rivergate/payments --log-stream-name api-1

now_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
events="$(mktemp)"
NOW="$now_ms" python3 - > "$events" <<'PY'
import json, os
n = int(os.environ["NOW"])
rows = [
    {"level": "INFO", "code": "OK", "order": "A-1"},
    {"level": "ERROR", "code": "CARD_DECLINED", "order": "A-2"},
    {"level": "INFO", "code": "OK", "order": "A-3"},
    {"level": "ERROR", "code": "GATEWAY_TIMEOUT", "order": "A-4"},
    {"level": "WARN", "code": "SLOW", "order": "A-5"},
    {"level": "ERROR", "code": "LEDGER_WRITE", "order": "A-6"},
    {"level": "INFO", "code": "OK", "order": "A-7"},
]
print(json.dumps([{"timestamp": n + i, "message": json.dumps(r)} for i, r in enumerate(rows)]))
PY
aws_local logs put-log-events --log-group-name /rivergate/payments --log-stream-name api-1 \
  --log-events "file://$events" >/dev/null
rm -f "$events"

aws_local cloudwatch put-dashboard --dashboard-name rivergate-payments \
  --dashboard-body "file://$MISSION_DIR/workspace/dashboard.json" >/dev/null

echo "Dashboard rivergate-payments is live; its error table is empty."
