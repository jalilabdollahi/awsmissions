"""Helixia Labs: lab result indexer.

For every new result file the S3 event is turned into one row of the
lab-result-index table, which the clinician portal searches.
"""
from urllib.parse import unquote_plus

import boto3

table = boto3.client("dynamodb")


def index(event, context):
    indexed = []
    for record in event["Records"]:
        key = unquote_plus(record["s3"]["object"]["key"])
        table.put_item(
            TableName="lab-result-index",
            Item={
                "object_key": {"S": key},
                "bucket": {"S": record["s3"]["bucket"]["name"]},
                "size": {"N": str(record["s3"]["object"].get("size", 0))},
            },
        )
        indexed.append(key)
    return {"indexed": indexed}
