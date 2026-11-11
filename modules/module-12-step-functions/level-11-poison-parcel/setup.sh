#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

python3 - "$stage" <<'PY'
import sys, zipfile

VALIDATE = '''class MalformedParcel(Exception):
    pass


def handler(event, context):
    parcel = event["parcel"]
    if not parcel.get("weightKg") or parcel["weightKg"] <= 0:
        raise MalformedParcel("parcel %s has an impossible weight" % parcel["id"])
    zone = parcel["zip"][:2]
    return {"routeCode": "R-" + zone}
'''
with zipfile.ZipFile(sys.argv[1] + "/validate.zip", "w") as z:
    z.writestr("validate.py", VALIDATE)
PY

aws_local sqs create-queue --queue-name kestrel-accepted >/dev/null
aws_local sqs create-queue --queue-name kestrel-quarantine >/dev/null

aws_local iam create-role --role-name kestrel-lambda-exec \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name kestrel-validate-parcel --runtime python3.12 \
  --handler validate.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/kestrel-lambda-exec" \
  --zip-file "fileb://$stage/validate.zip" >/dev/null

aws_local iam create-role --role-name kestrel-import-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name kestrel-import-role --policy-name import \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"lambda:InvokeFunction\",\"Resource\":\"arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:kestrel-validate-parcel\"},{\"Effect\":\"Allow\",\"Action\":\"sqs:SendMessage\",\"Resource\":[\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:kestrel-accepted\",\"arn:aws:sqs:us-east-1:${ACCOUNT_ID}:kestrel-quarantine\"]}]}"

aws_local stepfunctions create-state-machine --name kestrel-manifest-import \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/kestrel-import-role" \
  --definition "file://$MISSION_DIR/workspace/manifest-import.asl.json" >/dev/null

aws_local lambda invoke --function-name kestrel-validate-parcel --cli-binary-format raw-in-base64-out \
  --payload '{"parcel":{"id":"warm","weightKg":1,"zip":"10115"}}' /dev/null >/dev/null

echo "kestrel-manifest-import is live; no parcel makes it to kestrel-accepted."
