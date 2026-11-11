#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudformation delete-stack --stack-name crescent-platform >/dev/null 2>&1 || true

aws_local s3 mb s3://crescent-templates >/dev/null
child="$(mktemp)"
trap 'rm -f "$child"' EXIT
cat > "$child" <<'TEMPLATE'
AWSTemplateFormatVersion: "2010-09-09"
Description: Crescent Payments alerting child stack
Parameters:
  TeamName:
    Type: String
    Description: Lower-case team name used to name the topic
Resources:
  AlertTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: !Sub "crescent-${TeamName}-alerts"
Outputs:
  AlertTopicArn:
    Description: ARN of the team's alert topic
    Value: !Ref AlertTopic
TEMPLATE
aws_local s3api put-object --bucket crescent-templates --key shared/alerting/topic-stack.yaml \
  --body "$child" >/dev/null

# The pipeline's first run, which failed.
aws_local cloudformation create-stack --stack-name crescent-platform \
  --template-body "file://$MISSION_DIR/workspace/template.yaml" >/dev/null || true
wait_for "crescent-platform failure" 30 sh -c \
  "aws --endpoint-url=$AWS_ENDPOINT_URL cloudformation describe-stacks --stack-name crescent-platform --query 'Stacks[0].StackStatus' --output text | grep -Eq 'ROLLBACK_COMPLETE|CREATE_FAILED'"

echo "crescent-platform is stuck in a failed state. The child template sits in s3://crescent-templates."
