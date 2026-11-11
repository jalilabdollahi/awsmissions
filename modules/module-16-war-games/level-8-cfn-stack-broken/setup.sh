#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# CloudFormation stacks survive an emulator state reset, but their resources do not, which leaves
# stale stacks stuck in DELETE_FAILED. Put the physical resources back, then delete the stacks.
stale="$(mktemp -d)"
trap 'rm -rf "$stale"' EXIT
aws_local sqs create-queue --queue-name cobalt-orders-legacy >/dev/null 2>&1 || true
aws_local dynamodb create-table --table-name cobalt-ledger --attribute-definitions AttributeName=entryId,AttributeType=S \
  --key-schema AttributeName=entryId,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null 2>&1 || true
aws_local iam create-role --role-name cobalt-ledger-fn-role --assume-role-policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1 || true
printf 'def handler(e, c):\n    return {}\n' > "$stale/index.py"
python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1],'w').write(sys.argv[2],'index.py')" "$stale/z.zip" "$stale/index.py"
aws_local lambda create-function --function-name cobalt-ledger-fn --runtime python3.12 --handler index.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/cobalt-ledger-fn-role" --zip-file "fileb://$stale/z.zip" >/dev/null 2>&1 || true
for s in cobalt-orders cobalt-core; do
  aws_local cloudformation delete-stack --stack-name "$s" >/dev/null 2>&1 || true
done
gone() { ! aws_local cloudformation describe-stacks --stack-name "$1" >/dev/null 2>&1; }
wait_for "stale cobalt-orders to disappear" 30 gone cobalt-orders
wait_for "stale cobalt-core to disappear" 30 gone cobalt-core
# Remove whatever the stale cleanup left behind so the scenario starts from nothing.
aws_local dynamodb delete-table --table-name cobalt-ledger >/dev/null 2>&1 || true
aws_local lambda delete-function --function-name cobalt-ledger-fn >/dev/null 2>&1 || true
aws_local iam delete-role --role-name cobalt-ledger-fn-role >/dev/null 2>&1 || true
aws_local sqs delete-queue --queue-url "$AWS_ENDPOINT_URL/${ACCOUNT_ID}/cobalt-orders-legacy" >/dev/null 2>&1 || true

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp" "$stale"' EXIT
cat > "$tmp/core.yaml" <<'YAML'
Resources:
  LegacyOrders:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: cobalt-orders-legacy
Outputs:
  OrdersQueueArn:
    Value: !GetAtt LegacyOrders.Arn
    Export:
      Name: cobalt-orders-queue-arn
YAML
aws_local cloudformation create-stack --stack-name cobalt-core --template-body "file://$tmp/core.yaml" >/dev/null
settled() { s="$(aws_local cloudformation describe-stacks --stack-name "$1" --query 'Stacks[0].StackStatus' --output text 2>/dev/null)"; case "$s" in *IN_PROGRESS*|"") return 1 ;; esac; }
wait_for "cobalt-core to finish creating" 30 settled cobalt-core

# The migration stack collides with the legacy export and ends up CREATE_FAILED, resources and all.
aws_local cloudformation create-stack --stack-name cobalt-orders \
  --template-body "file://$MISSION_DIR/workspace/orders-stack.yaml" --capabilities CAPABILITY_NAMED_IAM >/dev/null
wait_for "cobalt-orders to finish" 30 settled cobalt-orders

# Finance has already started using the table.
aws_local dynamodb put-item --table-name cobalt-ledger --item '{"entryId":{"S":"E-1"},"amount":{"N":"125000"},"memo":{"S":"opening balance"}}' >/dev/null

echo "INC-3318 is open: cobalt-orders is stuck and the ledger table already holds real data."
