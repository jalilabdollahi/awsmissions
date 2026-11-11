"""SwiftCab ride event shaper: Firehose transformation function.

Input event:  {"records": [{"recordId": "...", "data": "<base64 of the raw ride JSON>"}]}
Raw ride:     {"ride_id", "fare_cents", "currency", "pickup": {"lat", "lon"}, "rider_phone"}
"""
import base64
import json
import uuid


def handler(event, context):
    out = []
    for rec in event["records"]:
        ride = json.loads(base64.b64decode(rec["data"]))
        shaped = {
            "ride_id": ride["ride_id"],
            "fare_usd": ride["fare_cents"] / 100,
            "currency": ride["currency"],
            "pickup": ride["pickup"],
        }
        out.append({
            "recordId": str(uuid.uuid4()),
            "result": "Success",
            "data": json.dumps(shaped),
        })
    return {"records": out}
