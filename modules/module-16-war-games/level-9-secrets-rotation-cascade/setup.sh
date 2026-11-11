#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The database side already moved to the new password.
aws_local ssm put-parameter --name /juniper/db/live-password --type SecureString --value 'Tr0ub4dor&Meadow-2026' >/dev/null
aws_local secretsmanager create-secret --name juniper/prod/billing-api-key --secret-string '{"key":"bill-live-81234"}' >/dev/null

# The original secret, which the app was built around.
OLD_ARN="$(aws_local secretsmanager create-secret --name juniper/prod/db-credentials \
  --secret-string '{"username":"claims_app","password":"Winter-Pigeon-2025"}' --query ARN --output text)"
# The failed rotation "fix": delete the secret outright and create it again under the same name.
aws_local secretsmanager delete-secret --secret-id juniper/prod/db-credentials --force-delete-without-recovery >/dev/null
aws_local secretsmanager create-secret --name juniper/prod/db-credentials \
  --secret-string '{"username":"claims_app","password":"Winter-Pigeon-2025"}' >/dev/null
aws_local secretsmanager put-secret-value --secret-id juniper/prod/db-credentials \
  --secret-string '{"username":"claims_app","password":"Tr0ub4dor&Meadow-2026"}' --version-stages AWSPENDING >/dev/null

aws_local iam create-user --user-name jn-oncall >/dev/null
aws_local iam put-user-policy --user-name jn-oncall --policy-name assume-claims \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::${ACCOUNT_ID}:role/juniper-claims-role\"}]}"
aws_local iam create-role --role-name juniper-claims-role --assume-role-policy-document "{
  \"Version\":\"2012-10-17\",\"Statement\":[
   {\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"},
   {\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::${ACCOUNT_ID}:user/jn-oncall\"},\"Action\":\"sts:AssumeRole\"}]}" >/dev/null
aws_local iam put-role-policy --role-name juniper-claims-role --policy-name claims-secrets --policy-document "{
  \"Version\":\"2012-10-17\",\"Statement\":[
   {\"Sid\":\"ReadDbSecret\",\"Effect\":\"Allow\",\"Action\":\"secretsmanager:GetSecretValue\",\"Resource\":\"$OLD_ARN\"},
   {\"Sid\":\"ReadLiveMirror\",\"Effect\":\"Allow\",\"Action\":\"ssm:GetParameter\",\"Resource\":\"arn:aws:ssm:us-east-1:${ACCOUNT_ID}:parameter/juniper/db/live-password\"}]}"

cat > "$tmp/claims.py" <<'PY'
import json
import os
import boto3

def handler(event, context):
    secret = json.loads(
        boto3.client("secretsmanager").get_secret_value(SecretId=os.environ["SECRET_ID"])["SecretString"]
    )
    live = boto3.client("ssm").get_parameter(
        Name="/juniper/db/live-password", WithDecryption=True)["Parameter"]["Value"]
    if secret["password"] != live:
        raise Exception("password authentication failed for user " + secret["username"])
    return {"db": "authenticated", "user": secret["username"]}
PY
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],'claims.py')" "$tmp/c.zip" "$tmp/claims.py"
aws_local lambda create-function --function-name juniper-claims-api --runtime python3.12 --handler claims.handler \
  --timeout 10 --role "arn:aws:iam::${ACCOUNT_ID}:role/juniper-claims-role" --zip-file "fileb://$tmp/c.zip" \
  --environment "Variables={SECRET_ID=$OLD_ARN}" >/dev/null
aws_local lambda wait function-active-v2 --function-name juniper-claims-api 2>/dev/null || sleep 2

echo "INC-9004 is open: the claims API cannot authenticate to its database."
