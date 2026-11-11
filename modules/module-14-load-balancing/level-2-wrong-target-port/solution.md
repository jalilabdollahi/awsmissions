# Solution

The target group `tracking-api` has the right default port (8080), but the instance was registered with an explicit **port override** of 80. Health checks use the target's own port ("traffic-port"), so the load balancer keeps knocking on port 80, where nothing listens.

1. See the problem. The `Port` of the target is 80:

```bash
TG=$(aws elbv2 describe-target-groups --names tracking-api --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-health --target-group-arn $TG
```

2. A registered target's port cannot be edited. Remove that registration and add the instance again without an override:

```bash
aws elbv2 deregister-targets --target-group-arn $TG --targets Id=<instance-id>,Port=80
aws elbv2 register-targets   --target-group-arn $TG --targets Id=<instance-id>
```

3. After about ten seconds the target turns healthy. Run `check`.
