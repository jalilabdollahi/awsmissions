# Debrief: provisioned capacity needs a controller

In provisioned mode you promise DynamoDB a number of reads and writes per second. Exceed it for longer than the burst credit lasts and requests fail with `ProvisionedThroughputExceededException`. The AWS SDKs retry with backoff, which is why the first symptom is usually latency and only later errors.

Auto scaling is not a DynamoDB feature, but an **Application Auto Scaling** integration with two pieces:
1. a **scalable target**: which resource and dimension (table or index, read or write), with minimum and maximum capacity;
2. a **scaling policy**: target tracking keeps utilisation (consumed / provisioned) near a percentage you choose, adding and removing units as CloudWatch alarms fire.

Gotchas:
- Auto scaling reacts in minutes. A burst that arrives within seconds can still throttle; the minimum capacity and the 02:00 burst size need to be chosen together, or use scheduled scaling to pre-warm before known peaks.
- Scaling in is limited by DynamoDB: a table can decrease capacity only a few times per day (more on the first hours of a day), so the scale-in cooldown matters.
- Every global secondary index has its own capacity and needs its own scalable target. Under-provisioned indexes throttle writes to the base table.
- On-demand mode removes all of this at a higher price per request. For flat, predictable load provisioned (ideally with reserved capacity) is cheaper; for spiky or unknown load on-demand wins. That is the exact trade-off finance asked you to respect.
- Emulator note: AWSMissions' emulator stores the scaling configuration but does not actually run alarms, so this level checks the configuration the real service would use.
