#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
FN_ARN="arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:mg-thumbnailer"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/mg-thumbnailer-role"

for b in mg-photo-uploads mg-photo-uploads-staging mg-photo-thumbs; do
  aws_local s3 mb "s3://$b" >/dev/null
done

aws_local iam create-user --user-name mg-oncall >/dev/null
aws_local iam put-user-policy --user-name mg-oncall --policy-name assume-thumbnailer \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"$ROLE_ARN\"}]}"
aws_local iam create-role --role-name mg-thumbnailer-role --assume-role-policy-document "{
  \"Version\":\"2012-10-17\",\"Statement\":[
   {\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"},
   {\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::${ACCOUNT_ID}:user/mg-oncall\"},\"Action\":\"sts:AssumeRole\"}]}" >/dev/null
# Cloned from the staging setup: reads are scoped to the staging bucket.
aws_local iam put-role-policy --role-name mg-thumbnailer-role --policy-name thumbnailer --policy-document '{
  "Version":"2012-10-17","Statement":[
   {"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::mg-photo-uploads-staging/*"},
   {"Effect":"Allow","Action":"s3:PutObject","Resource":"arn:aws:s3:::mg-photo-thumbs/*"}]}'

cat > "$tmp/thumb.py" <<'PY'
import os
import urllib.parse
import boto3

def handler(event, context):
    s3 = boto3.client("s3")
    made = []
    for rec in event["Records"]:
        bucket = rec["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(rec["s3"]["object"]["key"])
        data = s3.get_object(Bucket=bucket, Key=key)["Body"].read()
        small = data[: max(1, len(data) // 4)]
        out = "thumb-" + key.split("/")[-1]
        s3.put_object(Bucket=os.environ["THUMB_BUCKET"], Key=out, Body=small)
        made.append(out)
    return {"thumbnails": made}
PY
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],'thumb.py')" "$tmp/t.zip" "$tmp/thumb.py"
# The reorganisation renamed the thumbs bucket, but the function still says "mg-photo-thumb".
aws_local lambda create-function --function-name mg-thumbnailer --runtime python3.12 --handler thumb.handler \
  --timeout 15 --role "$ROLE_ARN" --zip-file "fileb://$tmp/t.zip" \
  --environment 'Variables={THUMB_BUCKET=mg-photo-thumb}' >/dev/null
aws_local lambda wait function-active-v2 --function-name mg-thumbnailer 2>/dev/null || sleep 3

# The trigger was cloned from staging: it sits on the staging bucket and filters on ".jpeg".
aws_local s3api put-bucket-notification-configuration --bucket mg-photo-uploads-staging \
  --notification-configuration "{\"LambdaFunctionConfigurations\":[{\"LambdaFunctionArn\":\"$FN_ARN\",\"Events\":[\"s3:ObjectCreated:*\"],\"Filter\":{\"Key\":{\"FilterRules\":[{\"Name\":\"suffix\",\"Value\":\".jpeg\"}]}}}]}"

echo "Gallery escalation #8841 is open: uploads land, thumbnails never appear."
