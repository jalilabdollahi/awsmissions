#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

aws_local s3 mb s3://corvid-storefront-assets >/dev/null
echo "price list 2026" > "$work/prices.csv"
aws_local s3 cp "$work/prices.csv" s3://corvid-storefront-assets/downloads/price-list.csv >/dev/null

# Deliberately: no logging configuration and no log bucket.
echo "No access logs exist for corvid-storefront-assets."
