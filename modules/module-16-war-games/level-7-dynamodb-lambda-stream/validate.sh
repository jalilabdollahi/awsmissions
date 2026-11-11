#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

FN=orbit-leaderboard-updater
bad=0
echo "Leaderboard pipeline triage (ORBIT-1893)"

for t in orbit-workouts orbit-leaderboard; do
  if ! aws_local dynamodb describe-table --table-name "$t" >/dev/null 2>&1; then
    echo "Table $t is gone. The scores are the product; repair, don't recreate."
    exit 1
  fi
done
if [ "$(aws_local dynamodb get-item --table-name orbit-workouts --key '{"workoutId":{"S":"w-0001"}}' --query Item.points.N --output text 2>/dev/null)" != "4200" ] \
   || [ "$(aws_local dynamodb get-item --table-name orbit-leaderboard --key '{"userId":{"S":"u-maya"}}' --query Item.score.N --output text 2>/dev/null)" != "4200" ]; then
  echo "Existing data was lost: the original workout w-0001 or Maya's 4200 score is missing."
  exit 1
fi

# Stage 1: is there a stream, and does it carry what the updater reads?
spec="$(aws_local dynamodb describe-table --table-name orbit-workouts --query 'Table.StreamSpecification' --output json 2>/dev/null || echo null)"
enabled="$(printf '%s' "$spec" | jq -r '.StreamEnabled // false')"
view="$(printf '%s' "$spec" | jq -r '.StreamViewType // "none"')"
if [ "$enabled" != "true" ]; then
  echo "[FAULT] stage 1  orbit-workouts has no stream"
  bad=$((bad + 1))
elif [ "$view" != "NEW_IMAGE" ] && [ "$view" != "NEW_AND_OLD_IMAGES" ]; then
  echo "[FAULT] stage 1  the stream is on, but its records do not carry the new item (view type $view)"
  bad=$((bad + 1))
else
  echo "[ok]    stage 1  orbit-workouts streams new images"
fi

# Stage 2: is the function subscribed to the stream that exists *now*?
cur="$(aws_local dynamodb describe-table --table-name orbit-workouts --query 'Table.LatestStreamArn' --output text 2>/dev/null || echo None)"
mapped="$(aws_local lambda list-event-source-mappings --function-name "$FN" \
  --query "EventSourceMappings[?EventSourceArn=='$cur' && State=='Enabled'] | length(@)" --output text 2>/dev/null || echo 0)"
if [ "$cur" = "None" ] || [ "$mapped" = "0" ]; then
  echo "[FAULT] stage 2  $FN is not consuming the table's current stream"
  bad=$((bad + 1))
else
  echo "[ok]    stage 2  $FN consumes the current stream"
fi

# Stage 3: does the function succeed on a stream-shaped record?
event='{"Records":[{"eventName":"INSERT","dynamodb":{"NewImage":{"userId":{"S":"u-probe"},"points":{"N":"7"}}}}]}'
out="$(mktemp)"
aws_local lambda invoke --function-name "$FN" --cli-binary-format raw-in-base64-out --payload "$event" "$out" >/dev/null 2>&1 || true
errmsg="$(jq -r '.errorMessage // empty' "$out" 2>/dev/null || true)"
rm -f "$out"
env_table="$(aws_local lambda get-function-configuration --function-name "$FN" --query 'Environment.Variables.LEADERBOARD_TABLE' --output text 2>/dev/null || echo None)"
if ! aws_local dynamodb describe-table --table-name "$env_table" >/dev/null 2>&1; then
  echo "[FAULT] stage 3a the function is configured to update a table ('$env_table') that does not exist"
  bad=$((bad + 1))
else
  echo "[ok]    stage 3a function targets an existing table"
fi
if printf '%s' "$errmsg" | grep -qi 'AccessDenied\|not authorized'; then
  echo "[FAULT] stage 3b the function runs but DynamoDB refuses its write: $(printf '%s' "$errmsg" | cut -c1-120)"
  bad=$((bad + 1))
elif [ -n "$errmsg" ] && aws_local dynamodb describe-table --table-name "$env_table" >/dev/null 2>&1; then
  echo "[FAULT] stage 3b the function fails on a stream record: $(printf '%s' "$errmsg" | cut -c1-120)"
  bad=$((bad + 1))
else
  echo "[ok]    stage 3b function can apply a record (when its config is right)"
fi
aws_local dynamodb delete-item --table-name orbit-leaderboard --key '{"userId":{"S":"u-probe"}}' >/dev/null 2>&1 || true

# Guardrail: the updater must not become a table admin.
if aws_local iam get-role-policy --role-name orbit-updater-role --policy-name leaderboard-write --query 'PolicyDocument' --output json 2>/dev/null | grep -q '"\*"'; then
  echo "BLOCKER: the updater's policy now contains a wildcard. It only needs the leaderboard table."
  exit 1
fi
if [ "$bad" -gt 0 ]; then
  echo "$bad stage(s) broken. No live workout logged yet."
  exit 1
fi

# Live test.
wid="w-$(date +%s)"
aws_local dynamodb put-item --table-name orbit-workouts \
  --item "{\"workoutId\":{\"S\":\"$wid\"},\"userId\":{\"S\":\"u-kofi\"},\"points\":{\"N\":\"350\"}}" >/dev/null
scored() { [ "$(aws_local dynamodb get-item --table-name orbit-leaderboard --key '{"userId":{"S":"u-kofi"}}' --query Item.score.N --output text 2>/dev/null)" -ge 350 ]; }
if ! wait_for "Kofi's score" 50 scored; then
  echo "A workout was logged but no score appeared within 50s. Everything looked right in isolation; check whether the mapping actually delivers."
  exit 1
fi
echo "A new workout flowed stream -> Lambda -> leaderboard. The challenge board is moving again."
