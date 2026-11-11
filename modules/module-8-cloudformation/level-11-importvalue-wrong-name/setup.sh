#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for s in ledgerline-auditor ledgerline-platform-prod ledgerline-platform-staging; do
  aws_local cloudformation delete-stack --stack-name "$s" >/dev/null 2>&1 || true
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for env in prod staging; do
  cat > "$tmp/$env.yaml" <<TEMPLATE
AWSTemplateFormatVersion: "2010-09-09"
Resources:
  AuditTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: ledgerline-${env}-audit
  AuditBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: ledgerline-${env}-audit-log
Outputs:
  AuditTopicArn:
    Value: !Ref AuditTopic
    Export:
      Name: ledgerline-${env}-audit-topic-arn
  AuditBucketName:
    Value: !Ref AuditBucket
    Export:
      Name: ledgerline-${env}-audit-bucket-name
TEMPLATE
  aws_local cloudformation create-stack --stack-name "ledgerline-platform-$env" \
    --template-body "file://$tmp/$env.yaml" >/dev/null
  aws_local cloudformation wait stack-create-complete --stack-name "ledgerline-platform-$env"
done

echo "Both platform stacks are deployed. The auditor template is in your workspace."
