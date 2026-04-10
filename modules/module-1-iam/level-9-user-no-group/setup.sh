#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local iam create-user --user-name orphan-user >/dev/null 2>&1 || true

echo "Broken IAM user created: orphan-user (no group membership)"
