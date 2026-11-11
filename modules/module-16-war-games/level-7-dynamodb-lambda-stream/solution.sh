#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. Stream with new images.
aws_local dynamodb update-table --table-name orbit-workouts \
  --stream-specification StreamEnabled=false >/dev/null
sleep 1
aws_local dynamodb update-table --table-name orbit-workouts \
  --stream-specification StreamEnabled=true,StreamViewType=NEW_IMAGE >/dev/null

# 2. Re-create the mapping against the current stream.
OLD="$(aws_local lambda list-event-source-mappings --function-name orbit-leaderboard-updater --query 'EventSourceMappings[0].UUID' --output text)"
aws_local lambda delete-event-source-mapping --uuid "$OLD" >/dev/null
STREAM="$(aws_local dynamodb describe-table --table-name orbit-workouts --query Table.LatestStreamArn --output text)"
aws_local lambda create-event-source-mapping --function-name orbit-leaderboard-updater \
  --event-source-arn "$STREAM" --starting-position LATEST --batch-size 1 >/dev/null

# 3. Fix the table name in the function configuration.
aws_local lambda update-function-configuration --function-name orbit-leaderboard-updater \
  --environment 'Variables={LEADERBOARD_TABLE=orbit-leaderboard}' >/dev/null
aws_local lambda wait function-updated-v2 --function-name orbit-leaderboard-updater 2>/dev/null || sleep 2

# 4. Grant UpdateItem on the leaderboard table.
aws_local iam put-role-policy --role-name orbit-updater-role --policy-name leaderboard-write --policy-document '{
  "Version":"2012-10-17","Statement":[
   {"Effect":"Allow","Action":["dynamodb:UpdateItem","dynamodb:GetItem"],"Resource":"arn:aws:dynamodb:us-east-1:000000000000:table/orbit-leaderboard"}]}'
