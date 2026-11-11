# Debrief: reaching AWS services without the internet

S3 and DynamoDB offer **gateway endpoints**: free, route-table based, and highly available. Everything else (SQS, Secrets Manager, ECR, ...) uses **interface endpoints** (PrivateLink): an ENI in your subnet with a private IP, billed per hour and per GB, with its own security group.

A gateway endpoint works by adding a route for the service's managed prefix list to the route tables you associate it with, which is why the association with the *private* table matters and why the public table does not need it.

The **endpoint policy** is a second IAM-style filter between your VPC and the service. It does not replace identity or bucket policies; it can only narrow. Use it for data-exfiltration controls ("this network can only talk to our buckets"). Pair it with a bucket policy that denies requests not coming through the endpoint (`aws:SourceVpce`) to lock the data in both directions.

Cost note: sending S3 traffic through a NAT gateway is often one of the largest surprise items on an AWS bill; a gateway endpoint removes it for free.
