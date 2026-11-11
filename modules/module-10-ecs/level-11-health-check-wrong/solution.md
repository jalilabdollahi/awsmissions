# Solution

The target group probes `/healthz`, but the gateway serves `/health`. Everything else answers 404, which the strict matcher (200) correctly treats as a failure. Look at the reason first:

```bash
TG=$(aws elbv2 describe-target-groups --names gateway-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-health --target-group-arn $TG        # Target.ResponseCodeMismatch
aws elbv2 describe-target-groups --target-group-arns $TG --query 'TargetGroups[0].HealthCheckPath'
```

Fix the path (not the matcher):

```bash
aws elbv2 modify-target-group --target-group-arn $TG --health-check-path /health
```
