# Debrief: an internet gateway has to be attached

Internet access for a subnet needs four things at once: an IGW **attached** to the VPC, a route `0.0.0.0/0 -> igw-...` in the subnet's route table, a public (or Elastic) IP on the instance, and security group / NACL rules that allow the traffic. Miss any one and you get a plain timeout with no error message anywhere.

An unattached IGW is easy to miss because it exists, it has an id, and a route can point at it; the console even lets you create that route. A VPC can have only one IGW attached, and an IGW only one VPC.

Real-world tips:
- Diagnose from the outside in: `describe-internet-gateways` (attachment state), then `describe-route-tables` for the subnet, then the instance's public IP, then SG/NACL.
- In AWS, a route to a gateway that is not attached shows up as `blackhole` in the route table. Check the route's State when debugging.
- Name your gateways (tags) so a leftover like `legacy-igw` is recognisable and can be cleaned up safely.
