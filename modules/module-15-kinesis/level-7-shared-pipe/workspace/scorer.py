"""Rivermill risk scorer: scores every trade it is handed.

The risk desk counts how many times a trade was scored; anything other than 1
means a double count or a miss.
"""
import base64
import json

import boto3

ddb = boto3.client("dynamodb")


def handler(event, context):
    for record in event["Records"]:
        trade = json.loads(base64.b64decode(record["kinesis"]["data"]))
        ddb.update_item(
            TableName="risk-scores",
            Key={"trade_id": {"S": trade["trade_id"]}},
            UpdateExpression="ADD scored :one",
            ExpressionAttributeValues={":one": {"N": "1"}},
        )
