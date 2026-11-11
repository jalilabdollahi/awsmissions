#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=ardent-customer-exports
can_read() { # user bucket key
  aws_as_user "$1" s3api get-object --bucket "$2" --key "$3" /dev/null >/dev/null 2>&1
}
broken=0
echo "SEC-INC-0719 retest"

# The business must keep running.
if ! can_read ardent-analyst $B pii/customers.csv; then
  echo "OUTAGE: ardent-analyst can no longer read pii/customers.csv. Remove the exposure, keep the analyst grant."
  exit 1
fi
if ! can_read ardent-partner-nova $B partners/nova/feed.csv || ! can_read ardent-partner-zephyr $B partners/zephyr/feed.csv; then
  echo "OUTAGE: a partner can no longer read their own feed."
  exit 1
fi
if ! can_read ardent-temp-contractor $B reports/q3-summary.pdf; then
  echo "OUTAGE: staff (via the ardent-staff group) can no longer read reports/."
  exit 1
fi
if ! can_read ardent-outsider ardent-marketing-assets logo.png; then
  echo "OUTAGE: the public logo in ardent-marketing-assets is no longer readable. That bucket is public on purpose."
  exit 1
fi
if ! aws_local s3api get-bucket-policy --bucket $B >/dev/null 2>&1; then
  echo "The bucket policy on $B was deleted entirely. Keep the legitimate analyst grant; remove only what is too broad."
  exit 1
fi

# Exposure 1: a principal with no permissions of its own.
leak=0
for key in pii/customers.csv reports/q3-summary.pdf partners/nova/feed.csv partners/zephyr/feed.csv; do
  can_read ardent-outsider $B "$key" && leak=$((leak + 1))
done
if [ "$leak" -gt 0 ]; then
  echo "[FAULT] exposure 1  an unrelated identity with no permissions can read $leak object(s) in $B"
  broken=$((broken + 1))
else
  echo "[ok]    exposure 1  unrelated identities are locked out of $B"
fi

# Exposure 2: staff group scope.
if can_read ardent-temp-contractor $B pii/customers.csv || can_read ardent-temp-contractor $B partners/nova/feed.csv; then
  echo "[FAULT] exposure 2  the temp contractor (staff group) can read data outside reports/"
  broken=$((broken + 1))
else
  echo "[ok]    exposure 2  staff can read reports/ only"
fi

# Exposure 3: partner isolation.
if can_read ardent-partner-nova $B partners/zephyr/feed.csv || can_read ardent-partner-zephyr $B partners/nova/feed.csv \
   || can_read ardent-partner-nova $B pii/customers.csv; then
  echo "[FAULT] exposure 3  a partner can read data that is not theirs"
  broken=$((broken + 1))
else
  echo "[ok]    exposure 3  each partner sees only their own feed"
fi

if [ "$broken" -gt 0 ]; then
  echo "$broken exposure(s) still open."
  exit 1
fi
echo "All three exposures are closed and every legitimate reader still works. Notify the researcher and write the postmortem."
