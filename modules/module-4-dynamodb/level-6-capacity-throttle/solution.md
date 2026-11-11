# Solution

Register read and write capacity of the table as scalable targets, then attach a target-tracking policy to each.

```bash
for kind in Write Read; do
  aws application-autoscaling register-scalable-target \
    --service-namespace dynamodb \
    --resource-id table/pulsewire-readings \
    --scalable-dimension dynamodb:table:${kind}CapacityUnits \
    --min-capacity 25 --max-capacity 1000

  aws application-autoscaling put-scaling-policy \
    --service-namespace dynamodb \
    --resource-id table/pulsewire-readings \
    --scalable-dimension dynamodb:table:${kind}CapacityUnits \
    --policy-name pulsewire-${kind}-tracking \
    --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration \
    '{"TargetValue":70.0,"PredefinedMetricSpecification":{"PredefinedMetricType":"DynamoDB'${kind}'CapacityUtilization"}}'
done
```

`workspace/scaling-policy.json` has a template of the policy document.
