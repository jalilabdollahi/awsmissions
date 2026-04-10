#!/usr/bin/env bash
set -euo pipefail
command="$(jq -r '.KeyConditionExpression' request.json 2>/dev/null || true)"
[ -n "$command" ]
echo "success"
