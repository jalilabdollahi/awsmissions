# Debrief: NACLs are ordered and stateless

Security groups are unordered allow-lists and are stateful. Network ACLs are the opposite:

- Rules are evaluated **from the lowest number up and the first match wins**; everything after it is ignored. An early broad deny silently shadows later allows.
- Each direction is evaluated independently (**stateless**). An allowed inbound request still needs an outbound rule for its reply, which goes to an ephemeral port in the range 1024-65535. That is why egress `1024-65535` exists here.
- Every NACL ends with an unremovable `*` deny-all (rule 32767).

Real-world tips:
- Leave gaps between rule numbers (10, 20, 30...) so you can insert rules later; put specific denies (like the abuse range) at low numbers and broad allows afterwards.
- A NACL is a blunt subnet-level tool. Use security groups for normal access control and keep NACLs for coarse blocks such as known-bad CIDRs.
- If a security group looks right but traffic still dies, check the NACL of the subnet: `describe-network-acls --filters Name=association.subnet-id,Values=<subnet>`.
