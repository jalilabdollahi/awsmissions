# Solution

Both target groups are fine. The problem is the **listener's default action**: it forwards to `portal-staging`.

1. Find the listener and see where it forwards:

```bash
LB=$(aws elbv2 describe-load-balancers --names maplewood-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws elbv2 describe-listeners --load-balancer-arn $LB
aws elbv2 describe-target-groups --query 'TargetGroups[].[TargetGroupName,TargetGroupArn]' --output text
```

2. Point the default action at `portal-prod`:

```bash
aws elbv2 modify-listener --listener-arn <listener-arn> \
  --default-actions Type=forward,TargetGroupArn=<portal-prod-arn>
```

3. `bash probe.sh` should now show the production banner. Run `check`.
