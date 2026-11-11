# Debrief: a threshold has to live inside the metric's range

An alarm compares one number against another, so both must be on the same scale. Three common ways to get the threshold wrong:

1. **Wrong magnitude** (this level): 900 instead of 90, or 0.9 for a metric reported as 0 to 100. Check the unit and range of the metric first. EC2's `CPUUtilization` is 0 to 100; some custom metrics use a 0 to 1 ratio.
2. **Wrong unit**: seconds against a metric in milliseconds, bytes against kilobytes, percent against a ratio.
3. **Wrong statistic**: a threshold of 90 on `Average` over 5 minutes needs a long period of saturation, while the same threshold on `Maximum` fires on one spike.

**Why it is dangerous.** An alarm that cannot fire shows up as a green dashboard. It is the monitoring equivalent of a smoke detector with no battery, and you only learn it at the next incident. `OK` is not evidence of health.

**In real life**
- Look at the metric's recent range in the console or with `get-metric-statistics` *before* choosing a threshold, and put the alarm line on the graph.
- Every alarm should be tested once: publish a value past the threshold (as this validator does, or with `aws cloudwatch set-alarm-state` for a quick check of the action path) and confirm the notification arrives.
- Review alarms after a unit change in the producer (a library upgrade that switches from percent to ratio breaks thresholds silently).
