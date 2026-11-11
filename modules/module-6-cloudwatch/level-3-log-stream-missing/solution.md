# Solution

`PutLogEvents` writes into a specific stream, and the stream has to exist. The group is fine; stream `field-gateway-07` was never created and the gateway's agent is not allowed to create it.

```bash
aws logs describe-log-streams --log-group-name /harvest/sensors
aws logs create-log-stream --log-group-name /harvest/sensors --log-stream-name field-gateway-07
```

Run `check`: the validator writes a sensor reading to the new stream and reads it back.
