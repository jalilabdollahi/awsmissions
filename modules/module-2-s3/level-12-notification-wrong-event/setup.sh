#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://snapfolio-gallery >/dev/null
aws_local sqs create-queue --queue-name thumbnail-jobs >/dev/null
aws_local sqs create-queue --queue-name deletion-audit >/dev/null

aws_local s3api put-bucket-notification-configuration --bucket snapfolio-gallery \
  --notification-configuration "file://$MISSION_DIR/workspace/notification.json"

echo "Thumbnails are only requested when a photo is deleted."
