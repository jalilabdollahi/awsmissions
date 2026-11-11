# Solution

Four independent defects sit in a chain. Fix them one at a time by sending a test event after each change:

```bash
aws events put-events --entries '[{"Source":"cedarpoint.shop","DetailType":"OrderPlaced","Detail":"{\"orderId\":\"CP-1\",\"items\":[{\"sku\":\"MUG-RED\",\"qty\":4}]}"}]'
aws stepfunctions list-executions --state-machine-arn <arn of the workflow>
```

**1. The rule never matches.** The pattern asks for `"detail-type": ["OrderCreated"]`, the shop sends `OrderPlaced`. In `order-placed-pattern.json` change it, then:

```bash
aws events put-rule --name cedarpoint-order-placed --event-pattern file://order-placed-pattern.json
```

**2. The target is the retired workflow.** `rule-targets.json` points at `cedarpoint-fulfilment-legacy`, which accepts anything and does nothing. Change the `Arn` to `arn:aws:states:us-east-1:000000000000:stateMachine:cedarpoint-fulfilment`.

**3. The workflow gets the whole event.** EventBridge passes the complete event envelope (`source`, `detail-type`, `detail`, ...) as the execution input, but the workflow reads `$.orderId` and `$.items`. Add `"InputPath": "$.detail"` to the target (or change the workflow's paths to `$.detail.orderId`). Then apply the targets:

```bash
aws events put-targets --rule cedarpoint-order-placed --targets file://rule-targets.json
```

**4. The workflow's role cannot invoke the Lambda.** `workflow-role-policy.json` allows `function:cedarpoint-allocate`, but the function is `cedarpoint-allocate-stock`. Fix the ARN and apply it:

```bash
aws iam put-role-policy --role-name cedarpoint-fulfilment-role --policy-name fulfilment --policy-document file://workflow-role-policy.json
```
