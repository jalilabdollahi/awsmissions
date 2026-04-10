#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local iam create-user --user-name team-user >/dev/null 2>&1 || true
aws_local iam create-group --group-name empty-group >/dev/null 2>&1 || true
aws_local iam add-user-to-group --user-name team-user --group-name empty-group >/dev/null 2>&1 || true

echo "Broken IAM group created: empty-group (no policy attached)"
