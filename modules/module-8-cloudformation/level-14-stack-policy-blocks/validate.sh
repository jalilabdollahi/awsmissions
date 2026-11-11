#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for s in kestrel-pr-742 kestrel-prod-core; do
  prot="$(aws_local cloudformation describe-stacks --stack-name "$s" \
    --query 'Stacks[0].EnableTerminationProtection' --output text 2>/dev/null || true)"
  if [ -z "$prot" ]; then
    echo "$s has been deleted. Only the merged PR's preview was meant to go."
    exit 1
  fi
  if [ "$prot" != "True" ] && [ "$prot" != "true" ]; then
    echo "$s lost its termination protection. Only the stack being retired should be unlocked."
    exit 1
  fi
done

status="$(aws_local cloudformation describe-stacks --stack-name kestrel-pr-731 \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
if [ -n "$status" ] && [ "$status" != "DELETE_COMPLETE" ]; then
  prot="$(aws_local cloudformation describe-stacks --stack-name kestrel-pr-731 \
    --query 'Stacks[0].EnableTerminationProtection' --output text)"
  echo "kestrel-pr-731 still exists (status $status, termination protection: $prot)."
  exit 1
fi

if aws_local s3api head-bucket --bucket kestrel-pr-731-artifacts >/dev/null 2>&1; then
  echo "The preview's bucket kestrel-pr-731-artifacts is still around."
  exit 1
fi
if aws_local sns list-topics --query 'Topics[].TopicArn' --output text | tr '\t' '\n' | grep -q ':kestrel-pr-731-notices$'; then
  echo "The preview's topic kestrel-pr-731-notices is still around."
  exit 1
fi

echo "kestrel-pr-731 is gone with its resources; #742 and production are still protected."
