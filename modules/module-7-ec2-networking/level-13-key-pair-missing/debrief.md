# Debrief: some launch parameters are forever

An EC2 key pair is just a public key that cloud-init writes into `~/.ssh/authorized_keys` of the default user during first boot. After that the instance is on its own: AWS cannot "attach" a key later. Instance properties fall into two groups: mutable ones (security groups, instance type while stopped, IAM profile, tags) and launch-time ones (key pair, AMI, subnet, most network interface details). For the second kind the fix is always replace, not modify.

Real-world tips:
- Do the swap in the right order: start the new instance, verify, then terminate the old one.
- Put a launch template in version control so a replacement is one command and cannot forget the key.
- Better still, skip SSH keys entirely: SSM Session Manager (needs an instance profile) gives audited shell access without opening port 22.
- Private keys are only shown once at `create-key-pair`. Lose it and the key pair is useless; keep it in a secret store.
