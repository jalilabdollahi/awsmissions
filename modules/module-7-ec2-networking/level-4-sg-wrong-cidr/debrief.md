# Debrief: CIDR is a prefix, not an address

`203.0.113.0/24` means "the first 24 bits are fixed", i.e. 256 addresses from .0 to .255. `/32` is exactly one address, `/0` is everything. A source of `203.0.131.0/24` (two digits swapped) is a perfectly valid, perfectly wrong range, and AWS cannot tell you it is a typo.

Real-world tips:
- When an office, VPN or partner changes address, the rule must change in both directions: add the new range, remove the old one. A forgotten old range is a quiet backdoor once the provider recycles that address space.
- Prefer a managed prefix list (`aws ec2 create-managed-prefix-list`) for ranges shared by many groups, so one edit updates every rule.
- For SSH, best practice is no inbound rule at all: use SSM Session Manager or EC2 Instance Connect Endpoint.
