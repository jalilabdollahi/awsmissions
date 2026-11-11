# Debrief: a redrive policy is only a pointer

`RedrivePolicy` stores two values: the ARN of the dead-letter queue and `maxReceiveCount`. In a real account SQS validates some of this when you set it, but a pointer can still go wrong in ways that are silent at runtime: a typo in the name, the wrong region, or a DLQ that was deleted later. The source queue keeps working; the only symptom is that failed messages stop showing up anywhere.

**Why it hurts.** Messages that exhaust their retries are discarded without a trace. You lose exactly the messages you most wanted to inspect, and metrics such as `NumberOfMessagesDeleted` do not show them either.

**In real life**
- Build the ARN from the queue itself (`QueueArn` attribute, or `!GetAtt Dlq.Arn` in CloudFormation) instead of typing it.
- After any change to a redrive policy, test it with a deliberate failure, as this level's validator does.
- On the DLQ, `RedriveAllowPolicy` can restrict which source queues may use it, which also helps catch mix-ups between environments.
- Once the cause is fixed, move parked messages back with `StartMessageMoveTask` (DLQ redrive) instead of writing a replay script.
