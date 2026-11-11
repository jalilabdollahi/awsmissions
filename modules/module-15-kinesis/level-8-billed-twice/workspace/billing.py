"""Brightline billing: resume reading usage-events from the saved checkpoint.

The checkpoint parameter holds the sequence number of the LAST event that was
billed successfully. Each run bills what came after it.
"""
import json

import boto3

kinesis = boto3.client("kinesis")
ssm = boto3.client("ssm")
ddb = boto3.client("dynamodb")

STREAM = "usage-events"
SHARD = "shardId-000000000000"
CHECKPOINT = "/brightline/billing/checkpoint"
TABLE = "invoice-lines"


def handler(event, context):
    checkpoint = ssm.get_parameter(Name=CHECKPOINT)["Parameter"]["Value"]
    iterator = kinesis.get_shard_iterator(
        StreamName=STREAM,
        ShardId=SHARD,
        ShardIteratorType="AT_SEQUENCE_NUMBER",
        StartingSequenceNumber=checkpoint,
    )["ShardIterator"]

    billed = []
    last_sequence = checkpoint
    while iterator:
        page = kinesis.get_records(ShardIterator=iterator, Limit=100)
        for record in page["Records"]:
            usage = json.loads(record["Data"])
            ddb.update_item(
                TableName=TABLE,
                Key={"event_id": {"S": usage["event_id"]}},
                UpdateExpression="ADD times_billed :one",
                ExpressionAttributeValues={":one": {"N": "1"}},
            )
            billed.append(usage["event_id"])
            last_sequence = record["SequenceNumber"]
        if page["MillisBehindLatest"] == 0:
            break
        iterator = page.get("NextShardIterator")

    ssm.put_parameter(Name=CHECKPOINT, Value=last_sequence, Type="String", Overwrite=True)
    return {"billed": billed, "checkpoint": last_sequence}
