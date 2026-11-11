#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SUBNET=$(aws_local ec2 describe-subnets --filters Name=tag:Name,Values=lumen-web --query 'Subnets[0].SubnetId' --output text)
ACL=$(aws_local ec2 describe-network-acls --filters Name=association.subnet-id,Values="$SUBNET" --output json)
ACL="$ACL" python3 -c '
import ipaddress, json, os, sys
acl = json.loads(os.environ["ACL"])["NetworkAcls"][0]
name = next((t["Value"] for t in acl.get("Tags", []) if t["Key"] == "Name"), "")
if name != "lumen-web-nacl":
    print("lumen-web is now associated with %s instead of lumen-web-nacl. Swapping to the default allow-all ACL throws away the abuse block." % (name or acl["NetworkAclId"])); sys.exit(1)

def decide(egress, proto, port, addr):
    """First matching rule, lowest number wins; implicit deny at 32767."""
    ip = ipaddress.ip_address(addr)
    for e in sorted((e for e in acl["Entries"] if e["Egress"] == egress), key=lambda e: e["RuleNumber"]):
        if ip not in ipaddress.ip_network(e["CidrBlock"]):
            continue
        if e["Protocol"] != "-1" and e["Protocol"] != proto:
            continue
        pr = e.get("PortRange")
        if e["Protocol"] != "-1" and pr and not pr["From"] <= port <= pr["To"]:
            continue
        return e["RuleAction"], e["RuleNumber"]
    return "deny", 32767

visitor, abuser = "203.0.113.50", "198.51.100.7"
for port, label in ((80, "HTTP"), (443, "HTTPS")):
    act, num = decide(False, "6", port, visitor)
    if act != "allow":
        print("Inbound %s (tcp/%d) from a normal visitor is still denied, by rule %d. NACL rules are evaluated lowest number first and the first match decides." % (label, port, num)); sys.exit(1)
    act, num = decide(False, "6", port, abuser)
    if act != "deny":
        print("The abuse range 198.51.100.0/24 can reach %s again (rule %d allows it). It has to stay blocked." % (label, num)); sys.exit(1)
act, num = decide(True, "6", 50000, visitor)
if act != "allow":
    print("Replies cannot leave: outbound ephemeral ports (1024-65535) are denied by rule %d. NACLs are stateless." % num); sys.exit(1)
for port in (22, 3306, 3389):
    act, num = decide(False, "6", port, visitor)
    if act == "allow":
        print("Inbound tcp/%d is open to the internet through rule %d. Only 80 and 443 belong here." % (port, num)); sys.exit(1)
' || exit 1
echo "lumen-web-nacl admits HTTP and HTTPS, still blocks the abuse range, and lets replies out."
