# Solution

Rule 90 (deny TCP 80 from anywhere) is evaluated before rule 100 (allow TCP 80), and the first match wins, so the allow never gets a chance. The rule added for the abuse incident was meant to cover only `198.51.100.0/24`, which rule 50 already does.

```bash
NACL=$(aws ec2 describe-network-acls --query "NetworkAcls[?Tags[?Value=='lumen-web-nacl']]|[0].NetworkAclId" --output text)
aws ec2 describe-network-acls --network-acl-ids $NACL --query 'NetworkAcls[0].Entries'
aws ec2 delete-network-acl-entry --network-acl-id $NACL --ingress --rule-number 90
```

Do not remove rule 50 (the abuse block) and do not swap the subnet to the default ACL.
