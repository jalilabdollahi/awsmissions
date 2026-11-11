# Solution

1. **Placement.** The service was copied from the old VPC: public subnet, `assignPublicIp=ENABLED`. Update it to use only `mt-private-a` (10.30.2.0/24), `mt-gateway-sg`, and `assignPublicIp=DISABLED`. Use `--force-new-deployment` so tasks are replaced.
2. **Route.** The private route table has only the local route. Add `0.0.0.0/0` via the NAT gateway `mt-nat` (`create-route --nat-gateway-id`). Routing to the internet gateway would make the subnet public.
3. **Egress.** Add `tcp/443` to `0.0.0.0/0` on `mt-gateway-sg`.
4. **Ingress.** Add `tcp/8080` from the source security group `mt-alb-sg` (a `UserIdGroupPairs` entry), not from a CIDR.

`check` looks at the service's configuration and at where its running tasks' network interfaces really are (it waits for the redeployment to finish), then examines the private route table and both directions of the security group. It rejects an internet-gateway route and any inbound rule open to 0.0.0.0/0.
