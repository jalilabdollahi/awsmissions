#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ../../../scripts/aws_helpers.sh

aws_local iam create-user --user-name mission-user --path /ops/ >/dev/null 2>&1 || true
aws_local iam put-user-policy   --user-name mission-user   --policy-name path-check-policy   --policy-document "file://$SCRIPT_DIR/policy.json" >/dev/null

echo "Broken IAM user created: mission-user at path /ops/"
