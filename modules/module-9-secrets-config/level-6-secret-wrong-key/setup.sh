#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local secretsmanager create-secret --name cinder/warehouse/login \
  --description "Warehouse loader login (billing job, BI dashboard)" \
  --secret-string "file://$MISSION_DIR/workspace/secret.json" >/dev/null

echo "cinder/warehouse/login holds username/password; the dashboard wants user/pass."
