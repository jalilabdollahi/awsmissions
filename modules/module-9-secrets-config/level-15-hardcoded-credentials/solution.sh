#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

secret_arn="$(aws_local secretsmanager describe-secret --secret-id nimbus/exporter/api-token \
  --query ARN --output text)"

aws_local iam create-role --role-name nimbus-exporter-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
cat > exporter-policy.json <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "$secret_arn"
    }
  ]
}
POLICY
aws_local iam put-role-policy --role-name nimbus-exporter-role --policy-name read-api-token \
  --policy-document file://exporter-policy.json

aws_local lambda update-function-configuration --function-name nimbus-exporter \
  --role "arn:aws:iam::000000000000:role/nimbus-exporter-role" \
  --environment "Variables={APP_ENV=prod,TOKEN_SECRET_ID=nimbus/exporter/api-token}" >/dev/null

for key in $(aws_local iam list-access-keys --user-name nimbus-ci --query 'AccessKeyMetadata[].AccessKeyId' --output text); do
  aws_local iam update-access-key --user-name nimbus-ci --access-key-id "$key" --status Inactive
done
