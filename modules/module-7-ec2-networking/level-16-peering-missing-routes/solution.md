# Solution

Three things have to be true for peered VPCs to talk: the connection is *active*, **both** route tables send the peer's CIDR to it, and the destination's security group admits the source.

```bash
PCX=$(aws ec2 describe-vpc-peering-connections --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' --output text)
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $PCX

aws ec2 create-route --route-table-id <orders-private>  --destination-cidr-block 10.161.0.0/16 --vpc-peering-connection-id $PCX
aws ec2 create-route --route-table-id <billing-private> --destination-cidr-block 10.160.0.0/16 --vpc-peering-connection-id $PCX

aws ec2 authorize-security-group-ingress --group-id <billing-db-sg> --protocol tcp --port 5432 --cidr 10.160.0.0/16
aws ec2 revoke-security-group-ingress    --group-id <billing-db-sg> --protocol tcp --port 5432 --cidr 10.162.0.0/16
```
