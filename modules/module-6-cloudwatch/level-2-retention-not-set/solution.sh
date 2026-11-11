#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for g in ingest api worker; do
  aws_local logs put-retention-policy --log-group-name "/orbit/$g" --retention-in-days 30
done
