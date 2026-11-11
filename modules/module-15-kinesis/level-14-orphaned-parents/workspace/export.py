"""Ledgerline nightly export.

Returns every entry still retained in the ledger-entries stream. Entries have
the form {"account": "acct-1", "seq": 3, "cents": 1250}; for each account the
export must list them in write order (increasing seq).
"""
import json

import boto3

kinesis = boto3.client("kinesis")
STREAM = "ledger-entries"

# The stream has a single shard.
SHARD_IDS = ["shardId-000000000000"]


def read_shard(shard_id):
    iterator = kinesis.get_shard_iterator(
        StreamName=STREAM,
        ShardId=shard_id,
        ShardIteratorType="TRIM_HORIZON",
    )["ShardIterator"]
    entries = []
    while iterator:
        page = kinesis.get_records(ShardIterator=iterator, Limit=500)
        entries.extend(json.loads(r["Data"]) for r in page["Records"])
        if not page["Records"] and page["MillisBehindLatest"] == 0:
            break
        iterator = page.get("NextShardIterator")
    return entries


def handler(event, context):
    entries = []
    for shard_id in SHARD_IDS:
        entries.extend(read_shard(shard_id))
    return {"count": len(entries), "entries": entries}
