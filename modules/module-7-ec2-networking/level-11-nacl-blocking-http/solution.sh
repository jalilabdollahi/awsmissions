#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

NACL=$(aws_local ec2 describe-network-acls --query "NetworkAcls[?Tags[?Value=='lumen-web-nacl']]|[0].NetworkAclId" --output text)
aws_local ec2 delete-network-acl-entry --network-acl-id "$NACL" --ingress --rule-number 90
