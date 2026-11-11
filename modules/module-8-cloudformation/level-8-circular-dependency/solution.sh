#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# The policy keeps its bucket restriction but spells the ARN out instead of
# asking CloudFormation for it, which removes the Policy -> Bucket edge.
sed 's|"aws:SourceArn": !GetAtt UploadsBucket.Arn|"aws:SourceArn": "arn:aws:s3:::granitepeak-uploads"|' \
  template.yaml > template.acyclic
mv template.acyclic template.yaml

if aws_local cloudformation create-stack --stack-name granitepeak-intake \
     --template-body file://template.yaml >/dev/null; then
  aws_local cloudformation wait stack-create-complete --stack-name granitepeak-intake
else
  echo "create-stack was rejected" >&2
  exit 1
fi
