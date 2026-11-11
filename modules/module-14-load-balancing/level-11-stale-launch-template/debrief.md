# Debrief: changing a launch template changes nothing that already exists

A **launch template** is versioned. Each version is immutable, one is marked the *default*, and a group's `LaunchTemplate` reference chooses one of three things: an explicit number (`1`), `$Default`, or `$Latest`. Creating a new version does not touch any group; only instances launched *afterwards*, from the referenced version, are affected.

Two separate steps are therefore needed for a rollout:
1. Make the **group reference** the right version. An explicit number pins the group, which is great for predictability and a classic reason for "we fixed it but nothing changed".
2. Replace the **running instances**. An *instance refresh* does it in rolling batches while keeping `MinHealthyPercentage` of capacity in service, and rolls back when health checks fail (with auto-rollback enabled). Without it you wait for natural churn, or terminate instances one by one and watch each replacement.

**Choosing the reference**
- `$Latest` is convenient for dev and risky for prod: any new version rolls out on the next launch, including scale-out events at 3 a.m.
- Pinning a version (and promoting it by updating the group) gives you a reviewable, revertible rollout. Reverting means pointing the group back and refreshing again.
- `$Default` lets you decouple "publish" from "go live" by changing the template's default version.

**Also learn from this outage**: the old version started the service on a port that did not match the target group. Catch that class of error before shipping: launch one instance from the new version and check it passes the target group's health check first.
