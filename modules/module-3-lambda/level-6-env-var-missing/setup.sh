#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for env in prod staging; do
  aws_local dynamodb create-table --table-name "maple-fx-rates-$env" \
    --attribute-definitions AttributeName=pair,AttributeType=S \
    --key-schema AttributeName=pair,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null
done
aws_local dynamodb put-item --table-name maple-fx-rates-prod \
  --item '{"pair":{"S":"EURUSD"},"rate":{"N":"1.08735"}}'
aws_local dynamodb put-item --table-name maple-fx-rates-staging \
  --item '{"pair":{"S":"EURUSD"},"rate":{"N":"1.00000"}}'

aws_local iam create-role --role-name fx-lookup-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name fx-lookup-role --policy-name read-prod-rates \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"dynamodb:GetItem\",\"Resource\":\"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/maple-fx-rates-prod\"}]}"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/fx.zip" fx_lookup.py)

# The re-deploy wiped RATES_TABLE; only the precision setting survived.
aws_local lambda create-function --function-name fx-rate-lookup \
  --runtime python3.12 --handler fx_lookup.convert \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/fx-lookup-role" \
  --environment 'Variables={FX_PRECISION=4}' \
  --zip-file "fileb://$stage/fx.zip" >/dev/null

echo "fx-rate-lookup raises KeyError on every call; two rates tables exist (prod and staging)."
