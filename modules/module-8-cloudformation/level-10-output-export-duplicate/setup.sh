#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Consumers before producers so exports can be released.
for s in quayside-reports quayside-web quayside-network; do
  aws_local cloudformation delete-stack --stack-name "$s" >/dev/null 2>&1 || true
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/network.yaml" <<'TEMPLATE'
AWSTemplateFormatVersion: "2010-09-09"
Resources:
  AssetsBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: quayside-shared-assets
Outputs:
  AssetsBucketName:
    Value: !Ref AssetsBucket
    Export:
      Name: quayside-assets-bucket
TEMPLATE
cat > "$tmp/web.yaml" <<'TEMPLATE'
AWSTemplateFormatVersion: "2010-09-09"
Resources:
  WebAssetsParam:
    Type: AWS::SSM::Parameter
    Properties:
      Name: /quayside/web/assets-bucket
      Type: String
      Value: !ImportValue quayside-assets-bucket
TEMPLATE

aws_local cloudformation create-stack --stack-name quayside-network --template-body "file://$tmp/network.yaml" >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name quayside-network
aws_local cloudformation create-stack --stack-name quayside-web --template-body "file://$tmp/web.yaml" >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name quayside-web

echo "quayside-network and quayside-web are live. The reporting stack template is in your workspace."
