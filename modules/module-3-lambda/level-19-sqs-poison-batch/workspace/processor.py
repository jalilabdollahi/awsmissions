"""Kestrel Ticketing: ticket event processor.

Consumes batches of ticket events from SQS and records each ticket in the
ledger. The ledger counts how many times a ticket was processed; anything
above 1 means a customer was handled twice.
"""
import json

import boto3

ddb = boto3.client("dynamodb")


def handler(event, context):
    processed = []
    for record in event["Records"]:
        ticket = json.loads(record["body"])
        ddb.update_item(
            TableName="ticket-ledger",
            Key={"ticket_id": {"S": ticket["ticket_id"]}},
            UpdateExpression="ADD attempts :one",
            ExpressionAttributeValues={":one": {"N": "1"}},
        )
        processed.append(ticket["ticket_id"])
    return {"processed": processed}
