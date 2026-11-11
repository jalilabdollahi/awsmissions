# Debrief: security groups are VPC-scoped, and launches validate them

`RunInstances` checks every referenced resource up front. A security group id that does not exist (or lives in another VPC) is rejected with `InvalidGroup.NotFound` before anything starts, so you get an error instead of a half-built instance.

Things worth remembering:

- A group id is not portable. The default VPC's `tindle-web` and a group with the same name in `tindle-prod` are two different resources.
- A new group has **no inbound rules** and allows all outbound traffic. Opening a port is a separate `authorize-security-group-ingress` call.
- Hard-coded ids in runbooks rot. Look groups up by tag or name inside the target VPC, or move the launch into a launch template that is versioned together with the infrastructure code.
- Do not "fix" a failing launch by opening SSH to `0.0.0.0/0`. Reach servers through SSM Session Manager or a locked-down bastion.
