#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local secretsmanager create-secret --name wyvern/matchmaker/db-credentials \
  --description "Matchmaker database login" \
  --secret-string '{"username":"mm_service","password":"Quartz!Maple-4821","host":"mm-db.wyvern.internal"}' >/dev/null

# Last night's tidy-up script.
aws_local secretsmanager delete-secret --secret-id wyvern/matchmaker/db-credentials \
  --recovery-window-in-days 14 >/dev/null

echo "The matchmaker's secret is scheduled for deletion in 14 days."
