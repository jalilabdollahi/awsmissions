#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam create-role --role-name rate-quote-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/quote.zip" quote.py)
aws_local lambda create-function --function-name rate-quote-engine \
  --runtime python3.12 --handler quote.quote \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/rate-quote-role" \
  --zip-file "fileb://$stage/quote.zip" >/dev/null

# Partner identities live in Cartwheel's account but carry no Lambda permissions of their own.
for u in partner-shipright partner-fastlane; do
  aws_local iam create-user --user-name "$u" >/dev/null
done
# FastLane's old integration still has an unrelated, harmless permission.
aws_local iam put-user-policy --user-name partner-fastlane --policy-name read-own-docs \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:ListAllMyBuckets","Resource":"*"}]}'

echo "partner-shipright is calling rate-quote-engine and being refused."
