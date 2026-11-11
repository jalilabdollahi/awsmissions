"""Quillbox order event publisher.

Event shape: {"events": [{"order_id": "...", "customer_id": "...", "type": "created|paid|shipped"}]}
All events of a call go to Kinesis in a single PutRecords request.
"""
import json
import time

import boto3

kinesis = boto3.client("kinesis")
STREAM = "order-events"


def handler(event, context):
    records = []
    for item in event["events"]:
        body = dict(item, published_at=int(time.time() * 1000))
        records.append({
            "Data": json.dumps(body).encode("utf-8"),
            "PartitionKey": "order-service",
        })

    response = kinesis.put_records(StreamName=STREAM, Records=records)
    return {"sent": len(records), "failed": response["FailedRecordCount"]}
