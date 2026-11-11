#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Unlock exactly one stack, then delete it.
aws_local cloudformation update-termination-protection --stack-name kestrel-pr-731 \
  --no-enable-termination-protection >/dev/null
aws_local cloudformation delete-stack --stack-name kestrel-pr-731
aws_local cloudformation wait stack-delete-complete --stack-name kestrel-pr-731
