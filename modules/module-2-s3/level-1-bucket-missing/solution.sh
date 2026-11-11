#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Read the name the service actually uses and create exactly that bucket.
bucket="$(grep '^MANIFEST_BUCKET=' ingest.env | cut -d= -f2)"
aws_local s3 mb "s3://$bucket"
