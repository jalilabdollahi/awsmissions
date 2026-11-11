#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

LIVE=$(aws_local ec2 describe-instances --filters Name=tag:Name,Values=atlas-bastion \
  Name=instance-state-name,Values=pending,running --output json)
SUBNET=$(aws_local ec2 describe-subnets --filters Name=tag:Name,Values=atlas-public --query 'Subnets[0].SubnetId' --output text)
SG=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=atlas-bastion-sg --query 'SecurityGroups[0].GroupId' --output text)
KEYS=$(aws_local ec2 describe-key-pairs --query 'KeyPairs[].KeyName' --output text)

LIVE="$LIVE" KEYS="$KEYS" SUBNET="$SUBNET" SG="$SG" python3 -c '
import json, os, sys
inst = [i for r in json.loads(os.environ["LIVE"])["Reservations"] for i in r["Instances"]]
keys = os.environ["KEYS"].split()
if "platform-ops" not in keys:
    print("The platform-ops key pair has been deleted. It is the team key and has to stay."); sys.exit(1)
if not inst:
    print("No atlas-bastion is running. Launch the replacement before removing the old one."); sys.exit(1)
keyless = [i["InstanceId"] for i in inst if not i.get("KeyName")]
if keyless:
    print("Still running without a key pair: %s. Terminate the keyless bastion." % ", ".join(keyless)); sys.exit(1)
if len(inst) > 1:
    print("%d atlas-bastion instances are alive. Keep exactly one." % len(inst)); sys.exit(1)
i = inst[0]
if i["KeyName"] != "platform-ops":
    print("The bastion boots with key pair %r. The team uses platform-ops." % i["KeyName"]); sys.exit(1)
if i["SubnetId"] != os.environ["SUBNET"]:
    print("The new bastion is not in the atlas-public subnet."); sys.exit(1)
if [g["GroupId"] for g in i["SecurityGroups"]] != [os.environ["SG"]]:
    print("The new bastion must use atlas-bastion-sg and only that group."); sys.exit(1)
' || exit 1
echo "atlas-bastion boots with platform-ops in atlas-public behind atlas-bastion-sg; the keyless one is gone."
