#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

status="$(aws_local cloudformation describe-stacks --stack-name parcelhub-notifier \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
case "$status" in
  CREATE_COMPLETE|UPDATE_COMPLETE) ;;
  "") echo "No stack named parcelhub-notifier yet. Deploy the template under that name."; exit 1 ;;
  *) echo "parcelhub-notifier is in $status."; exit 1 ;;
esac

if ! aws_local lambda get-function-configuration --function-name parcel-notifier >/dev/null 2>&1; then
  types="$(aws_local cloudformation describe-stack-resources --stack-name parcelhub-notifier \
    --query 'StackResources[].ResourceType' --output text)"
  echo "The stack is healthy but the Lambda function parcel-notifier does not exist."
  echo "Resource types the stack actually holds: $types"
  exit 1
fi

owned="$(aws_local cloudformation describe-stack-resources --stack-name parcelhub-notifier \
  --query "StackResources[?ResourceType=='AWS::Lambda::Function'].PhysicalResourceId" --output text)"
if [ "$owned" != "parcel-notifier" ]; then
  echo "The function exists, but the stack does not own it. Deploy it through the stack."
  exit 1
fi

out="$(mktemp)"
trap 'rm -f "$out"' EXIT
if ! aws_local lambda invoke --function-name parcel-notifier --payload '{}' \
     --cli-binary-format raw-in-base64-out "$out" >/dev/null 2>&1; then
  echo "Invoking parcel-notifier failed."
  exit 1
fi
if ! grep -q '"stage": "courier-live"' "$out"; then
  echo "The function ran but returned: $(head -c 200 "$out"). It should report the stage from its environment."
  exit 1
fi

echo "parcel-notifier exists, belongs to the stack and answers with its environment stage."
