# Solution

Launch template versions are immutable snapshots. Version 2 (the fix) exists, but the group references `Version=1`, so it keeps launching instances with the old startup script. And even after you repoint the group, the two instances already running stay on version 1 until something replaces them.

1. See which version the group uses and which versions exist:

```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names parcelway-asg \
  --query 'AutoScalingGroups[0].[LaunchTemplate,Instances[].[InstanceId,LaunchTemplate.Version]]'
aws ec2 describe-launch-template-versions --launch-template-name parcelway-lt \
  --query 'LaunchTemplateVersions[].[VersionNumber,VersionDescription]'
```

2. Point the group at the newest version (`$Latest` follows future versions too; an explicit `2` also passes):

```bash
aws autoscaling update-auto-scaling-group --auto-scaling-group-name parcelway-asg \
  --launch-template 'LaunchTemplateName=parcelway-lt,Version=$Latest'
```

3. Replace the running instances with an instance refresh (it launches new instances from the current version and retires the old ones in rolling batches):

```bash
aws autoscaling start-instance-refresh --auto-scaling-group-name parcelway-asg \
  --preferences MinHealthyPercentage=50
aws autoscaling describe-instance-refreshes --auto-scaling-group-name parcelway-asg
```

4. When the refresh is `Successful`, `bash probe.sh` answers with release 2.4. Run `check`.
