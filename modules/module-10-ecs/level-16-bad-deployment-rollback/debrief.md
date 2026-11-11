# Debrief: roll back first, root-cause second

ECS keeps every task definition revision, which makes rollback a one-line `update-service`. During an incident the order is: restore service, then debug the bad revision calmly (its logs and stopped-task reasons are still there).

How ECS rolling deployments behave:
- `minimumHealthyPercent` / `maximumPercent` control how much old capacity may be removed and how many extra tasks may start. With 100/200 a healthy service keeps all old tasks until the new ones are healthy, so a crashing revision costs capacity only if the old tasks are removed or the new ones fail forever.
- Without protection a failing deployment just keeps trying: the service shows `IN_PROGRESS`, nothing alerts, and a human has to notice.
- The **deployment circuit breaker** counts consecutive failed task launches and, with `rollback: true`, automatically returns the service to the last steady revision and marks the deployment `FAILED`. Pair it with a CloudWatch alarm or EventBridge rule on deployment state changes.

Real-world tips:
- Run migrations as a separate one-off task (`run-task`) before the deploy, not at container start-up of every replica.
- Health-check grace periods and a proper load balancer health check turn "container started" into "container ready", which the circuit breaker also uses.
- Never deploy on a Friday afternoon without the breaker.
