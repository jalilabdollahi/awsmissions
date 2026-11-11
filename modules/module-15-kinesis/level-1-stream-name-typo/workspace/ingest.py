"""Thermowave: thermostat reading ingest.

Each invocation carries one reading from a thermostat and appends it to the
Kinesis stream named in the STREAM_NAME environment variable.
"""
import json
import os
import time

import boto3

kinesis = boto3.client("kinesis")


def handler(event, context):
    reading = {
        "device_id": event["device_id"],
        "temp_c": event["temp_c"],
        "channel": os.environ.get("FIRMWARE_CHANNEL", "unknown"),
        "ingested_at": int(time.time()),
    }
    response = kinesis.put_record(
        StreamName=os.environ["STREAM_NAME"],
        Data=json.dumps(reading).encode("utf-8"),
        PartitionKey=event["device_id"],
    )
    return {"shard": response["ShardId"], "sequence": response["SequenceNumber"]}
