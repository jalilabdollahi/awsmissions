#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3api put-bucket-versioning --bucket ledgerly-contracts \
  --versioning-configuration Status=Enabled
