#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam delete-user-policy --user-name forge-deployer --policy-name release-freeze-2023
