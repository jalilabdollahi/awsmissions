#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

NOTES_KEY="$(aws_local kms create-key --description "patient notes" --query KeyMetadata.KeyId --output text)"
aws_local kms create-alias --alias-name alias/vl-patient-notes --target-key-id "$NOTES_KEY"
OLD_KEY="$(aws_local kms create-key --description "retired 2024 notes key" --query KeyMetadata.KeyId --output text)"
aws_local kms create-alias --alias-name alias/vl-notes-2024 --target-key-id "$OLD_KEY"
BILL_KEY="$(aws_local kms create-key --description "finance" --query KeyMetadata.KeyId --output text)"
aws_local kms create-alias --alias-name alias/vl-billing --target-key-id "$BILL_KEY"

# Encrypt the clinic's first note while the key is healthy, then park it in DynamoDB.
ct="$(aws_local kms encrypt --key-id alias/vl-patient-notes --plaintext "$(printf 'Patient reports mild headache, advise rest.' | base64)" \
  --query CiphertextBlob --output text)"
aws_local dynamodb create-table --table-name vl-vault --attribute-definitions AttributeName=noteId,AttributeType=S \
  --key-schema AttributeName=noteId,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null
aws_local dynamodb put-item --table-name vl-vault --item "{\"noteId\":{\"S\":\"n-1\"},\"ct\":{\"S\":\"$ct\"}}" >/dev/null
bct="$(aws_local kms encrypt --key-id alias/vl-billing --plaintext "$(printf 'invoice-run' | base64)" --query CiphertextBlob --output text)"
aws_local dynamodb put-item --table-name vl-vault --item "{\"noteId\":{\"S\":\"bill-1\"},\"ct\":{\"S\":\"$bct\"}}" >/dev/null

aws_local iam create-user --user-name vl-oncall >/dev/null
aws_local iam put-user-policy --user-name vl-oncall --policy-name assume-reader --policy-document \
  "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::${ACCOUNT_ID}:role/vl-reader-role\"}]}"
aws_local iam create-role --role-name vl-reader-role --assume-role-policy-document "{
  \"Version\":\"2012-10-17\",\"Statement\":[
   {\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"},
   {\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::${ACCOUNT_ID}:user/vl-oncall\"},\"Action\":\"sts:AssumeRole\"}]}" >/dev/null
# Last year's setup: Decrypt only, and only on the retired key.
aws_local iam put-role-policy --role-name vl-reader-role --policy-name reader --policy-document "{
  \"Version\":\"2012-10-17\",\"Statement\":[
   {\"Sid\":\"Vault\",\"Effect\":\"Allow\",\"Action\":\"dynamodb:GetItem\",\"Resource\":\"arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/vl-vault\"},
   {\"Sid\":\"Kms\",\"Effect\":\"Allow\",\"Action\":\"kms:Decrypt\",\"Resource\":\"arn:aws:kms:us-east-1:${ACCOUNT_ID}:key/$OLD_KEY\"}]}"

cat > "$tmp/reader.py" <<'PY'
import base64
import os
import boto3

def handler(event, context):
    kms = boto3.client("kms")
    item = boto3.client("dynamodb").get_item(
        TableName="vl-vault", Key={"noteId": {"S": event["noteId"]}})["Item"]
    plain = kms.decrypt(CiphertextBlob=base64.b64decode(item["ct"]["S"]))["Plaintext"]
    archived = kms.encrypt(KeyId=os.environ["KEY_ALIAS"], Plaintext=plain)["CiphertextBlob"]
    return {"note": plain.decode(), "archived_bytes": len(archived)}
PY
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],'reader.py')" "$tmp/r.zip" "$tmp/reader.py"
aws_local lambda create-function --function-name vl-note-reader --runtime python3.12 --handler reader.handler \
  --timeout 10 --role "arn:aws:iam::${ACCOUNT_ID}:role/vl-reader-role" --zip-file "fileb://$tmp/r.zip" \
  --environment 'Variables={KEY_ALIAS=alias/vl-patient-note}' >/dev/null
aws_local lambda wait function-active-v2 --function-name vl-note-reader 2>/dev/null || sleep 2

# The hygiene sweep.
aws_local kms schedule-key-deletion --key-id "$NOTES_KEY" --pending-window-in-days 7 >/dev/null

echo "INC-7702 is open: the notes key is scheduled for deletion and the reader is misconfigured."
