# Debrief: a storage class is an object property, set by rewriting it

**Storage classes** trade price for access: STANDARD (hot), STANDARD_IA / ONEZONE_IA (infrequent), GLACIER_IR (instant archive), GLACIER (minutes to hours) and DEEP_ARCHIVE (up to 12-48 hours). The first requests to an archived object fail with `InvalidObjectState` until you `restore-object` it, which is why the site "loaded for hours".

**Two ways an object lands in a class**
- explicitly, with `--storage-class` on upload or copy;
- implicitly, through lifecycle `Transitions`, which applies to everything whose key matches the rule's prefix.

The second one was the real culprit. Moving the object back without removing the rule would have repeated the problem the next day.

**Changing the class**
There is no `put-object-storage-class`. A `copy-object` of the object onto itself with a new class creates a new version. Two details matter:
- the default `--metadata-directive COPY` carries over Content-Type and user metadata. `REPLACE` takes them from your command line, so anything you forget is erased;
- for archived objects (GLACIER/DEEP_ARCHIVE) a real bucket requires a `restore-object` first and the copy only works from the restored temporary copy.

**Minimum duration and size charges**
IA and Glacier classes bill a minimum storage duration (30, 90, 180 days). Moving things around quickly can cost more than leaving them.

**In real life**
- Check rule prefixes against real keys before enabling a transition (see the lifecycle levels).
- Use S3 Intelligent-Tiering for data with unpredictable access instead of time-based transitions.
