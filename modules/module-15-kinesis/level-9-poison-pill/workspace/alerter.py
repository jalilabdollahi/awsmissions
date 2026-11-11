"""Marlow Health vitals alerter.

Invoked by a Kinesis event source mapping. A reading that is not valid JSON
makes the function raise, exactly as the on-call engineers saw this morning.
"""
import base64
import json

import boto3

ddb = boto3.client("dynamodb")


def handler(event, context):
    for record in event["Records"]:
        raw = base64.b64decode(record["kinesis"]["data"])
        reading = json.loads(raw)
        ddb.put_item(
            TableName="vitals-processed",
            Item={
                "reading_id": {"S": reading["reading_id"]},
                "spo2": {"N": str(reading["spo2"])},
            },
        )
    return {"records": len(event["Records"])}
