#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

python3 - "$stage" <<'PY'
import sys, zipfile

SOURCE = '''import time

CATALOGUE = {"FG-ROSE-12": 40, "FG-TERRA-30": 7, "FG-SHED-01": 2}


class StockLocked(Exception):
    """The warehouse scanner holds the stock table during a sync."""


class UnknownSku(Exception):
    """Not in the catalogue: retrying will never help."""


def handler(event, context):
    sku = event["sku"]
    if sku not in CATALOGUE:
        raise UnknownSku("no such SKU: " + sku)
    if time.time() < event.get("lockedUntil", 0):
        raise StockLocked("stock table locked by scanner sync")
    return {"reservationId": "RSV-" + sku, "sku": sku, "qty": event["qty"]}
'''
with zipfile.ZipFile(sys.argv[1] + "/reserve.zip", "w") as z:
    z.writestr("reserve.py", SOURCE)
PY

aws_local iam create-role --role-name fernhill-lambda-exec \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name fernhill-reserve-stock --runtime python3.12 \
  --handler reserve.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/fernhill-lambda-exec" \
  --zip-file "fileb://$stage/reserve.zip" >/dev/null

aws_local iam create-role --role-name fernhill-reserve-flow-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name fernhill-reserve-flow-role --policy-name invoke-reserve \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"lambda:InvokeFunction\",\"Resource\":\"arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:fernhill-reserve-stock\"}]}"

aws_local stepfunctions create-state-machine --name fernhill-reserve \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/fernhill-reserve-flow-role" \
  --definition "file://$MISSION_DIR/workspace/reserve.asl.json" >/dev/null

# Warm the function so the first execution is not slowed by a cold start.
aws_local lambda invoke --function-name fernhill-reserve-stock --cli-binary-format raw-in-base64-out \
  --payload '{"sku":"FG-ROSE-12","qty":1}' /dev/null >/dev/null

echo "fernhill-reserve is live; orders placed during a scanner sync still fail."
