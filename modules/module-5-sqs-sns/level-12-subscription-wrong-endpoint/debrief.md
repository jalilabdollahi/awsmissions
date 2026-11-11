# Debrief: you cannot edit where a subscription points

`SetSubscriptionAttributes` can change a subscription's filter policy, raw delivery flag, redrive policy and delivery policy. It cannot change the **protocol** or the **endpoint**. Those define the subscription's identity, so correcting a wrong endpoint means `Unsubscribe` followed by `Subscribe`, which also produces a new subscription ARN. Anything configured on the old subscription (filters, raw delivery, DLQ) has to be recreated.

**Why nothing complained.** The staging queue is a perfectly valid destination. SNS delivers happily, the publisher sees success, and the only evidence is a queue that is empty where it should be full, and a different one that is full where it should be empty. Mixed environments are among the most expensive of silent configuration bugs because they also leak real data into test systems.

**In real life**
- Keep prod and staging in separate AWS accounts; a copy-and-paste ARN then fails loudly with an authorisation error instead of working.
- Reference ARNs from the stack that creates the queue (`!GetAtt`, Terraform outputs) rather than typing them.
- Review `list-subscriptions-by-topic` output as part of every release: endpoint, filter policy and raw-delivery flag are the three things that matter.
- A subscription can have its own dead-letter queue (`RedrivePolicy`), which catches deliveries that fail because the target queue is unreachable.
