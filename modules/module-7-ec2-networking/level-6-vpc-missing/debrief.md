# Debrief: plan your address space before you build

Two networks with overlapping CIDRs cannot be peered, cannot be joined through a Transit Gateway, and cannot be reached over the same VPN without ambiguous routing. Because a VPC's primary CIDR cannot be edited, the only cure after the fact is to rebuild, which is painful once instances exist. This is why overlap is the most expensive networking mistake to make early.

Real-world tips:
- Keep an IP address plan (a spreadsheet or IPAM). AWS VPC IPAM can allocate non-overlapping blocks automatically.
- You can *add* secondary CIDR blocks to a VPC later, but not remove the primary one.
- Remember the default VPC (172.31.0.0/16) and on-premises ranges when choosing.
- `enableDnsHostnames` gives instances public DNS names and is required by services such as EKS nodes and PrivateLink private DNS; `enableDnsSupport` (on by default) is the resolver itself.
