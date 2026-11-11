#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

status="$(aws_local cloudformation describe-stacks --stack-name crescent-platform \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
case "$status" in
  CREATE_COMPLETE|UPDATE_COMPLETE) ;;
  "") echo "crescent-platform does not exist right now. Deploy it again once its problems are fixed."; exit 1 ;;
  ROLLBACK_COMPLETE|CREATE_FAILED)
    reason="$(aws_local cloudformation describe-stack-events --stack-name crescent-platform \
      --query "StackEvents[?contains(ResourceStatus,'FAILED')].ResourceStatusReason | [0]" --output text)"
    echo "crescent-platform is in $status. CloudFormation said: $reason"
    echo "A stack that failed on create cannot be updated; remove it and deploy again."
    exit 1 ;;
  *) echo "crescent-platform is in $status."; exit 1 ;;
esac

want="arn:aws:sns:us-east-1:${ACCOUNT_ID}:crescent-billing-alerts"
if ! aws_local sns list-topics --query 'Topics[].TopicArn' --output text | tr '\t' '\n' | grep -qx "$want"; then
  echo "The stack is healthy but the child's alert topic (crescent-billing-alerts) does not exist."
  exit 1
fi

got="$(aws_local cloudformation describe-stacks --stack-name crescent-platform \
  --query "Stacks[0].Outputs[?OutputKey=='AlertsTopicArn'].OutputValue" --output text)"
if [ -z "$got" ] || [ "$got" = "None" ]; then
  echo "The parent has no AlertsTopicArn output."
  exit 1
fi
if [ "$got" != "$want" ]; then
  echo "The parent's AlertsTopicArn output says '$got', which is not the ARN of the topic the child created."
  exit 1
fi

echo "crescent-platform nests the alerts child from S3 and exposes its real topic ARN."
