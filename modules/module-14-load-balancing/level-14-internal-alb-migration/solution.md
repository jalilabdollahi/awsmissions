# Solution

A load balancer's **scheme** (`internal` or `internet-facing`) is fixed at creation. The only way to change it is to create a new load balancer and move the listeners and rules over. The target groups are separate objects, so they can be reused as they are.

1. Record the old routing. You need every rule's priority, condition and action, and the listener's default action:

```bash
OLD=$(aws elbv2 describe-load-balancers --names nimbus-gateway --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws elbv2 describe-load-balancers --names nimbus-gateway --query 'LoadBalancers[0].[Scheme,AvailabilityZones]'
aws elbv2 describe-listeners --load-balancer-arn $OLD   # note the Port
L=$(aws elbv2 describe-listeners --load-balancer-arn $OLD --query 'Listeners[0].ListenerArn' --output text)
aws elbv2 describe-rules --listener-arn $L
```

2. Create the internet-facing replacement in at least two zones (the name must differ while the old one exists, or delete the old one first as below):

```bash
aws elbv2 delete-load-balancer --load-balancer-arn $OLD
NEW=$(aws elbv2 create-load-balancer --name nimbus-gateway-public --scheme internet-facing \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-b --query 'LoadBalancers[0].LoadBalancerArn' --output text)
```

3. Rebuild the listener on the same port as the old one: default action forwards to `nimbus-web`; then the two rules (`/status` fixed 200 response with the same body at priority 10, host `api.nimbusnotes.example` forwarding to `nimbus-api` at priority 20):

```bash
L2=$(aws elbv2 create-listener --load-balancer-arn $NEW --protocol HTTP --port <old-listener-port> \
  --default-actions Type=forward,TargetGroupArn=<nimbus-web-arn> --query 'Listeners[0].ListenerArn' --output text)
aws elbv2 create-rule --listener-arn $L2 --priority 10 \
  --conditions '[{"Field":"path-pattern","Values":["/status"]}]' \
  --actions '[{"Type":"fixed-response","FixedResponseConfig":{"StatusCode":"200","ContentType":"text/plain","MessageBody":"nimbus gateway: all systems go"}}]'
aws elbv2 create-rule --listener-arn $L2 --priority 20 \
  --conditions '[{"Field":"host-header","Values":["api.nimbusnotes.example"]}]' \
  --actions '[{"Type":"forward","TargetGroupArn":"<nimbus-api-arn>"}]'
```

4. Test with `bash probe.sh <new-lb-name> /status`, and run `check`.
