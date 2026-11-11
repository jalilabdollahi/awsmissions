#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

aws_local dynamodb create-table --table-name orbit-workouts \
  --attribute-definitions AttributeName=workoutId,AttributeType=S \
  --key-schema AttributeName=workoutId,KeyType=HASH --billing-mode PAY_PER_REQUEST \
  --stream-specification StreamEnabled=true,StreamViewType=NEW_IMAGE >/dev/null
aws_local dynamodb create-table --table-name orbit-leaderboard \
  --attribute-definitions AttributeName=userId,AttributeType=S \
  --key-schema AttributeName=userId,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null
aws_local dynamodb put-item --table-name orbit-leaderboard \
  --item '{"userId":{"S":"u-maya"},"score":{"N":"4200"}}' >/dev/null
aws_local dynamodb put-item --table-name orbit-workouts \
  --item '{"workoutId":{"S":"w-0001"},"userId":{"S":"u-maya"},"points":{"N":"4200"}}' >/dev/null

# Role rewritten from the security template: PutItem only.
aws_local iam create-role --role-name orbit-updater-role --assume-role-policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name orbit-updater-role --policy-name leaderboard-write --policy-document "{
  \"Version\":\"2012-10-17\",\"Statement\":[
   {\"Effect\":\"Allow\",\"Action\":[\"dynamodb:PutItem\",\"dynamodb:GetItem\"],\"Resource\":\"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/orbit-leaderboard\"}]}"

cat > "$tmp/updater.py" <<'PY'
import os
import boto3

def handler(event, context):
    ddb = boto3.client("dynamodb")
    board = os.environ["LEADERBOARD_TABLE"]
    applied = 0
    for rec in event["Records"]:
        if rec["eventName"] != "INSERT":
            continue
        img = rec["dynamodb"]["NewImage"]
        ddb.update_item(
            TableName=board,
            Key={"userId": img["userId"]},
            UpdateExpression="ADD score :p",
            ExpressionAttributeValues={":p": {"N": img["points"]["N"]}},
        )
        applied += 1
    return {"applied": applied}
PY
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],'updater.py')" "$tmp/u.zip" "$tmp/updater.py"
aws_local lambda create-function --function-name orbit-leaderboard-updater --runtime python3.12 --handler updater.handler \
  --timeout 10 --role "arn:aws:iam::${ACCOUNT_ID}:role/orbit-updater-role" --zip-file "fileb://$tmp/u.zip" \
  --environment 'Variables={LEADERBOARD_TABLE=orbit-leaderboards}' >/dev/null
aws_local lambda wait function-active-v2 --function-name orbit-leaderboard-updater 2>/dev/null || sleep 2

# The mapping was created against the original stream...
STREAM="$(aws_local dynamodb describe-table --table-name orbit-workouts --query Table.LatestStreamArn --output text)"
aws_local lambda create-event-source-mapping --function-name orbit-leaderboard-updater \
  --event-source-arn "$STREAM" --starting-position LATEST --batch-size 1 >/dev/null
# ...then the "cost trim" switched streams off, and the rollback re-enabled them with keys only.
aws_local dynamodb update-table --table-name orbit-workouts --stream-specification StreamEnabled=false >/dev/null
sleep 1
aws_local dynamodb update-table --table-name orbit-workouts \
  --stream-specification StreamEnabled=true,StreamViewType=KEYS_ONLY >/dev/null

echo "ORBIT-1893 is open: workouts are logged, scores do not move."
