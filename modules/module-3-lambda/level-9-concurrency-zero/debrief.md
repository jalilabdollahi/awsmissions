# Debrief: reserved concurrency is a floor and a ceiling

Each account has a regional concurrency limit shared by all functions (1,000 by default). **Reserved concurrency** carves a slice out of it for one function and does two things at once:

- It **guarantees** that slice to the function: other functions cannot use it up.
- It **caps** the function at that number: execution beyond it is throttled (`TooManyRequestsException` / HTTP 429 for synchronous callers; async events are retried for up to six hours).

Setting it to `0` is therefore the quickest "off switch" Lambda has, and `delete-function-concurrency` is the switch back to the shared pool. The mission shows why neither extreme is a good resting state: `0` takes the product down, and *no* setting at all lets a retry storm scale to hundreds of parallel executions and open hundreds of database connections.

**Choosing the cap**: it should come from the most constrained downstream (here a Postgres pool with room for 20), not from guesswork. For SQS-triggered functions use the event source mapping's `MaximumConcurrency` instead, so messages stay safely in the queue rather than being throttled and retried.

**In real life**
- Throttles appear as the `Throttles` CloudWatch metric; alarm on it, and after any incident check `aws lambda get-function-concurrency` on every function you touched.
- Reserved concurrency counts against the account pool; the account must keep at least 100 unreserved executions.
- *Provisioned* concurrency is a different feature: it keeps environments warm (and costs money all day) to remove cold starts.
