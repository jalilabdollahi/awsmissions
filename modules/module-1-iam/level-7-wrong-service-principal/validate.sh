#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

role_arn="arn:aws:iam::${ACCOUNT_ID}:role/sre-breakglass"
queue_url="$(aws_local sqs get-queue-url --queue-name payments-retry --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$queue_url" ]; then
  echo "The payments-retry queue is missing; the incident drill needs it."
  exit 1
fi
if ! aws_local iam get-role --role-name sre-breakglass >/dev/null 2>&1; then
  echo "sre-breakglass was deleted. Fix the role instead of removing it."
  exit 1
fi

rc=0
aws_as_role "$role_arn" sre-oncall "" sqs purge-queue --queue-url "$queue_url" >/dev/null 2>&1 || rc=$?
case "$rc" in
  0) ;;
  98)
    echo "sre-oncall still cannot assume sre-breakglass."
    echo "Read the trust policy and ask what kind of principal it names."
    exit 1 ;;
  *)
    echo "sre-oncall assumed the role but the purge failed (exit $rc). The permissions policy was fine; leave it alone."
    exit 1 ;;
esac

# The break-glass role must not become available to everybody.
rc=0
aws_as_role "$role_arn" sre-intern "" sqs purge-queue --queue-url "$queue_url" >/dev/null 2>&1 || rc=$?
if [ "$rc" -ne 98 ]; then
  echo "sre-intern can assume the break-glass role as well. Trust only sre-oncall."
  exit 1
fi

echo "sre-oncall can assume sre-breakglass and purge the queue; sre-intern cannot."
