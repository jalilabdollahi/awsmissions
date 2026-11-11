#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Created by the application with default settings: retention never expires.
for g in /orbit/ingest /orbit/api /orbit/worker; do
  aws_local logs create-log-group --log-group-name "$g"
done

# Deliberately configured groups that must survive a careless "fix them all".
aws_local logs create-log-group --log-group-name /orbit/audit
aws_local logs put-retention-policy --log-group-name /orbit/audit --retention-in-days 365
aws_local logs create-log-group --log-group-name /billing/invoice-exports
aws_local logs put-retention-policy --log-group-name /billing/invoice-exports --retention-in-days 2557

echo "Three Orbit log groups never expire, the audit group is fine, and another team's group is off limits."
