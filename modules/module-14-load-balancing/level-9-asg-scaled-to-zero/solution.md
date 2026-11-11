# Solution

Two things keep the group empty: its **capacity settings** (`MinSize 0`, `DesiredCapacity 0`, `MaxSize 2`) and a **scheduled action** that applies zeroes every night at 22:00.

1. Inspect both:

```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names lumen-api-asg \
  --query 'AutoScalingGroups[0].[MinSize,DesiredCapacity,MaxSize]'
aws autoscaling describe-scheduled-actions --auto-scaling-group-name lumen-api-asg
```

2. Remove the shutdown action (or edit it so it never goes below your minimum):

```bash
aws autoscaling delete-scheduled-action --auto-scaling-group-name lumen-api-asg --scheduled-action-name nightly-shutdown
```

3. Restore capacity with room to scale out (min at least 2, desired at least 2, max at least 6):

```bash
aws autoscaling update-auto-scaling-group --auto-scaling-group-name lumen-api-asg \
  --min-size 2 --desired-capacity 2 --max-size 6
```

4. Instances launch within seconds and register with the target group automatically. Run `check` once they are healthy.
