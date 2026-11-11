#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Take the trigger away from staging, then give the same configuration to prod.
aws_local s3api put-bucket-notification-configuration --bucket marlowe-invoices-staging \
  --notification-configuration '{}'
aws_local s3api put-bucket-notification-configuration --bucket marlowe-invoices-prod \
  --notification-configuration file://notification.json
