#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# The template was never wrong; only the state of the stack is. Start over.
aws_local cloudformation delete-stack --stack-name saltmarsh-api
aws_local cloudformation wait stack-delete-complete --stack-name saltmarsh-api
aws_local cloudformation create-stack --stack-name saltmarsh-api \
  --template-body file://template.yaml >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name saltmarsh-api
