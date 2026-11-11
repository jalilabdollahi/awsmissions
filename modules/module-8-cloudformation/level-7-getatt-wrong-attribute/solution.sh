#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# S3 buckets publish their ARN as "Arn"; swap the invented attribute name.
awk '{ gsub(/ArchiveBucket\.BucketArn/, "ArchiveBucket.Arn"); print }' template.yaml > template.next
mv template.next template.yaml

aws_local cloudformation update-stack --stack-name orchard-reporting \
  --template-body file://template.yaml --capabilities CAPABILITY_NAMED_IAM >/dev/null
aws_local cloudformation wait stack-update-complete --stack-name orchard-reporting
