# INC-5561 - mt-gateway cannot be reached and cannot reach out (post-migration)

Meridian Transit (journey-planner backend). Platform networking on-call.

## Background
The `mt-gateway` ECS service moved last night from the shared default VPC into
its own VPC, `mt-vpc` (10.30.0.0/16), as part of the "tasks only live in
private subnets" security programme. Today the service is "up" in ECS but the
load balancer health checks fail and the container cannot pull updates.

## Target network design (signed off by security)
- Tasks run ONLY in the private subnet (10.30.2.0/24) and never get a public IP.
- The private subnet's route table sends internet-bound traffic (0.0.0.0/0)
  through the NAT gateway `mt-nat`, which sits in the public subnet
  (10.30.1.0/24). It must NOT send it directly to the internet gateway.
- Security group `mt-gateway-sg` for the tasks:
  - outbound: HTTPS (tcp 443) to the internet, for image pulls and partner APIs
  - inbound: tcp 8080 from the load balancer's security group `mt-alb-sg` only
    (never from 0.0.0.0/0)
- The load balancer's own group `mt-alb-sg` is fine; leave it alone.

## What we found on the migration day
- The service definition was copied verbatim from the default-VPC version.
- Somebody tightened the security group by deleting the default allow-all
  egress rule and re-adding only HTTP.
- The route table for the private subnet was created by hand and nobody added
  the default route.
- The inbound rule for the load balancer was lost when the group was recreated.

## Note on emulation
There is no packet flow in the lab emulator. Your fix is verified by what ECS
actually does with the service (where its tasks are placed) and by
the routes and security-group rules that define reachability.
