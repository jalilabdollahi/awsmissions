# Solution

The target group still has Terraform's default health check: `GET /` and success only on HTTP `200`. The API answers `/` with `404`, so every check fails. The real liveness endpoint is `/healthz`.

1. Read the current check:

```bash
aws elbv2 describe-target-groups --names brewline-orders \
  --query 'TargetGroups[0].[HealthCheckPath,Matcher.HttpCode,HealthCheckPort]'
```

2. Ask the service which routes answer 200 (`bash probe.sh /`, `bash probe.sh /healthz`).

3. Point the check at the liveness endpoint, leaving the success code strict:

```bash
aws elbv2 modify-target-group --target-group-arn <arn> --health-check-path /healthz
```

4. After two passing checks (about 10 seconds) both targets are `healthy`. Run `check`.

Do not "fix" it with `--matcher HttpCode=200-499`: then a broken app that returns 404 or 500 would still be called healthy.
