# Solution

Two separate problems, and the order matters: **capacity first, then traffic.**

1. Look at the weights and at both fleets:

```bash
aws elbv2 describe-listeners --load-balancer-arn <alb-arn> --query 'Listeners[0].DefaultActions'
aws elbv2 describe-target-health --target-group-arn <green-arn>
aws elbv2 describe-target-health --target-group-arn <blue-arn>
```

2. Make green as big as blue. The group's own min must go up with it, otherwise a quiet night could scale it back:

```bash
aws autoscaling update-auto-scaling-group --auto-scaling-group-name saffron-green-asg \
  --min-size 2 --desired-capacity 2
```

3. Wait until `describe-target-health` shows two `healthy` targets in green (about 20 seconds).

4. Edit `listener-actions.json` (a copy of the listener's current action with this lab's ARNs): green `Weight` 100, blue `Weight` 0. Keep blue in the list. Apply it:

```bash
aws elbv2 modify-listener --listener-arn <listener-arn> --default-actions file://listener-actions.json
```

5. `bash probe.sh` should now count 10 answers from release 2. Rollback would be the same call with the weights swapped. Run `check`.
