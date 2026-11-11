"""Maple Treasury: currency conversion lookup.

Reads the latest rate for a currency pair from the rates table and converts an
amount. Configuration comes from environment variables so the same package can
run in staging and production:

  RATES_TABLE   DynamoDB table holding the rates (required)
  FX_PRECISION  decimal places in the answer (optional, defaults to 2)
"""
import os
from decimal import Decimal, ROUND_HALF_UP

import boto3

dynamodb = boto3.client("dynamodb")


def convert(event, context):
    table = os.environ["RATES_TABLE"]
    places = int(os.environ.get("FX_PRECISION", "2"))

    item = dynamodb.get_item(TableName=table, Key={"pair": {"S": event["pair"]}}).get("Item")
    if item is None:
        return {"error": f"no rate for {event['pair']}"}

    rate = Decimal(item["rate"]["N"])
    quantum = Decimal(1).scaleb(-places)
    converted = (Decimal(str(event["amount"])) * rate).quantize(quantum, rounding=ROUND_HALF_UP)
    return {"pair": event["pair"], "rate": str(rate), "converted": str(converted)}
