# Solution

The listener forwards to the target group `pageturn-web`, but nothing was ever registered in that group, so the load balancer has no backend and answers 503.

1. Find the instance that runs the storefront:

```bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=pageturn-web-1" \
  --query 'Reservations[].Instances[].InstanceId' --output text
```

2. Look at the target group and confirm it is empty:

```bash
aws elbv2 describe-target-groups --names pageturn-web
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

3. Register the instance (it uses the group's default port 8080):

```bash
aws elbv2 register-targets --target-group-arn <target-group-arn> --targets Id=<instance-id>
```

4. Wait about ten seconds for two successful health checks, then try `bash probe.sh` and run `check`.
