#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

groups="$(aws_local iam list-groups-for-user --user-name orphan-user --query 'Groups[].GroupName' --output text 2>/dev/null || true)"
doc="$(aws_local iam get-group-policy --group-name readers-group --policy-name readers-policy --query 'PolicyDocument' --output json 2>/dev/null || true)"

if [[ "$groups" == *"readers-group"* && "$doc" == *"s3:GetObject"* && "$doc" == *"arn:aws:s3:::mission-bucket/*"* ]]; then
  echo "orphan-user is now in readers-group with the expected access policy."
  exit 0
fi

echo "orphan-user is still missing the required group membership or group policy."
exit 1
