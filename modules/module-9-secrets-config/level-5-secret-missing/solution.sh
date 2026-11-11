#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local secretsmanager restore-secret --secret-id wyvern/matchmaker/db-credentials >/dev/null
