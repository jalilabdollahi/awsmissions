#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

API="$(aws_local apigateway get-rest-apis --query "items[?name=='pelican-partner-api'].id | [0]" --output text)"
RES="$(aws_local apigateway get-resources --rest-api-id "$API" --query "items[?path=='/lockers'].id | [0]" --output text)"
AUTH="$(aws_local apigateway get-authorizers --rest-api-id "$API" --query 'items[0].id' --output text)"

# 1. Method: use the token authorizer.
aws_local apigateway update-method --rest-api-id "$API" --resource-id "$RES" --http-method GET \
  --patch-operations "op=replace,path=/authorizationType,value=CUSTOM" "op=replace,path=/authorizerId,value=$AUTH" >/dev/null

# 2. Authorizer: read the standard header.
aws_local apigateway update-authorizer --rest-api-id "$API" --authorizer-id "$AUTH" \
  --patch-operations "op=replace,path=/identitySource,value=method.request.header.Authorization" >/dev/null

# 3. Authorizer role: read the token parameter.
aws_local iam put-role-policy --role-name pl-auth-role --policy-name minimal --policy-document '{
  "Version":"2012-10-17","Statement":[
   {"Effect":"Allow","Action":"logs:CreateLogGroup","Resource":"*"},
   {"Effect":"Allow","Action":"ssm:GetParameter","Resource":"arn:aws:ssm:us-east-1:000000000000:parameter/pelican/partner-token"}]}'

# 4. Backend role: scan the lockers table; then publish the API definition to the live stage.
aws_local iam put-role-policy --role-name pl-lockers-role --policy-name minimal --policy-document '{
  "Version":"2012-10-17","Statement":[
   {"Effect":"Allow","Action":["dynamodb:GetItem","dynamodb:Scan"],"Resource":"arn:aws:dynamodb:us-east-1:000000000000:table/pl-lockers"}]}'
aws_local apigateway create-deployment --rest-api-id "$API" --stage-name live >/dev/null
