#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

dest="$(mktemp)"
trap 'rm -f "$dest"' EXIT
priya() { aws_as_user nimbus-priya "$@"; }

if [ -n "$(aws_local iam list-attached-user-policies --user-name nimbus-priya --query 'AttachedPolicies[0].PolicyArn' --output text | grep -v None || true)" ] \
   || [ -n "$(aws_local iam list-user-policies --user-name nimbus-priya --query 'PolicyNames[0]' --output text | grep -v None || true)" ]; then
  echo "A policy is attached straight to nimbus-priya. At Nimbus access comes from groups; remove it and use a group."
  exit 1
fi

if ! out="$(priya s3api get-object --bucket nimbus-curated --key daily/events.csv "$dest" 2>&1)"; then
  echo "nimbus-priya still cannot read the curated bucket: $(printf '%s' "$out" | tail -1)"
  echo "Her user has nothing attached, so check which groups she is in: aws iam list-groups-for-user --user-name nimbus-priya"
  exit 1
fi
if ! priya s3api list-objects-v2 --bucket nimbus-curated >/dev/null 2>&1; then
  echo "She can read single files but not list the curated bucket; the group she joined is not the analyst one."
  exit 1
fi

if priya s3api get-object --bucket nimbus-raw-landing --key landing/dump-0001.json "$dest" >/dev/null 2>&1; then
  echo "nimbus-priya can read the raw landing bucket. That is the contractors' access, not an analyst's."
  exit 1
fi
if priya iam list-users >/dev/null 2>&1; then
  echo "nimbus-priya can call IAM. She ended up with administrator rights; analysts must not have them."
  exit 1
fi

echo "nimbus-priya has analyst access: curated data lake yes, raw landing and IAM no."
