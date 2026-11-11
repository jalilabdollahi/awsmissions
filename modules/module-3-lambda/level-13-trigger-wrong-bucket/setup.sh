#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://marlowe-invoices-prod >/dev/null
aws_local s3 mb s3://marlowe-invoices-staging >/dev/null
aws_local dynamodb create-table --table-name marlowe-invoice-ledger \
  --attribute-definitions AttributeName=doc_id,AttributeType=S \
  --key-schema AttributeName=doc_id,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null

aws_local iam create-role --role-name invoice-extractor-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name invoice-extractor-role --policy-name ledger-write \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"dynamodb:PutItem\",\"Resource\":\"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/marlowe-invoice-ledger\"}]}"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/extract.zip" extract.mjs)
aws_local lambda create-function --function-name invoice-extractor \
  --runtime nodejs20.x --handler extract.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/invoice-extractor-role" \
  --zip-file "fileb://$stage/extract.zip" >/dev/null

# Both buckets may call the function; only the staging one is wired up.
for b in prod staging; do
  aws_local lambda add-permission --function-name invoice-extractor --statement-id "s3-$b" \
    --action lambda:InvokeFunction --principal s3.amazonaws.com \
    --source-arn "arn:aws:s3:::marlowe-invoices-$b" --source-account "$ACCOUNT_ID" >/dev/null
done
aws_local s3api put-bucket-notification-configuration --bucket marlowe-invoices-staging \
  --notification-configuration "file://$MISSION_DIR/workspace/notification.json"

echo "The extractor is wired to marlowe-invoices-staging."
