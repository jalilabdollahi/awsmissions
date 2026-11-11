#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

status="$(aws_local cloudformation describe-stacks --stack-name cobalt-reminders \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
case "$status" in
  CREATE_COMPLETE|UPDATE_COMPLETE) ;;
  "") echo "No stack named cobalt-reminders yet. Deploy the template under that name."; exit 1 ;;
  ROLLBACK_COMPLETE|CREATE_FAILED)
    reason="$(aws_local cloudformation describe-stack-events --stack-name cobalt-reminders \
      --query "StackEvents[?ResourceStatus=='CREATE_FAILED'].ResourceStatusReason | [0]" --output text)"
    echo "cobalt-reminders is in $status (CloudFormation said: $reason)."
    echo "A stack that failed on create cannot be updated; remove it and deploy again."
    exit 1 ;;
  *) echo "cobalt-reminders is in $status."; exit 1 ;;
esac

config="$(aws_local lambda get-function-configuration --function-name cobalt-reminder-sender \
  --query '[MemorySize,Timeout]' --output text 2>/dev/null || true)"
if [ -z "$config" ]; then
  echo "The stack is healthy but the function cobalt-reminder-sender does not exist."
  exit 1
fi
mem="$(printf '%s' "$config" | awk '{print $1}')"
timeout="$(printf '%s' "$config" | awk '{print $2}')"
if [ "$mem" != "1024" ] || [ "$timeout" != "20" ]; then
  echo "The function runs with ${mem} MB and a ${timeout}s timeout; the capacity plan for us-east-1 says 1024 MB and 20s."
  exit 1
fi

body="$(aws_local cloudformation get-template --stack-name cobalt-reminders --output json \
  | jq -r '.TemplateBody | if type=="string" then . else tojson end')"
case "$body" in
  *FindInMap*) ;;
  *) echo "The sizing must keep coming from the Mappings table (Fn::FindInMap), not be hard-coded per function."; exit 1 ;;
esac

echo "cobalt-reminder-sender runs with 1024 MB and a 20s timeout, sized from the regional Mappings table."
