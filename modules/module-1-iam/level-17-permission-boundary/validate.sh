#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

boundary_arn="$(aws_local iam get-role --role-name bounded-reader-role --query 'Role.PermissionsBoundary.PermissionsBoundaryArn' --output text 2>/dev/null || true)"
if [[ -z "$boundary_arn" || "$boundary_arn" == "None" ]]; then
  echo "bounded-reader-role no longer has a blocking permissions boundary."
  exit 0
fi

version="$(aws_local iam get-policy --policy-arn "$boundary_arn" --query 'Policy.DefaultVersionId' --output text 2>/dev/null || true)"
doc="$(aws_local iam get-policy-version --policy-arn "$boundary_arn" --version-id "$version" --query 'PolicyVersion.Document' --output json 2>/dev/null || true)"

if [[ "$doc" == *"s3:GetObject"* && "$doc" == *"arn:aws:s3:::mission-bucket/*"* && "$doc" != *'"Effect":"Deny"'* ]]; then
  echo "bounded-reader-role now has a non-blocking permissions boundary."
  exit 0
fi

echo "bounded-reader-role is still blocked by its permissions boundary."
exit 1
