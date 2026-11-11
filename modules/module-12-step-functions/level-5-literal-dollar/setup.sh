#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name saffron-subscribers \
  --attribute-definitions AttributeName=email,AttributeType=S \
  --key-schema AttributeName=email,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST >/dev/null

aws_local iam create-role --role-name saffron-signup-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name saffron-signup-role --policy-name write-subscribers \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"dynamodb:PutItem\",\"Resource\":\"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/saffron-subscribers\"}]}"

aws_local stepfunctions create-state-machine --name saffron-signup \
  --role-arn "arn:aws:iam::${ACCOUNT_ID}:role/saffron-signup-role" \
  --definition "file://$MISSION_DIR/workspace/signup.asl.json" >/dev/null

# Three real signups have already been processed by the broken flow.
sm="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:saffron-signup"
for who in "ana@example.com|Ana Ruiz|solo|1" "ben@example.com|Ben Okafor|couple|2" "chloe@example.com|Chloe Lin|family|3"; do
  IFS='|' read -r email name plan boxes <<<"$who"
  aws_local stepfunctions start-execution --state-machine-arn "$sm" \
    --input "{\"email\":\"$email\",\"fullName\":\"$name\",\"plan\":\"$plan\",\"boxes\":$boxes}" >/dev/null
done
sleep 2
echo "saffron-signup has processed 3 signups, yet the table holds a single odd row."
