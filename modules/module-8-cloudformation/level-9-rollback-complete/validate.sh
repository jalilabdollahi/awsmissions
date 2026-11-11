#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

shared="$(aws_local cloudformation describe-stacks --stack-name saltmarsh-shared \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
if [ "$shared" != "CREATE_COMPLETE" ]; then
  echo "The shared stack is not healthy any more (status '${shared:-missing}'). It should not need any change."
  exit 1
fi

status="$(aws_local cloudformation describe-stacks --stack-name saltmarsh-api \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
case "$status" in
  CREATE_COMPLETE) ;;
  ROLLBACK_COMPLETE) echo "saltmarsh-api is still the failed ROLLBACK_COMPLETE stack from Friday's release."; exit 1 ;;
  "") echo "saltmarsh-api does not exist. It has to be deployed again under that name."; exit 1 ;;
  *) echo "saltmarsh-api is in $status; wait for it or look at its events."; exit 1 ;;
esac

value="$(aws_local ssm get-parameter --name /saltmarsh/alerts-topic \
  --query 'Parameter.Value' --output text 2>/dev/null || true)"
want="arn:aws:sns:us-east-1:${ACCOUNT_ID}:saltmarsh-pharmacy-alerts"
if [ "$value" != "$want" ]; then
  echo "/saltmarsh/alerts-topic holds '${value:-nothing}', expected the exported topic ARN."
  exit 1
fi

echo "saltmarsh-api was recreated and now imports the alerts topic from saltmarsh-shared."
