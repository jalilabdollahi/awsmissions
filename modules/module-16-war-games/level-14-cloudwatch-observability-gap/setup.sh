#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
SQS="arn:aws:sqs:us-east-1:${ACCOUNT_ID}"

aws_local iam create-role --role-name tf-checkout-role --assume-role-policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
cat > "$tmp/checkout.py" <<'PY'
import json

def handler(event, context):
    order = event.get("order", "o-0000")
    if event.get("fail"):
        print(json.dumps({"level": "ERROR", "order": order, "code": "CARD_DECLINED", "msg": "payment failed"}))
        return {"status": "declined"}
    print(json.dumps({"level": "INFO", "order": order, "msg": "charged"}))
    return {"status": "charged"}
PY
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],'checkout.py')" "$tmp/c.zip" "$tmp/checkout.py"
aws_local lambda create-function --function-name tf-checkout-fn --runtime python3.12 --handler checkout.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/tf-checkout-role" --zip-file "fileb://$tmp/c.zip" >/dev/null
aws_local lambda wait function-active-v2 --function-name tf-checkout-fn 2>/dev/null || sleep 2
# Warm the function so its log group exists, as it would in production.
aws_local lambda invoke --function-name tf-checkout-fn --cli-binary-format raw-in-base64-out \
  --payload '{"order":"o-warmup"}' "$tmp/out.json" >/dev/null

aws_local logs create-log-group --log-group-name /aws/lambda/tf-checkout-fn-old >/dev/null

aws_local sqs create-queue --queue-name tf-oncall-inbox >/dev/null
OPS="$(aws_local sns create-topic --name tf-oncall --query TopicArn --output text)"
aws_local sns subscribe --topic-arn "$OPS" --protocol sqs --notification-endpoint "$SQS:tf-oncall-inbox" >/dev/null
DEV="$(aws_local sns create-topic --name tf-alerts-dev --query TopicArn --output text)"

# Filter: old log group, draft field name, plural namespace.
aws_local logs put-metric-filter --log-group-name /aws/lambda/tf-checkout-fn-old --filter-name checkout-errors \
  --filter-pattern '{ $.severity = "ERROR" }' \
  --metric-transformations metricName=CheckoutFailures,metricNamespace=TF/Checkouts,metricValue=1
# Alarm: copied from staging, so it pages the sandbox topic.
aws_local cloudwatch put-metric-alarm --alarm-name tf-checkout-errors \
  --namespace TF/Checkout --metric-name CheckoutFailures --statistic Sum \
  --period 10 --evaluation-periods 1 --threshold 5 --comparison-operator GreaterThanOrEqualToThreshold \
  --treat-missing-data notBreaching --alarm-actions "$DEV"

echo "PM-2026-31 follow-up opened: checkout failures never reach the pager."
