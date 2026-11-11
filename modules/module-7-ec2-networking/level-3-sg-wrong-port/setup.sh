#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 create-vpc --cidr-block 10.40.0.0/16 --query Vpc.VpcId --output text)
ALB_SG=$(aws_local ec2 create-security-group --group-name ledger-alb-sg --description "ledger ALB" \
  --vpc-id "$VPC" --query GroupId --output text)
API_SG=$(aws_local ec2 create-security-group --group-name ledger-api-sg --description "ledger api" \
  --vpc-id "$VPC" --query GroupId --output text)
aws_local ec2 authorize-security-group-ingress --group-id "$ALB_SG" --protocol tcp --port 443 --cidr 0.0.0.0/0 >/dev/null

aws_local ssm put-parameter --name /ledger/api/listen-port --type String --value 3000 >/dev/null
aws_local ssm put-parameter --name /ledger/api/log-level --type String --value info >/dev/null

# The wrong guess: 8080 from the ALB group.
aws_local ec2 authorize-security-group-ingress --group-id "$API_SG" --protocol tcp --port 8080 --source-group "$ALB_SG" >/dev/null
echo "ledger-api-sg lets the ALB in on 8080; the service listens elsewhere."
