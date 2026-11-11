#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. Fix the template: unique export, table name in the env var, a read policy for the role, Retain on the table.
python3 - <<'PY'
text = open("orders-stack.yaml").read()
text = text.replace("Name: cobalt-orders-queue-arn", "Name: cobalt-ledger-table-arn")
text = text.replace("TABLE_NAME: cobalt-ledgers", "TABLE_NAME: cobalt-ledger")
text = text.replace("            Action: sts:AssumeRole\n",
                    "            Action: sts:AssumeRole\n      Policies:\n        - PolicyName: read-ledger\n          PolicyDocument:\n            Version: \"2012-10-17\"\n            Statement:\n              - Effect: Allow\n                Action: dynamodb:Scan\n                Resource: !GetAtt LedgerTable.Arn\n")
text = text.replace("  LedgerTable:\n    Type: AWS::DynamoDB::Table\n",
                    "  LedgerTable:\n    Type: AWS::DynamoDB::Table\n    DeletionPolicy: Retain\n")
open("orders-stack.yaml", "w").write(text)
PY

# 2. Update the existing stack in place (do not delete it: the table holds real data).
aws_local cloudformation update-stack --stack-name cobalt-orders \
  --template-body file://orders-stack.yaml --capabilities CAPABILITY_NAMED_IAM >/dev/null
settled() { s="$(aws_local cloudformation describe-stacks --stack-name cobalt-orders --query 'Stacks[0].StackStatus' --output text)"; case "$s" in *IN_PROGRESS*) return 1 ;; esac; }
wait_for "cobalt-orders update" 40 settled
