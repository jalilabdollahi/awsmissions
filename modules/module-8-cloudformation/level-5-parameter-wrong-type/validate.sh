#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

status="$(aws_local cloudformation describe-stacks --stack-name quarry-resizer \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
if [ -z "$status" ]; then
  echo "quarry-resizer does not exist right now. Deploy it again once the cause is fixed."
  exit 1
fi
if [ "$status" = "ROLLBACK_COMPLETE" ]; then
  reason="$(aws_local cloudformation describe-stack-events --stack-name quarry-resizer \
    --query "StackEvents[?ResourceStatus=='CREATE_FAILED'].ResourceStatusReason | [0]" --output text)"
  echo "quarry-resizer is still the rolled-back stack from the failed release. CloudFormation said: $reason"
  exit 1
fi
if [ "$status" != "CREATE_COMPLETE" ] && [ "$status" != "UPDATE_COMPLETE" ]; then
  echo "quarry-resizer is in $status."
  exit 1
fi

timeout="$(aws_local lambda get-function-configuration --function-name quarry-resizer \
  --query 'Timeout' --output text 2>/dev/null || true)"
if [ -z "$timeout" ]; then
  echo "The stack is healthy but the function quarry-resizer does not exist."
  exit 1
fi
if [ "$timeout" != "45" ]; then
  echo "The function exists with a ${timeout}s timeout; panoramas need 45 seconds."
  exit 1
fi

given="$(aws_local cloudformation describe-stacks --stack-name quarry-resizer \
  --query "Stacks[0].Parameters[?ParameterKey=='TimeoutSeconds'].ParameterValue" --output text)"
if [ "$given" != "45" ]; then
  echo "The timeout must come through the TimeoutSeconds parameter as a plain number (stack has '$given')."
  exit 1
fi

echo "quarry-resizer is CREATE_COMPLETE and the function has a 45 second timeout."
