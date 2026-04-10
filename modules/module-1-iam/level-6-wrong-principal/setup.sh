#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ../../../scripts/aws_helpers.sh

aws_local iam create-role   --role-name cross-account-role   --assume-role-policy-document "file://$SCRIPT_DIR/trust-policy.json" >/dev/null 2>&1 || true

for _ in {1..10}; do
  if aws_local iam get-role --role-name cross-account-role >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "Broken IAM role created: cross-account-role"
