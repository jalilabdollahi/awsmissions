# Solution

The rule on priority 10 has a `host-header` condition with two values, and one of them has a typo: `app.helixpay.exmaple`. Host matching is a plain string comparison, so requests for `app.helixpay.example` fall through to the default rule (the marketing fleet).

1. Print the rule:

```bash
LISTENER=$(aws elbv2 describe-listeners --load-balancer-arn <alb-arn> --query 'Listeners[0].ListenerArn' --output text)
aws elbv2 describe-rules --listener-arn $LISTENER
```

2. Rewrite the condition with both hostnames spelled correctly (`modify-rule` replaces the conditions, so give the complete list):

```bash
aws elbv2 modify-rule --rule-arn <rule-arn> \
  --conditions '[{"Field":"host-header","Values":["portal.helixpay.example","app.helixpay.example"]}]'
```

3. Check both names with `bash probe.sh app.helixpay.example` and `bash probe.sh portal.helixpay.example`, then run `check`.
