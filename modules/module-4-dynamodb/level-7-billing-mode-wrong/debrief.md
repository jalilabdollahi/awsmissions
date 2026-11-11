# Debrief: choosing between provisioned and on-demand

|  | Provisioned | On-demand |
|---|---|---|
| You pay for | capacity you reserve per hour | requests you actually make |
| Throttling | when you exceed the number you set | only beyond very high per-partition limits, and on instant 2x jumps from the previous peak |
| Best for | steady, predictable load (and reserved capacity discounts) | spiky, unknown or brand new workloads |

Ticketflash's profile (idle for weeks, then a vertical wall) is the textbook case for on-demand. Auto scaling is slow because it works from CloudWatch averages over minutes, so it can never catch a one-minute spike.

Operational details:
- The switch is an in-place operation (`update-table --billing-mode`) with no downtime. After a switch, you can only change billing mode again once every 24 hours.
- Indexes follow the table. You cannot give an index its own capacity on an on-demand table.
- Application Auto Scaling targets and policies are separate resources. They are not removed when you change the mode, so IaC and manual cleanup have to do it; otherwise dashboards and alarms show phantom scaling activity.
- On-demand tables "remember" the previous peak: new tables start with room for roughly 4,000 writes and 12,000 reads per second, and double from the highest traffic they have seen. If you expect a launch far above anything seen, pre-warm by setting warm throughput.

Cost sanity check: if utilisation of provisioned capacity would be above roughly 15-20 percent over the month, provisioned (with auto scaling) is usually cheaper. Flat, busy workloads should stay provisioned.
