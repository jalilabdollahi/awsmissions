#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for b in bluefin-invoices bluefin-digests bluefin-hr-records; do
  aws_local s3 mb "s3://$b" >/dev/null
done
seed="$(mktemp)"
build="$(mktemp -d)"
trap 'rm -rf "$seed" "$build"' EXIT
printf 'inv-1001,250.00\n' > "$seed"
aws_local s3api put-object --bucket bluefin-invoices --key 2025-11-10/inv-1001.csv --body "$seed" >/dev/null
printf 'inv-1002,410.50\n' > "$seed"
aws_local s3api put-object --bucket bluefin-invoices --key 2025-11-10/inv-1002.csv --body "$seed" >/dev/null
printf 'confidential\n' > "$seed"
aws_local s3api put-object --bucket bluefin-hr-records --key reviews/2025.txt --body "$seed" >/dev/null

cat > "$build/lambda_function.py" <<'PY'
import os
import boto3

endpoint = os.environ.get("AWS_ENDPOINT_URL")
s3 = boto3.client("s3", endpoint_url=endpoint)


def handler(event, context):
    listing = s3.list_objects_v2(Bucket="bluefin-invoices", Prefix="2025-11-10/")
    keys = [o["Key"] for o in listing.get("Contents", [])]
    total = 0.0
    for key in keys:
        body = s3.get_object(Bucket="bluefin-invoices", Key=key)["Body"].read().decode()
        total += float(body.strip().split(",")[1])
    s3.put_object(Bucket="bluefin-digests", Key="digest-2025-11-10.txt",
                  Body=("invoices=%d total=%.2f\n" % (len(keys), total)).encode())
    result = {"invoices": len(keys), "total": total}
    # Canary used by the mission checker: this must stay forbidden.
    try:
        s3.list_objects_v2(Bucket="bluefin-hr-records")
        result["hr_bucket_readable"] = True
    except Exception:
        result["hr_bucket_readable"] = False
    return result
PY
(cd "$build" && python3 -c "
import zipfile
z = zipfile.ZipFile('fn.zip', 'w'); z.write('lambda_function.py'); z.close()")

aws_local iam create-role --role-name invoice-digest-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local lambda create-function --function-name invoice-digest --runtime python3.12 \
  --handler lambda_function.handler --timeout 30 \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/invoice-digest-role" \
  --zip-file "fileb://$build/fn.zip" >/dev/null

echo "invoice-digest is deployed; invoke it and it fails."
