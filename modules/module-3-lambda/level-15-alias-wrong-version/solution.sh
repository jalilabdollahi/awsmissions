#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

approved="$(aws_local lambda list-versions-by-function --function-name tax-calculator --output json \
  | jq -r '.Versions[] | select((.Description // "") | test("APPROVED")) | .Version')"
aws_local lambda update-alias --function-name tax-calculator --name prod \
  --function-version "$approved" >/dev/null
