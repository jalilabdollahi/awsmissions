#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

STACK=brightwater-intake
status="$(aws_local cloudformation describe-stacks --stack-name "$STACK" \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
if [ -z "$status" ]; then
  echo "The stack $STACK is gone. Repair it (or redeploy it under the same name) so the intake system has its stack back."
  exit 1
fi
case "$status" in
  CREATE_COMPLETE|UPDATE_COMPLETE) ;;
  *) echo "Stack $STACK is in $status. Wait for it to settle or inspect its events."; exit 1 ;;
esac

# The point of the stack is the bucket: does it exist and take a write?
probe="$(mktemp)"
trap 'rm -f "$probe"' EXIT
echo "intake-form-check" > "$probe"
if ! aws_local s3api put-object --bucket brightwater-scans --key forms/check.txt --body "$probe" >/dev/null 2>&1; then
  types="$(aws_local cloudformation describe-stack-resources --stack-name "$STACK" \
    --query 'StackResources[].ResourceType' --output text)"
  echo "Uploads to brightwater-scans still fail: the bucket does not exist."
  echo "The stack currently claims these resource types: $types"
  exit 1
fi

# The stack must really own the bucket, not a hand-made one.
owned="$(aws_local cloudformation describe-stack-resources --stack-name "$STACK" \
  --query "StackResources[?ResourceType=='AWS::S3::Bucket'].PhysicalResourceId" --output text)"
if [ "$owned" != "brightwater-scans" ]; then
  echo "A bucket named brightwater-scans exists, but $STACK does not manage it. Fix the stack rather than creating the bucket by hand."
  exit 1
fi

topics="$(aws_local sns list-topics --query 'Topics[].TopicArn' --output text)"
case "$topics" in
  *:brightwater-reminders*) ;;
  *) echo "The reminder topic brightwater-reminders disappeared while you were fixing things."; exit 1 ;;
esac

echo "brightwater-intake now owns a real brightwater-scans bucket, and the front desk can upload again."
