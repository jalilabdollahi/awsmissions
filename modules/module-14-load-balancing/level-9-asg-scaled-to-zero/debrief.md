# Debrief: min, desired, max (and the schedule that rewrites them)

An Auto Scaling group has three numbers. **Desired** is what the group tries to run right now. **Min** and **Max** are the fence around desired: scaling policies and manual changes can only move desired between them. The group launches instances until the running count equals desired. Setting `desired` above `max` is rejected.

**Why "scaled down by hand" bites later**
- A group with `min=0` can be taken to zero by anyone or anything, including a scale-in policy on a quiet night.
- Setting `max` equal to `desired` removes all headroom: scaling policies fire but nothing can launch.
- A **scheduled action** applies its min/max/desired at its time, every time if it has a recurrence. Fixing capacity without removing the schedule only postpones the next outage to 22:00. Look at `describe-scheduled-actions` any time capacity changes "by itself".

**Good practice for cost-saving schedules**
- Scale *down to a safe floor* (for example 2, one per AZ), never to zero for a customer-facing service.
- Pair every scale-down with a scale-up action, and keep both in code review.
- Set min to the number of instances you need to survive an AZ failure; let target-tracking policies handle the rest.
- With an attached target group, the group registers and deregisters instances for you, which is what makes this fix a one-liner instead of a rebuild.
