#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

current="$(aws_local ssm get-parameter --name /harrier/payments/api-key \
  --query Parameter.Value --output text)"

aws_local ssm put-parameter --name /harrier/payments/api-key --type SecureString \
  --key-id alias/harrier-config --value "$current" --overwrite >/dev/null
