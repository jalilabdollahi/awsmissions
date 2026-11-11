# Debrief: test the chain, not the links

Observability built from logs has four hand-offs: **log line to metric filter**, **filter to metric** (namespace, name, dimensions), **metric to alarm**, **alarm to notification target**. Each link can be perfectly valid on its own and still be disconnected from the next: the pattern is valid but matches nothing, the alarm is valid but watches an empty metric, the topic is valid but nobody subscribes. Every one of those failures looks like "all quiet".

**A debugging routine that works**
1. `aws logs test-metric-filter` with a real log line: does the pattern match?
2. `aws cloudwatch list-metrics --namespace ...`: does the metric exist, with the namespace and name the alarm uses?
3. `aws cloudwatch describe-alarms`: state reason and which metric it is actually reading.
4. `aws sns list-subscriptions-by-topic` and the alarm's history: was an action executed, and does anyone receive it?

**Preventing silent chains**
- Define filter, alarm and topic in one stack and derive the alarm's namespace and metric name from the filter's outputs rather than retyping them.
- Add an end-to-end "game day" test to the pipeline: write a burst of synthetic ERROR lines in a test environment and assert that a page arrives. This validator does exactly that.
- Alarm on missing data for the chain itself (a "dead man's switch" alarm with `TreatMissingData: breaching` on a heartbeat metric).
- Prefer structured (JSON) logging and JSON metric filter patterns so that a rename of the text does not silently disable the metric.
