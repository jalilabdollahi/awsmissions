#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

python3 - "$stage" <<'PY'
import sys, zipfile

BILLING = '''PLANS = {"C-5521": ("unlimited-5g", 42.5), "C-1002": ("saver-4g", 9.0)}

def handler(event, context):
    plan, balance = PLANS.get(event["customerId"], ("prepaid", 0.0))
    return {"plan": plan, "balance": balance}
'''
USAGE = '''USED = {"C-5521": 18.4, "C-1002": 2.1}

def handler(event, context):
    return {"gbUsed": USED.get(event["customerId"], 0.0), "period": "current"}
'''
for name, body in (("billing", BILLING), ("usage", USAGE)):
    with zipfile.ZipFile("%s/%s.zip" % (sys.argv[1], name), "w") as z:
        z.writestr(name + ".py", body)
PY

aws_local sqs create-queue --queue-name orbit-profile-cards >/dev/null

aws_local iam create-role --role-name orbit-lambda-exec \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name orbit-fetch-billing --runtime python3.12 --handler billing.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/orbit-lambda-exec" --zip-file "fileb://$stage/billing.zip" >/dev/null
aws_local lambda create-function --function-name orbit-fetch-usage --runtime python3.12 --handler usage.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/orbit-lambda-exec" --zip-file "fileb://$stage/usage.zip" >/dev/null

aws_local iam create-role --role-name orbit-profile-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name orbit-profile-role --policy-name profile \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"lambda:InvokeFunction\",\"Resource\":[\"arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:orbit-fetch-billing\",\"arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:orbit-fetch-usage\"]},{\"Effect\":\"Allow\",\"Action\":\"sqs:SendMessage\",\"Resource\":\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:orbit-profile-cards\"}]}"

aws_local stepfunctions create-state-machine --name orbit-profile-card \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/orbit-profile-role" \
  --definition "file://$MISSION_DIR/workspace/profile-card.asl.json" >/dev/null

for fn in orbit-fetch-billing orbit-fetch-usage; do
  aws_local lambda invoke --function-name "$fn" --cli-binary-format raw-in-base64-out \
    --payload '{"customerId":"warm"}' /dev/null >/dev/null
done

echo "orbit-profile-card is live; the publish step fails after the parallel lookups."
