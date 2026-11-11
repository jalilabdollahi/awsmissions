# Solution

Stickiness is a **target group attribute** and is off by default. Without it each request is balanced independently, so a shopper alternates between the two servers.

1. See the attributes of the group:

```bash
TG=$(aws elbv2 describe-target-groups --names kestrel-web --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-group-attributes --target-group-arn $TG
```

2. Turn on load-balancer-generated cookie stickiness for a day:

```bash
aws elbv2 modify-target-group-attributes --target-group-arn $TG --attributes \
  Key=stickiness.enabled,Value=true \
  Key=stickiness.type,Value=lb_cookie \
  Key=stickiness.lb_cookie.duration_seconds,Value=86400
```

3. `bash probe.sh -v` now shows an `AWSALB` cookie and the same server answering every time. Run `check`.
