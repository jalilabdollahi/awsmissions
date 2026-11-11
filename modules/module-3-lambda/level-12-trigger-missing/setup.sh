#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://helixia-lab-inbox >/dev/null
aws_local dynamodb create-table --table-name lab-result-index \
  --attribute-definitions AttributeName=object_key,AttributeType=S \
  --key-schema AttributeName=object_key,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null

aws_local iam create-role --role-name lab-indexer-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name lab-indexer-role --policy-name write-index \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"dynamodb:PutItem\",\"Resource\":\"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/lab-result-index\"}]}"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/indexer.zip" indexer.py)
aws_local lambda create-function --function-name lab-result-indexer \
  --runtime python3.12 --handler indexer.index \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/lab-indexer-role" \
  --zip-file "fileb://$stage/indexer.zip" >/dev/null

# S3 is allowed to call the function; nothing tells S3 to do it.
aws_local lambda add-permission --function-name lab-result-indexer --statement-id s3-inbox \
  --action lambda:InvokeFunction --principal s3.amazonaws.com \
  --source-arn arn:aws:s3:::helixia-lab-inbox --source-account "$ACCOUNT_ID" >/dev/null

echo "The inbox bucket receives files, the indexer is ready, and nothing connects them."
