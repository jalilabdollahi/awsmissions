#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 create-vpc --cidr-block 10.110.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=lumen-prod}]' --query Vpc.VpcId --output text)
SUBNET=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.110.1.0/24 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=lumen-web}]' --query Subnet.SubnetId --output text)
NACL=$(aws_local ec2 create-network-acl --vpc-id "$VPC" \
  --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=lumen-web-nacl}]' --query NetworkAcl.NetworkAclId --output text)

nacl_rule() {  # number action protocol cidr [from to] [egress]
  local flag=--ingress
  [ "${7:-}" = egress ] && flag=--egress
  if [ -n "${5:-}" ]; then
    aws_local ec2 create-network-acl-entry --network-acl-id "$NACL" --rule-number "$1" --rule-action "$2" \
      --protocol "$3" --cidr-block "$4" --port-range "From=$5,To=$6" $flag
  else
    aws_local ec2 create-network-acl-entry --network-acl-id "$NACL" --rule-number "$1" --rule-action "$2" \
      --protocol "$3" --cidr-block "$4" $flag
  fi
}
nacl_rule 50  deny  -1  198.51.100.0/24                 # abuse range
nacl_rule 90  deny  tcp 0.0.0.0/0 80 80                 # added "for the abuse incident"
nacl_rule 100 allow tcp 0.0.0.0/0 80 80
nacl_rule 110 allow tcp 0.0.0.0/0 443 443
nacl_rule 100 allow tcp 0.0.0.0/0 1024 65535 egress
# default-NACL association -> lumen-web-nacl
ASSOC=$(aws_local ec2 describe-network-acls --filters Name=association.subnet-id,Values="$SUBNET" \
  --query "NetworkAcls[0].Associations[?SubnetId=='$SUBNET'].NetworkAclAssociationId|[0]" --output text)
aws_local ec2 replace-network-acl-association --association-id "$ASSOC" --network-acl-id "$NACL" >/dev/null
echo "lumen-web-nacl is attached to lumen-web; port 80 is being dropped."
