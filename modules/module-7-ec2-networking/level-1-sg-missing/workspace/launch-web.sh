#!/usr/bin/env bash
# Runbook: launch one storefront web server (Tindle Books).
SUBNET=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=tindle-public-a \
  --query 'Subnets[0].SubnetId' --output text)

aws ec2 run-instances \
  --image-id ami-alpine \
  --instance-type t3.micro \
  --subnet-id "$SUBNET" \
  --security-group-ids sg-0a11c0de5afe0001 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=tindle-web-1}]'
