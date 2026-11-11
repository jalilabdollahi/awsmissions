#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

retention_of() {
  aws_local logs describe-log-groups --log-group-name-prefix "$1" \
    --query "logGroups[?logGroupName=='$1'].retentionInDays | [0]" --output text 2>/dev/null || echo "missing"
}

for g in /orbit/ingest /orbit/api /orbit/worker; do
  r="$(retention_of "$g")"
  if [ "$r" = "missing" ] || [ "$r" = "None" ] || [ -z "$r" ]; then
    echo "$g still has no retention policy (logs never expire, and keep being billed)."
    exit 1
  fi
  if [ "$r" != "30" ]; then
    echo "$g keeps logs for $r days. The data policy is exactly 30 days."
    exit 1
  fi
done

audit="$(retention_of /orbit/audit)"
if [ "$audit" != "365" ]; then
  echo "/orbit/audit must stay at 365 days for legal reasons (it is now '$audit'). Only the three application groups get 30 days."
  exit 1
fi
other="$(retention_of /billing/invoice-exports)"
if [ "$other" != "2557" ]; then
  echo "/billing/invoice-exports belongs to another team and its retention changed (now '$other'). Only touch /orbit/ingest, /orbit/api and /orbit/worker."
  exit 1
fi

echo "Orbit's application logs expire after 30 days; the audit trail and the billing team's logs are untouched."
