# Debrief: shift traffic last, and keep the way back open

A listener's `forward` action can list several target groups with **weights** (0 to 999). Each request is assigned randomly in proportion to the weights, so 90/10 is a canary and 0/100 is a completed cutover. A weight of **0** means "attached, healthy, but receives nothing", which is the cheapest rollback in AWS: put the weights back and the next request goes to the old fleet. Removing the old group from the action loses that.

**The order of a safe cutover**
1. Deploy green and let it pass health checks with no traffic.
2. Size green for the full load *before* moving traffic. An ASG at `desired=1` with 100% of the traffic would be hammered while it scales up (new instances take minutes to boot, warm caches and pass checks). A cold, small fleet takes the production load right as it hits.
3. Shift in steps if you can (5, 25, 50, 100) and watch error rate and latency per target group (`HTTPCode_Target_5XX_Count`, `TargetResponseTime`).
4. Keep blue alive, with weight 0, until you are confident, then scale it down.

**Details worth knowing**
- Stickiness across target groups needs the forward action's `TargetGroupStickinessConfig`; otherwise a client can flip between groups mid-session.
- `modify-listener --default-actions` replaces the entire action, so always send both groups; omitting one removes it.
- CodeDeploy and ECS blue/green automate this with the same weighted-forward primitive underneath.
- Weighted routing also works on rules (path or host based), so you can canary a single API path without touching the rest.
