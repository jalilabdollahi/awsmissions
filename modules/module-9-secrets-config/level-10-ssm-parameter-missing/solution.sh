#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

recorded="$(aws_local secretsmanager get-secret-value --secret-id corvid/checkout/db-credentials \
  --query SecretString --output text)"
host="$(printf '%s' "$recorded" | jq -r .host)"
port="$(printf '%s' "$recorded" | jq -r .port)"

aws_local ssm put-parameter --name /corvid/checkout/db-host --type String --value "$host" >/dev/null
aws_local ssm put-parameter --name /corvid/checkout/db-port --type String --value "$port" >/dev/null
