#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local secretsmanager create-secret --name corvid/checkout/db-credentials \
  --secret-string '{"host":"checkout-db.corvid.internal","port":"5433","username":"checkout_app"}' >/dev/null

aws_local iam create-user --user-name corvid-runner >/dev/null
aws_local iam put-user-policy --user-name corvid-runner --policy-name assume-checkout \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::${ACCOUNT_ID}:role/corvid-checkout\"}]}"
aws_local iam create-role --role-name corvid-checkout \
  --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::${ACCOUNT_ID}:user/corvid-runner\"},\"Action\":\"sts:AssumeRole\"}]}" >/dev/null
aws_local iam put-role-policy --role-name corvid-checkout --policy-name read-checkout-config \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"ssm:GetParameter\",\"ssm:GetParameters\"],\"Resource\":\"arn:aws:ssm:us-east-1:${ACCOUNT_ID}:parameter/corvid/checkout/*\"}]}"

# An unrelated parameter so the namespace is not empty.
aws_local ssm put-parameter --name /corvid/checkout/feature-flags --type String --value "express=on" >/dev/null

echo "The checkout role is ready, but its two connection parameters do not exist."
