#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

python3 - "$stage" <<'PY'
import sys, zipfile

ELIGIBILITY = '''def handler(event, context):
    # ENV is baked into the build: "prod" or "staging"
    return {"rx": event["rx"], "approved": event["dose"] <= 3, "ruleset": "%s-2024.2"}
'''
for env in ("prod", "staging"):
    with zipfile.ZipFile("%s/%s.zip" % (sys.argv[1], env), "w") as z:
        z.writestr("eligibility.py", ELIGIBILITY % env)
PY

aws_local iam create-role --role-name harborview-lambda-exec \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

aws_local lambda create-function --function-name refill-eligibility-check --runtime python3.12 \
  --handler eligibility.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/harborview-lambda-exec" \
  --zip-file "fileb://$stage/prod.zip" >/dev/null
aws_local lambda create-function --function-name refill-eligibility-check-staging --runtime python3.12 \
  --handler eligibility.handler --role "arn:aws:iam::${ACCOUNT_ID}:role/harborview-lambda-exec" \
  --zip-file "fileb://$stage/staging.zip" >/dev/null

# The workflow role may invoke the eligibility functions (the old name is still listed, plus a wildcard from the dev days).
aws_local iam create-role --role-name harborview-refill-flow-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name harborview-refill-flow-role --policy-name invoke-eligibility \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"lambda:InvokeFunction\",\"Resource\":[\"arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:check-refill-eligibility\",\"arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:refill-eligibility-check*\"]}]}"

aws_local stepfunctions create-state-machine --name harborview-refill-flow \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/harborview-refill-flow-role" \
  --definition "file://$MISSION_DIR/workspace/refill-flow.asl.json" >/dev/null

echo "harborview-refill-flow is deployed and every refill check fails."
