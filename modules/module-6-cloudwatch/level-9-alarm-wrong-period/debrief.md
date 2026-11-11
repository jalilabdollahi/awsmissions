# Debrief: period, evaluation periods and time to detect

The time an alarm needs to notice a problem is roughly `Period x EvaluationPeriods`, plus the delay with which the metric data arrives. A 300-second period with one evaluation means the alarm looks at a whole five-minute aggregate; with `DatapointsToAlarm` you can require "3 out of 5" such windows, which makes it slower still.

**Choosing the numbers**
- Short periods (60 s, or 10/30 s for high-resolution metrics) detect bursts quickly but are noisier. Combine them with `EvaluationPeriods` and `DatapointsToAlarm` (for example 3 of 5) to filter blips without waiting for a whole long window.
- Long periods suit slow-moving, expensive-to-be-wrong signals such as daily cost or weekly backups.
- A `Sum` statistic over a longer period reaches the threshold *more easily* (more data adds up), while `Average` dilutes spikes: a 300 BounceMessages burst in one minute averaged over five minutes is a small number.
- Standard metrics are published at one-minute granularity, so periods must be multiples of 60 seconds; 10 and 30 seconds need high-resolution metrics (`StorageResolution=1`).

**In real life**
- State the detection-time requirement in the runbook ("page within 2 minutes of sustained errors") and derive period and evaluation periods from it.
- Use the alarm's `StateReason` and history (`describe-alarm-history`) after an incident to measure how long detection really took.
- If you only see a spike in logs, a metric filter turns it into a metric you can alarm on at one-minute resolution.
