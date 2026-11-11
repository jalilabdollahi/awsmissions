#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
TRUST='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

aws_local ssm put-parameter --name /pelican/partner-token --type String --value 'tok-pelican-7f3a91' >/dev/null
aws_local dynamodb create-table --table-name pl-lockers --attribute-definitions AttributeName=lockerId,AttributeType=S \
  --key-schema AttributeName=lockerId,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null
aws_local dynamodb put-item --table-name pl-lockers --item '{"lockerId":{"S":"L-100"},"city":{"S":"Utrecht"}}' >/dev/null
aws_local dynamodb put-item --table-name pl-lockers --item '{"lockerId":{"S":"L-101"},"city":{"S":"Leiden"}}' >/dev/null

# Authorizer: compares the presented token with the SSM parameter.
cat > "$tmp/auth.py" <<'PY'
import boto3

def handler(event, context):
    expected = boto3.client("ssm").get_parameter(Name="/pelican/partner-token")["Parameter"]["Value"]
    effect = "Allow" if event.get("authorizationToken") == expected else "Deny"
    return {"principalId": "partner",
            "policyDocument": {"Version": "2012-10-17",
                               "Statement": [{"Action": "execute-api:Invoke", "Effect": effect, "Resource": event["methodArn"]}]}}
PY
cat > "$tmp/lockers.py" <<'PY'
import json
import boto3

def handler(event, context):
    items = boto3.client("dynamodb").scan(TableName="pl-lockers")["Items"]
    lockers = [{"id": i["lockerId"]["S"], "city": i["city"]["S"]} for i in items]
    return {"statusCode": 200, "headers": {"Content-Type": "application/json"}, "body": json.dumps({"lockers": lockers})}
PY
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],sys.argv[3])" "$tmp/auth.zip" "$tmp/auth.py" auth.py
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],sys.argv[3])" "$tmp/lockers.zip" "$tmp/lockers.py" lockers.py

aws_local iam create-role --role-name pl-auth-role --assume-role-policy-document "$TRUST" >/dev/null
aws_local iam create-role --role-name pl-lockers-role --assume-role-policy-document "$TRUST" >/dev/null
# "Minimal": the authorizer has no SSM permission; the backend can only GetItem.
aws_local iam put-role-policy --role-name pl-auth-role --policy-name minimal --policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"logs:CreateLogGroup","Resource":"*"}]}'
aws_local iam put-role-policy --role-name pl-lockers-role --policy-name minimal --policy-document \
  "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"dynamodb:GetItem\",\"Resource\":\"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/pl-lockers\"}]}"
aws_local lambda create-function --function-name pl-token-auth --runtime python3.12 --handler auth.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/pl-auth-role" --zip-file "fileb://$tmp/auth.zip" >/dev/null
aws_local lambda create-function --function-name pl-lockers-api --runtime python3.12 --handler lockers.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/pl-lockers-role" --zip-file "fileb://$tmp/lockers.zip" >/dev/null

API="$(aws_local apigateway create-rest-api --name pelican-partner-api --query id --output text)"
ROOT="$(aws_local apigateway get-resources --rest-api-id "$API" --query 'items[0].id' --output text)"
RES="$(aws_local apigateway create-resource --rest-api-id "$API" --parent-id "$ROOT" --path-part lockers --query id --output text)"
# Copy-pasted from the admin API: custom header name; no result caching.
aws_local apigateway create-authorizer --rest-api-id "$API" --name pl-token-auth --type TOKEN \
  --authorizer-uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:pl-token-auth/invocations" \
  --identity-source method.request.header.X-Admin-Token --authorizer-result-ttl-in-seconds 0 >/dev/null
# The script made every method IAM-authenticated.
aws_local apigateway put-method --rest-api-id "$API" --resource-id "$RES" --http-method GET --authorization-type AWS_IAM >/dev/null
aws_local apigateway put-integration --rest-api-id "$API" --resource-id "$RES" --http-method GET --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:pl-lockers-api/invocations" >/dev/null
aws_local apigateway create-deployment --rest-api-id "$API" --stage-name live >/dev/null

echo "PX-318 is open: partner calls are rejected."
