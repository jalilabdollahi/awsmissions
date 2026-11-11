# Solution

Cloud Map gives ECS services a stable DNS name: a **namespace** (the domain), a **service** inside it (the name), and the ECS service registers every task it starts as an **instance**.

```bash
aws servicediscovery create-private-dns-namespace --name shop.local --vpc vpc-default-us-east-1
aws servicediscovery list-namespaces                       # wait for shop.local, copy its Id

aws servicediscovery create-service --name inventory --namespace-id <ns id> \
  --dns-config 'RoutingPolicy=MULTIVALUE,DnsRecords=[{Type=A,TTL=10}]'

aws ecs update-service --cluster shop --service inventory \
  --service-registries registryArn=<the Cloud Map service ARN>
```

Verify with `aws servicediscovery list-instances --service-id <id>`: it should show both task IPs.
(On real AWS you attach the registry when creating the ECS service; recreating the service is the portable way.)
