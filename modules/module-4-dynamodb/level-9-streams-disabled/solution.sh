#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb update-table --table-name greenroom-articles \
  --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES >/dev/null
