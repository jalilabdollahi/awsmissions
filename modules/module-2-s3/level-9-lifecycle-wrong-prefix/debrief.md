# Debrief: lifecycle prefixes are plain "starts with" matches

A lifecycle rule applies to an object when the object's key **starts with** the rule's prefix. There are no globs and no "contains": `logs/` matches `logs/a.txt` but not `app-logs/a.txt`. The rule was valid, enabled and silently inert.

**Why nobody noticed**
S3 does not warn when a rule matches zero objects. Lifecycle also runs asynchronously (typically once a day), so a wrong rule looks identical to a rule that has not run yet.

**Scoping rules safely**
- An empty prefix applies to the entire bucket. That is dangerous next to data with a different retention requirement, like the audit logs here.
- When several rules match an object, the shortest expiration wins. A broad rule can therefore override a careful one.
- Tag and object-size filters let you scope more precisely than prefixes alone.

**In real life**
- After writing a rule, list a few real keys and mentally apply it, or script the check as this validator does.
- Use `Expiration` with `NoncurrentVersionExpiration` on versioned buckets, or deleted logs will live on as noncurrent versions.
- For compliance data prefer Object Lock over "no rule", because a later broad rule could still delete it.
