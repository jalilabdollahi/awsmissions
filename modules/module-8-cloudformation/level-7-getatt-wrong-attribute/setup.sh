#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudformation delete-stack --stack-name orchard-reporting >/dev/null 2>&1 || true

aws_local s3 mb s3://orchard-payroll >/dev/null
aws_local iam create-user --user-name report-bot >/dev/null
aws_local iam put-user-policy --user-name report-bot --policy-name assume-reporter \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"arn:aws:iam::${ACCOUNT_ID}:role/orchard-reporter\"}]}"

# Release 1 is what production runs today.
release1="$(mktemp)"
trap 'rm -f "$release1"' EXIT
cat > "$release1" <<TEMPLATE
AWSTemplateFormatVersion: "2010-09-09"
Description: Orchard Analytics reporting, release 1
Resources:
  ReportsBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: orchard-reports
  ReporterRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: orchard-reporter
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              AWS: arn:aws:iam::${ACCOUNT_ID}:user/report-bot
            Action: sts:AssumeRole
      Policies:
        - PolicyName: upload-reports
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action: s3:PutObject
                Resource: !Join ["/", [!GetAtt ReportsBucket.Arn, "*"]]
TEMPLATE
aws_local cloudformation create-stack --stack-name orchard-reporting \
  --template-body "file://$release1" --capabilities CAPABILITY_NAMED_IAM >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name orchard-reporting

echo "orchard-reporting runs release 1. Release 2 is waiting in your workspace."
