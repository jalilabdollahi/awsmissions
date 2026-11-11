"""Sablecart nightly swipe audit.

Reads the single shard of the card-swipes stream and reports what is there.
"""
import json

import boto3

kinesis = boto3.client("kinesis")
STREAM = "card-swipes"
SHARD = "shardId-000000000000"


def handler(event, context):
    iterator = kinesis.get_shard_iterator(
        StreamName=STREAM,
        ShardId=SHARD,
        ShardIteratorType="LATEST",
    )["ShardIterator"]

    swipes = []
    while iterator:
        page = kinesis.get_records(ShardIterator=iterator, Limit=100)
        for record in page["Records"]:
            swipes.append(json.loads(record["Data"]))
        if page["MillisBehindLatest"] == 0:
            break
        iterator = page.get("NextShardIterator")

    return {
        "audited": len(swipes),
        "swipe_ids": [s["swipe_id"] for s in swipes],
        "total_cents": sum(s["cents"] for s in swipes),
    }
