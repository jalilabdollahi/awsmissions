# Solution

`describe-target-health` says `Target.Timeout`: the load balancer sent `GET /health`, waited 5 seconds and gave up. The deep check needs about 7 seconds.

1. Confirm the reason and measure the endpoint:

```bash
aws elbv2 describe-target-health --target-group-arn <arn> \
  --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State,TargetHealth.Reason]'
aws elbv2 describe-target-groups --names fathomly-api \
  --query 'TargetGroups[0].[HealthCheckPath,HealthCheckIntervalSeconds,HealthCheckTimeoutSeconds]'
bash probe.sh /health     # about 7s
bash probe.sh /livez      # instant
```

2. Either of these fixes is accepted:

   - **Use the cheap endpoint** for the load balancer check (best option, and the deep check stays in monitoring):
     ```bash
     aws elbv2 modify-target-group --target-group-arn <arn> --health-check-path /livez
     ```
   - **Give the deep check room**: a timeout larger than the response time and a longer interval (the timeout must be shorter than the interval):
     ```bash
     aws elbv2 modify-target-group --target-group-arn <arn> \
       --health-check-timeout-seconds 10 --health-check-interval-seconds 20
     ```

3. Wait for two passes, then run `check`.
