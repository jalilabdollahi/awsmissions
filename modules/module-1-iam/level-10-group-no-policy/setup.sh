#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://ticket-attachments >/dev/null
seed="$(mktemp)"
trap 'rm -f "$seed"' EXIT
echo 'screenshot' > "$seed"
aws_local s3api put-object --bucket ticket-attachments --key tickets/PP-1042/screen.png --body "$seed" >/dev/null

BUCKET_OBJ='arn:aws:s3:::ticket-attachments/*'
BUCKET='arn:aws:s3:::ticket-attachments'
aws_local iam create-policy --policy-name attachments-viewer --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"s3:ListBucket\"],\"Resource\":\"$BUCKET\"},{\"Effect\":\"Allow\",\"Action\":[\"s3:GetObject\"],\"Resource\":\"$BUCKET_OBJ\"}]}" >/dev/null
aws_local iam create-policy --policy-name attachments-agent --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"s3:ListBucket\"],\"Resource\":\"$BUCKET\"},{\"Effect\":\"Allow\",\"Action\":[\"s3:GetObject\",\"s3:PutObject\"],\"Resource\":\"$BUCKET_OBJ\"}]}" >/dev/null
aws_local iam create-policy --policy-name attachments-owner --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"s3:*\",\"Resource\":[\"$BUCKET\",\"$BUCKET_OBJ\"]}]}" >/dev/null

aws_local iam create-group --group-name helpdesk-agents >/dev/null
for u in dana-helpdesk omar-helpdesk; do
  aws_local iam create-user --user-name "$u" >/dev/null
  aws_local iam add-user-to-group --group-name helpdesk-agents --user-name "$u"
done

echo "helpdesk-agents has two members and no permissions."
