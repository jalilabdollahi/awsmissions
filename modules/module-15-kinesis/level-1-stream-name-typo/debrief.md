# Debrief: a stream name is just a string until it is used

Kinesis streams are addressed by **name within an account and Region**. Nothing links a producer to a stream except that string, which usually lives in an environment variable, a parameter or a config file. A one-character drift gives you `ResourceNotFoundException`, and since the producer is the one raising it, the stream's own metrics look perfectly healthy: no incoming records, no errors.

**Why recreating the stream would have been wrong:** the role's policy covers `thermowave-*`, so a stream with the typo'd name would have accepted data, and you would have split the readings across two streams, left a stray resource to pay for, and hidden the real bug in the function's configuration.

**The classic side-trap:** `update-function-configuration --environment` replaces the *entire* variable map. Setting only `STREAM_NAME` would have silently dropped `FIRMWARE_CHANNEL`, and the model would have received readings with an unknown channel.

**In real life**
- Do not hard-code names in each service. Put them in one place (SSM Parameter Store, or a CloudFormation/Terraform output) and reference them everywhere.
- Prefer passing the **stream ARN** where an API accepts it: an ARN carries account and Region, so it cannot silently point at the wrong place.
- Alarm on the producer side (`PutRecord` failures, Lambda `Errors`) as well as on the stream's `IncomingRecords`; a flat IncomingRecords line alone cannot tell "no traffic" from "nobody can reach the stream".
