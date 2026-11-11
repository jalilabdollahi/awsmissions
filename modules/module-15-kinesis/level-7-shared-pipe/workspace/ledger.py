"""Rivermill ledger writer: books every trade it is handed."""
import base64
import json

import boto3

ddb = boto3.client("dynamodb")


def handler(event, context):
    for record in event["Records"]:
        trade = json.loads(base64.b64decode(record["kinesis"]["data"]))
        ddb.update_item(
            TableName="trade-ledger",
            Key={"trade_id": {"S": trade["trade_id"]}},
            UpdateExpression="ADD booked :one",
            ExpressionAttributeValues={":one": {"N": "1"}},
        )
