"""Lumen Photo Co: thumbnail queue scanner.

Lists the raw uploads that still need a thumbnail so the render farm can pick
them up. Runs on a schedule; it only needs read access to one prefix.
"""
import boto3

s3 = boto3.client("s3")


def scan(event, context):
    listing = s3.list_objects_v2(Bucket="lumen-thumb-source", Prefix="raw/")
    pending = sorted(obj["Key"] for obj in listing.get("Contents", []))
    return {"pending": pending, "count": len(pending)}
