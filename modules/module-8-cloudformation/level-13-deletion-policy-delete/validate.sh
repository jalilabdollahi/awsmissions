#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

status="$(aws_local cloudformation describe-stacks --stack-name nightjar-archive \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
if [ -n "$status" ] && [ "$status" != "DELETE_COMPLETE" ]; then
  echo "The nightjar-archive stack still exists (status $status). The pilot is supposed to be retired."
  exit 1
fi

# Data first: the point of the exercise.
if ! aws_local dynamodb describe-table --table-name nightjar-ledger-index >/dev/null 2>&1; then
  echo "The ledger index table nightjar-ledger-index is gone. The auditors needed it."
  exit 1
fi
items="$(aws_local dynamodb scan --table-name nightjar-ledger-index --select COUNT --query Count --output text)"
if [ "$items" != "3" ]; then
  echo "The ledger index table has $items records instead of 3."
  exit 1
fi
if ! aws_local s3api head-bucket --bucket nightjar-ledger-archive >/dev/null 2>&1; then
  echo "The archive bucket nightjar-ledger-archive no longer exists."
  exit 1
fi
objects="$(aws_local s3api list-objects-v2 --bucket nightjar-ledger-archive --prefix exports/ \
  --query 'length(Contents || `[]`)' --output text)"
if [ "$objects" != "2" ]; then
  echo "The archive bucket holds $objects ledger exports instead of 2. Deleting records is not retiring the stack."
  exit 1
fi

if aws_local sns list-topics --query 'Topics[].TopicArn' --output text | tr '\t' '\n' | grep -q ':nightjar-archive-events$'; then
  echo "The disposable events topic is still there; it belonged to the stack and should have been removed with it."
  exit 1
fi

echo "nightjar-archive is gone, its events topic with it, and all 3 index records and 2 ledger exports survived."
