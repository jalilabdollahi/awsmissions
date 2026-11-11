# INC-6120 - Ledger web front-end is down (no tasks running)

Ledger & Co. internal finance tooling, platform on-call.

## Situation
ECS service `ledger-web` in cluster `ledger-prod` runs the finance team's
static front-end behind the internal load balancer. During yesterday's
rollback drill someone scaled it down. Today, when the finance team needs the
month-end close page, nobody can get a task to stay up.

## Facts gathered so far
- Cluster: `ledger-prod` (Fargate, default VPC subnets are fine).
- Task definition family: `ledger-web`. The service points at revision 1.
- The container is named `web`. Its entrypoint is a small wrapper that refuses
  to start nginx unless `DB_HOST` is set (to stop it serving a page with dead
  widgets). The right value is `ledger-db.internal`.
- The internal registry mirror (`registry.ledgerco.invalid`) has been
  unreachable since the weekend. Staging runs the same front-end from the
  public image `nginx:alpine`; that is acceptable for production for now.
- The service ought to run 2 tasks during month-end close.

## Debugging tips from the team wiki
- `aws ecs describe-services` shows events and counts, `describe-tasks` shows a
  stopped task's `stoppedReason` and container exit codes.
- A task definition revision is immutable. To change anything you register a
  new revision and point the service at it.
