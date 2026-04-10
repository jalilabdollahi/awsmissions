#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ../../../scripts/aws_helpers.sh

aws_local iam create-role   --role-name external-id-role   --assume-role-policy-document "file://$SCRIPT_DIR/trust-policy.json" >/dev/null 2>&1 || true

echo "Broken IAM role created: external-id-role (requires ExternalId)"
