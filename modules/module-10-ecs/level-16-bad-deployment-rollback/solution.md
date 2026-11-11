# Solution

Revision 2 exits with code 3 (its migration fails), so the service never reaches two healthy tasks. Task definition revisions are immutable and cheap, so the quickest recovery is to point the service back at revision 1, and to switch on the circuit breaker in the same call.

```bash
aws ecs describe-services --cluster tidepool --services tidepool-web --query 'services[0].events[:5].message'
aws ecs update-service --cluster tidepool --service tidepool-web --task-definition tidepool-web:1 \
  --deployment-configuration 'deploymentCircuitBreaker={enable=true,rollback=true},maximumPercent=200,minimumHealthyPercent=100'
```

Registering a corrected revision 3 and deploying that would also pass, as long as it really serves traffic.
