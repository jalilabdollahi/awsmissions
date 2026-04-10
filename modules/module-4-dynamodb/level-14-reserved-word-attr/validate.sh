#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
names="$(jq -r '.ExpressionAttributeNames["#s"]' query.json 2>/dev/null || true)"
[ "$names" = "status" ]
echo "success"
