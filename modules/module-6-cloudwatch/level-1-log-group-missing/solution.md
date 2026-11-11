# Solution

CloudWatch Logs has three levels: a **log group** (the container for one application's logs and the place where retention and metric filters are configured), **log streams** inside it (one per source, such as a container), and **log events** in a stream. A write to a group that does not exist is rejected, and this log driver is configured not to create groups.

```bash
aws logs describe-log-groups
aws logs create-log-group --log-group-name /swiftpost/checkout-api
```

Run `check`: the validator creates a stream in the group, writes two lines, and searches for one of them.
