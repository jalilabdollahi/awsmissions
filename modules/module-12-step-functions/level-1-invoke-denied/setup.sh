#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

python3 - "$stage" <<'PY'
import sys, zipfile

LABEL = '''import json

def handler(event, context):
    sid = event["shipmentId"]
    return {"shipmentId": sid, "label": "LBL-" + sid.split("-")[-1], "printer": "dock-3"}
'''
CUSTOMS = '''def handler(event, context):
    return {"form": "CN22", "shipmentId": event.get("shipmentId")}
'''
for name, body in (("label", LABEL), ("customs", CUSTOMS)):
    with zipfile.ZipFile(sys.argv[1] + "/" + name + ".zip", "w") as z:
        z.writestr(name + ".py", body)
PY

aws_local iam create-role --role-name tidewater-label-flow-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name tidewater-label-flow-role --policy-name flow-permissions \
  --policy-document "file://$MISSION_DIR/workspace/role-policy.json"

aws_local iam create-role --role-name tidewater-fn-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

aws_local lambda create-function --function-name print-shipping-label --runtime python3.12 \
  --handler label.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/tidewater-fn-role" \
  --zip-file "fileb://$stage/label.zip" >/dev/null
aws_local lambda create-function --function-name print-customs-form --runtime python3.12 \
  --handler customs.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/tidewater-fn-role" \
  --zip-file "fileb://$stage/customs.zip" >/dev/null

aws_local stepfunctions create-state-machine --name tidewater-label-flow \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/tidewater-label-flow-role" \
  --definition "file://$MISSION_DIR/workspace/label-flow.asl.json" >/dev/null

echo "tidewater-label-flow is deployed. Every execution currently fails on its first state."
