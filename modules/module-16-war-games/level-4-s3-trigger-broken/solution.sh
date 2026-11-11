#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

FN_ARN="arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:mg-thumbnailer"

# 1. Move the trigger: remove it from staging, create it on the uploads bucket with the .jpg suffix.
aws_local s3api put-bucket-notification-configuration --bucket mg-photo-uploads-staging --notification-configuration '{}'
aws_local s3api put-bucket-notification-configuration --bucket mg-photo-uploads \
  --notification-configuration "{\"LambdaFunctionConfigurations\":[{\"LambdaFunctionArn\":\"$FN_ARN\",\"Events\":[\"s3:ObjectCreated:*\"],\"Filter\":{\"Key\":{\"FilterRules\":[{\"Name\":\"suffix\",\"Value\":\".jpg\"}]}}}]}"

# 2. Let the role read the production uploads (and only read).
aws_local iam put-role-policy --role-name mg-thumbnailer-role --policy-name thumbnailer --policy-document '{
  "Version":"2012-10-17","Statement":[
   {"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::mg-photo-uploads/*"},
   {"Effect":"Allow","Action":"s3:PutObject","Resource":"arn:aws:s3:::mg-photo-thumbs/*"}]}'

# 3. Point the function at the real thumbs bucket.
aws_local lambda update-function-configuration --function-name mg-thumbnailer \
  --environment 'Variables={THUMB_BUCKET=mg-photo-thumbs}' >/dev/null
aws_local lambda wait function-updated-v2 --function-name mg-thumbnailer 2>/dev/null || sleep 3
