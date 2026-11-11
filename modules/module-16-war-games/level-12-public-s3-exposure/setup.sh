#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

A="arn:aws:iam::${ACCOUNT_ID}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

aws_local s3 mb s3://ardent-customer-exports >/dev/null
aws_local s3 mb s3://ardent-marketing-assets >/dev/null
put() { printf '%s\n' "$2" > "$tmp/f"; aws_local s3 cp "$tmp/f" "s3://$1" >/dev/null; }
put ardent-customer-exports/pii/customers.csv "id,name,email"
put ardent-customer-exports/reports/q3-summary.pdf "Q3 summary"
put ardent-customer-exports/partners/nova/feed.csv "nova,feed"
put ardent-customer-exports/partners/zephyr/feed.csv "zephyr,feed"
put ardent-marketing-assets/logo.png "PNG-DATA"

for u in ardent-analyst ardent-temp-contractor ardent-partner-nova ardent-partner-zephyr ardent-outsider; do
  aws_local iam create-user --user-name "$u" >/dev/null
done
aws_local iam create-group --group-name ardent-staff >/dev/null
aws_local iam add-user-to-group --group-name ardent-staff --user-name ardent-temp-contractor
# "Just for quarter-end": the whole bucket.
aws_local iam put-group-policy --group-name ardent-staff --policy-name staff-reading --policy-document '{
  "Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::ardent-customer-exports/*"}]}'
# Partner policies written as partners/* "to save time".
for p in nova zephyr; do
  aws_local iam put-user-policy --user-name "ardent-partner-$p" --policy-name partner-feed --policy-document '{
    "Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::ardent-customer-exports/partners/*"}]}'
done

# Bucket policy: the real analyst grant plus the "temporary" share for everybody.
aws_local s3api put-bucket-policy --bucket ardent-customer-exports --policy "{
  \"Version\":\"2012-10-17\",\"Statement\":[
   {\"Sid\":\"AnalystsReadPii\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"$A:user/ardent-analyst\"},\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::ardent-customer-exports/pii/*\"},
   {\"Sid\":\"QuickShareForPartner\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::ardent-customer-exports/*\"}]}"
# The marketing bucket is meant to be public.
aws_local s3api put-bucket-policy --bucket ardent-marketing-assets --policy '{
  "Version":"2012-10-17","Statement":[{"Sid":"PublicLogo","Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::ardent-marketing-assets/*"}]}'

echo "SEC-INC-0719 is open: customer exports are readable by the wrong people."
