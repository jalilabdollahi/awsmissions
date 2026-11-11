#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

python3 - "$stage" <<'PY'
import sys, zipfile

CONVERT = '''RATES = {"EUR": 1.0, "USD": 0.9, "GBP": 1.2}

def handler(event, context):
    rate = RATES[event["currency"]]
    return {"amountEur": round(event["amount"] * rate, 2), "rate": rate}
'''
with zipfile.ZipFile(sys.argv[1] + "/convert.zip", "w") as z:
    z.writestr("convert.py", CONVERT)

V1 = '''{
  "StartAt": "ConvertToEur",
  "States": {
    "ConvertToEur": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-east-1:000000000000:function:marlin-fx-rates",
      "ResultPath": "$.converted",
      "Next": "Gate"
    },
    "Gate": {
      "Type": "Choice",
      "Choices": [
        {"Variable": "$.converted.amountEur", "NumericGreaterThanEquals": 1000, "Next": "SendToReview"}
      ],
      "Default": "AutoApprove"
    },
    "SendToReview": {"Type": "Pass", "Parameters": {"txId.$": "$.txId", "decision": "REVIEW"}, "End": true},
    "AutoApprove": {"Type": "Pass", "Parameters": {"txId.$": "$.txId", "decision": "APPROVE"}, "End": true}
  }
}
'''
open(sys.argv[1] + "/v1.asl.json", "w").write(V1)
PY

aws_local iam create-role --role-name marlin-lambda-exec \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name marlin-convert-to-eur --runtime python3.12 \
  --handler convert.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/marlin-lambda-exec" \
  --zip-file "fileb://$stage/convert.zip" >/dev/null
aws_local lambda invoke --function-name marlin-convert-to-eur --cli-binary-format raw-in-base64-out \
  --payload '{"amount":1,"currency":"EUR"}' /dev/null >/dev/null

aws_local iam create-role --role-name marlin-limit-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name marlin-limit-role --policy-name convert \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"lambda:InvokeFunction\",\"Resource\":[\"arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:marlin-fx-rates\",\"arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:marlin-convert-to-eur\"]}]}"

role="arn:aws:iam::${ACCOUNT_ID}:role/marlin-limit-role"
sm="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:marlin-limit-check"

# Version 1: the original release, still pointing at a retired function.
aws_local stepfunctions create-state-machine --name marlin-limit-check --role-arn "$role" \
  --definition "file://$stage/v1.asl.json" --publish >/dev/null
# Version 2: this afternoon's release.
aws_local stepfunctions update-state-machine --state-machine-arn "$sm" \
  --definition "file://$MISSION_DIR/workspace/limit-check.asl.json" --publish >/dev/null
aws_local stepfunctions create-state-machine-alias --name live \
  --routing-configuration "stateMachineVersionArn=${sm}:2,weight=100" >/dev/null

# The platform has already pushed a large payment through the alias.
aws_local stepfunctions start-execution --state-machine-arn "${sm}:live" \
  --input '{"txId":"TX-88001","amount":4200,"currency":"EUR"}' >/dev/null

echo "marlin-limit-check:live serves version 2, which auto-approves everything."
