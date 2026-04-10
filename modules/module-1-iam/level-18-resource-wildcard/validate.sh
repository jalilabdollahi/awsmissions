#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

resource="$(aws_local iam get-role-policy --role-name object-scope-role --policy-name object-scope-policy --query 'PolicyDocument.Statement[0].Resource' --output text 2>/dev/null || true)"

if [[ "$resource" == "arn:aws:s3:::bucket/*" ]]; then
  echo "object-scope-policy now allows access to all objects in bucket."
  exit 0
fi

echo "object-scope-policy is still scoped to a single object."
exit 1
