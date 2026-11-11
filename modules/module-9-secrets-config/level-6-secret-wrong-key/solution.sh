#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Keep the legacy fields, add the ones the dashboard expects.
jq '. + {user: .username, pass: .password}' secret.json > secret.merged
mv secret.merged secret.json

aws_local secretsmanager put-secret-value --secret-id cinder/warehouse/login \
  --secret-string file://secret.json >/dev/null
