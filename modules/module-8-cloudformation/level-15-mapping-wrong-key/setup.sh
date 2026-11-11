#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudformation delete-stack --stack-name cobalt-reminders >/dev/null 2>&1 || true

# The execution role the template points at.
aws_local iam create-role --role-name cobalt-reminders-exec \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

echo "The Cobalt reminder template is in your workspace; the stack has not been deployed."
