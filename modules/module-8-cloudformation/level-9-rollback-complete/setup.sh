#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Consumer first, then the exporter it imports from.
aws_local cloudformation delete-stack --stack-name saltmarsh-api >/dev/null 2>&1 || true
aws_local cloudformation delete-stack --stack-name saltmarsh-shared >/dev/null 2>&1 || true

# Friday's release: the api stack goes out BEFORE its dependency exists.
aws_local cloudformation create-stack --stack-name saltmarsh-api \
  --template-body "file://$MISSION_DIR/workspace/template.yaml" >/dev/null || true
wait_for "saltmarsh-api rollback" 30 sh -c \
  "aws --endpoint-url=$AWS_ENDPOINT_URL cloudformation describe-stacks --stack-name saltmarsh-api --query 'Stacks[0].StackStatus' --output text | grep -q ROLLBACK_COMPLETE"

shared="$(mktemp)"
trap 'rm -f "$shared"' EXIT
cat > "$shared" <<'TEMPLATE'
AWSTemplateFormatVersion: "2010-09-09"
Resources:
  AlertsTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: saltmarsh-pharmacy-alerts
Outputs:
  AlertsTopicArn:
    Value: !Ref AlertsTopic
    Export:
      Name: saltmarsh-alerts-topic-arn
TEMPLATE
aws_local cloudformation create-stack --stack-name saltmarsh-shared --template-body "file://$shared" >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name saltmarsh-shared

echo "saltmarsh-shared is healthy; saltmarsh-api is stuck in ROLLBACK_COMPLETE."
