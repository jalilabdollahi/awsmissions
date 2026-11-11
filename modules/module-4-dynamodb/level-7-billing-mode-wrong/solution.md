# Solution

Billing mode can be switched on a live table, and global secondary indexes follow the table's mode automatically. Then remove the leftover scaling target.

```bash
aws dynamodb update-table --table-name ticketflash-holds --billing-mode PAY_PER_REQUEST

aws application-autoscaling describe-scalable-targets --service-namespace dynamodb
aws application-autoscaling deregister-scalable-target \
  --service-namespace dynamodb \
  --resource-id table/ticketflash-holds \
  --scalable-dimension dynamodb:table:WriteCapacityUnits
```
