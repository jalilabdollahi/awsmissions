# Solution

The listener's default action is a `redirect`, but its `RedirectConfig` says: status `HTTP_302` (temporary), port `8443`, and path `/` (hard-coded, so the real path is thrown away).

1. Look at the current action:

```bash
LB=$(aws elbv2 describe-load-balancers --names quillstone-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws elbv2 describe-listeners --load-balancer-arn $LB --query 'Listeners[].[ListenerArn,Port,DefaultActions]'
```

2. Replace it with a permanent redirect that keeps host, path and query. `#{host}`, `#{path}` and `#{query}` are placeholders the load balancer fills in per request:

```bash
aws elbv2 modify-listener --listener-arn <listener-arn> --default-actions \
  '[{"Type":"redirect","RedirectConfig":{"Protocol":"HTTPS","Port":"443","Host":"#{host}","Path":"/#{path}","Query":"#{query}","StatusCode":"HTTP_301"}}]'
```

3. Test with `bash probe.sh "/pricing?plan=pro"`: expect `301` and a `Location` of `https://<host>:443/pricing?plan=pro`. Run `check`.
