#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam create-role --role-name webhook-relay-exec \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/relay.zip" relay.mjs)

# The new pipeline template always writes index.handler, whatever the package contains.
aws_local lambda create-function --function-name webhook-relay \
  --runtime nodejs20.x --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/webhook-relay-exec" \
  --environment 'Variables={SIGNING_KEY=pinecrest-partner-key-7f3a}' \
  --zip-file "fileb://$stage/relay.zip" >/dev/null

echo "webhook-relay is deployed. Partners have not received a webhook since the migration."
