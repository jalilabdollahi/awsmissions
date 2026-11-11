"""Tidewater Insurance: claim receipt archiver.

Writes the text of a claim receipt to the receipts bucket. Ops can pass a
`bucket` override in the event when they need to re-route a batch.
"""
import os

import boto3

s3 = boto3.client("s3")


def archive(event, context):
    bucket = event.get("bucket") or os.environ["RECEIPT_BUCKET"]
    key = f"receipts/{event['claim_id']}.txt"
    s3.put_object(Bucket=bucket, Key=key, Body=event["text"].encode("utf-8"))
    return {"status": "archived", "bucket": bucket, "key": key}
