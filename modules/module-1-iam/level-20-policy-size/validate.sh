#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

attached="$(aws_local iam list-attached-role-policies --role-name bloated-role --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null || true)"
for arn in $attached; do
  version="$(aws_local iam get-policy --policy-arn "$arn" --query 'Policy.DefaultVersionId' --output text 2>/dev/null || true)"
  doc="$(aws_local iam get-policy-version --policy-arn "$arn" --version-id "$version" --query 'PolicyVersion.Document' --output json 2>/dev/null || true)"
  if [[ "$doc" == *"s3:GetObject"* && "$doc" == *"arn:aws:s3:::mission-bucket/*"* ]]; then
    echo "bloated-role now has an attached managed policy with the required permissions."
    exit 0
  fi
done

echo "bloated-role still does not have the expected managed policy attached."
exit 1
