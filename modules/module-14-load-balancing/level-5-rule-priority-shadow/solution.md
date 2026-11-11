# Solution

A listener evaluates its rules in **priority order, lowest number first**, and stops at the first rule whose conditions match. The `/api/*` forward rule has priority 10 and matches `/api/admin/users` too, so the block rule at priority 20 is never reached.

1. List the rules with their priorities:

```bash
LISTENER=$(aws elbv2 describe-listeners --load-balancer-arn <alb-arn> --query 'Listeners[0].ListenerArn' --output text)
aws elbv2 describe-rules --listener-arn $LISTENER
```

2. Give the more specific block rule a smaller number than the broad API rule (they only need to differ in order, for example 5 and 10):

```bash
aws elbv2 set-rule-priorities --rule-priorities \
  RuleArn=<admin-rule-arn>,Priority=5 RuleArn=<api-rule-arn>,Priority=10
```

3. Test with `bash probe.sh /api/admin/users` (403) and `bash probe.sh /api/orders/42` (API). Run `check`.
