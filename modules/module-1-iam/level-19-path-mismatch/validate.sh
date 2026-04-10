#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

resource="$(aws_local iam get-user-policy --user-name mission-user --policy-name path-check-policy --query 'PolicyDocument.Statement[0].Resource' --output text 2>/dev/null || true)"

if [[ "$resource" == "arn:aws:iam::000000000000:user/ops/mission-user" ]]; then
  echo "path-check-policy now matches the user's actual path."
  exit 0
fi

echo "path-check-policy still references the wrong path."
exit 1
