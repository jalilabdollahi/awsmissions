# Debrief: escalation #8841, uploads without thumbnails

## Root causes
1. The notification configuration was attached to the staging bucket, with the staging suffix (`.jpeg`). Production uploads emitted no events at all. Worse, every staging test upload would have hit the production function.
2. The execution role's `s3:GetObject` pointed at the staging bucket, a classic symptom of cloning policies without reading them.
3. `THUMB_BUCKET` named a bucket that was renamed during the reorganisation.

## Timeline
- Mon: "storage reorganisation" moves buckets and re-creates triggers by copying the staging configuration.
- Mon-Tue: uploads succeed (S3 itself is fine), so no alarms fire. There is no error to alert on, because S3 emits nothing when no notification matches.
- Wed: photographers notice grey galleries; ticket #8841.

## How the pieces interact
S3 evaluates a bucket's notification configuration on every ObjectCreated event: destination, event types and key filters all have to match, or nothing happens and nothing is logged. Once the function runs, it uses its role for every S3 call, so a role scoped to the wrong bucket fails inside the function, visible only in the function's own errors.

## Lessons
- "Nothing happened" has no log line. Alarm on the absence of expected output (thumbnails per hour), not only on errors.
- Keep triggers, roles and environment variables in the same IaC change so a bucket rename updates all three.
- Never let a function write to the bucket that triggers it. If it must, use a separate prefix with a non-overlapping filter, and set a reserved concurrency cap as a seatbelt.
- Test a filter with both a match and a non-match.
