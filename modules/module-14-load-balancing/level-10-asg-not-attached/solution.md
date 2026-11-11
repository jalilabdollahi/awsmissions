# Solution

The group and the target group never met. A group only registers its instances with the target groups listed in its own configuration (`TargetGroupARNs`); the target group has no idea an Auto Scaling group exists.

1. Confirm the group lists no target groups:

```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names orbit-dispatch-asg \
  --query 'AutoScalingGroups[0].[TargetGroupARNs,Instances[].InstanceId]'
aws elbv2 describe-target-health --target-group-arn <orbit-dispatch-arn>
```

2. Attach the target group to the group. Existing instances are registered immediately, and every future launch is registered automatically (and deregistered when the instance goes away):

```bash
aws autoscaling attach-load-balancer-target-groups --auto-scaling-group-name orbit-dispatch-asg \
  --target-group-arns <orbit-dispatch-arn>
```

3. After the health checks pass (about 10 seconds) `bash probe.sh` answers. `check` also terminates one instance to prove that the replacement joins the group on its own.
