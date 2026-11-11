#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

stacks="kestrel-pr-731 kestrel-pr-742 kestrel-prod-core"
for s in $stacks; do
  aws_local cloudformation update-termination-protection --stack-name "$s" \
    --no-enable-termination-protection >/dev/null 2>&1 || true
  aws_local cloudformation delete-stack --stack-name "$s" >/dev/null 2>&1 || true
done

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
for s in $stacks; do
  cat > "$tmp" <<TEMPLATE
AWSTemplateFormatVersion: "2010-09-09"
Resources:
  Artifacts:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: ${s}-artifacts
  Notices:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: ${s}-notices
TEMPLATE
  aws_local cloudformation create-stack --stack-name "$s" --template-body "file://$tmp" >/dev/null
  aws_local cloudformation wait stack-create-complete --stack-name "$s"
  aws_local cloudformation update-termination-protection --stack-name "$s" \
    --enable-termination-protection >/dev/null
done

echo "Three stacks are deployed, all with termination protection on."
