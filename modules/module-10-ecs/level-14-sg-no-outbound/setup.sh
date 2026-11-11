#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 create-vpc --cidr-block 10.200.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=slate-isolated}]' --query Vpc.VpcId --output text)
S1=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.200.1.0/24 --availability-zone us-east-1a --query Subnet.SubnetId --output text)
S2=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.200.2.0/24 --availability-zone us-east-1b --query Subnet.SubnetId --output text)
VPCE_SG=$(aws_local ec2 create-security-group --group-name slate-vpce-sg --description "slate interface endpoints" --vpc-id "$VPC" --query GroupId --output text)
TASK_SG=$(aws_local ec2 create-security-group --group-name slate-task-sg --description "slate-reports tasks" --vpc-id "$VPC" --query GroupId --output text)

# Stale trust: a subnet that no longer exists.
aws_local ec2 authorize-security-group-ingress --group-id "$VPCE_SG" --protocol tcp --port 443 --cidr 10.200.99.0/24 >/dev/null
# Hardening: remove the default allow-all egress from the task group.
aws_local ec2 revoke-security-group-egress --group-id "$TASK_SG" --ip-permissions 'IpProtocol=-1,IpRanges=[{CidrIp=0.0.0.0/0}]' >/dev/null

for svc in ecr.api ecr.dkr logs secretsmanager; do
  aws_local ec2 create-vpc-endpoint --vpc-id "$VPC" --vpc-endpoint-type Interface \
    --service-name "com.amazonaws.us-east-1.$svc" --subnet-ids "$S1" "$S2" --security-group-ids "$VPCE_SG" >/dev/null
done

cat > /tmp/awsm-slate-$$.json <<'JSON'
{
  "family": "slate-reports",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [{"name": "reports", "image": "alpine:3.21", "essential": true,
    "command": ["sh", "-c", "echo slate-reports generating; sleep 3600"]}]
}
JSON
aws_local ecs create-cluster --cluster-name slate >/dev/null
aws_local ecs register-task-definition --cli-input-json "file:///tmp/awsm-slate-$$.json" >/dev/null
rm -f /tmp/awsm-slate-$$.json
aws_local ecs create-service --cluster slate --service-name slate-reports --task-definition slate-reports:1 --desired-count 1 \
  --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$S1],securityGroups=[$TASK_SG],assignPublicIp=DISABLED}" >/dev/null
echo "slate-task-sg has no egress; slate-vpce-sg trusts a dead subnet."
