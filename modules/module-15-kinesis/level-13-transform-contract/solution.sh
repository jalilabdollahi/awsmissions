#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

cat > shaper.py <<'PY'
import base64
import json


def handler(event, context):
    out = []
    for rec in event["records"]:
        try:
            ride = json.loads(base64.b64decode(rec["data"]))
            shaped = {
                "ride_id": ride["ride_id"],
                "fare_usd": ride["fare_cents"] / 100,
                "currency": ride["currency"],
                "pickup": ride["pickup"],
            }
            payload = (json.dumps(shaped) + "\n").encode("utf-8")
            out.append({
                "recordId": rec["recordId"],
                "result": "Ok",
                "data": base64.b64encode(payload).decode("ascii"),
            })
        except (KeyError, ValueError, TypeError):
            out.append({"recordId": rec["recordId"], "result": "ProcessingFailed", "data": rec["data"]})
    return {"records": out}
PY

rm -f shaper.zip
zip -q shaper.zip shaper.py
aws_local lambda update-function-code --function-name ride-event-shaper --zip-file fileb://shaper.zip >/dev/null
wait_for "function update" 30 aws_local lambda wait function-updated --function-name ride-event-shaper
