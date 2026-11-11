#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# The execution role survived the sandbox cleanup; the function did not.
aws_local iam create-role --role-name parcel-label-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name parcel-label-role --policy-name write-logs \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],"Resource":"*"}]}'

echo "The parcel-label-role role exists. The dispatch job is calling parcel-label-formatter and getting nothing back."
