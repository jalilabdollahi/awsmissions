"""Quasar Fintech: API key audit job.

Reads the current API key from Parameter Store, writes an audit record (a
SHA-256 fingerprint, never the key) to the audit bucket, and reports on a legacy
table scan that the security team wants to see stay blocked.
"""
import hashlib

import boto3
from botocore.exceptions import ClientError

ssm = boto3.client("ssm")
s3 = boto3.client("s3")
ddb = boto3.client("dynamodb")


def audit(event, context):
    key = ssm.get_parameter(Name="/quasar/api-key", WithDecryption=True)["Parameter"]["Value"]
    fingerprint = hashlib.sha256(key.encode()).hexdigest()[:16]
    s3.put_object(Bucket="quasar-audit-records", Key=f"fingerprints/{event['run']}.txt", Body=fingerprint.encode())

    try:
        ddb.list_tables()
        legacy = "reachable"
    except ClientError:
        legacy = "blocked"
    return {"fingerprint": fingerprint, "legacy_tables": legacy}
