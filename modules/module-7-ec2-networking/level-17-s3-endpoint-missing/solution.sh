#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=quartz-vpc --query 'Vpcs[0].VpcId' --output text)
PRIV=$(aws_local ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC" Name=tag:Name,Values=quartz-private --query 'RouteTables[0].RouteTableId' --output text)
cat > endpoint-policy.json <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
    "Resource": ["arn:aws:s3:::quartz-exports", "arn:aws:s3:::quartz-exports/*"]
  }]
}
JSON
aws_local ec2 create-vpc-endpoint --vpc-id "$VPC" --vpc-endpoint-type Gateway \
  --service-name com.amazonaws.us-east-1.s3 --route-table-ids "$PRIV" \
  --policy-document file://endpoint-policy.json >/dev/null
