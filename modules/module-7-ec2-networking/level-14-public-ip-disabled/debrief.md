# Debrief: three kinds of address

- **Private IP**: always present, only routable inside the VPC.
- **Auto-assigned public IP**: handed out at launch when the subnet's `MapPublicIpOnLaunch` (or the launch request) says so. It is released when the instance stops, so the address changes on restart. Changing the subnet flag does nothing for instances that already exist.
- **Elastic IP**: a static public address allocated to your account, associated to an instance or network interface, and kept across stop/start until you release it.

A correct route table and IGW are not enough: the instance also needs *some* public address, otherwise the IGW has nothing to translate to.

Real-world tips:
- Elastic IPs that are allocated but unassociated cost money. Release what you do not use.
- For anything customer-facing, prefer a load balancer or CloudFront with DNS; reserve Elastic IPs for cases like partner allow-lists.
- Public IPv4 addresses are billed hourly, so private subnets plus NAT or endpoints are cheaper at scale.
