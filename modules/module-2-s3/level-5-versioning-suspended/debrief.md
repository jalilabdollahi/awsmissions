# Debrief: Suspended is not Disabled, and "restore" means "copy forward"

A bucket's versioning state has three values: never enabled, `Enabled`, and `Suspended`. Once a bucket has been versioned it can never go back to "never enabled", only to `Suspended`.

**What Suspended does**
- Existing versions are kept.
- New writes get the version id `null` and *replace* any previous `null` version. So the safety net is gone exactly when people need it.
- Deletes create a `null` delete marker instead of a unique one.

That is how a bad deploy could silently overwrite flags.json even though earlier versions were still sitting in the bucket.

**Restoring a version**
There is no "rollback" API. You either `copy-object` an old version onto the current key (creating a new latest version and keeping the full history), or delete the newer versions. Copying forward is safer because it is itself reversible.

**In real life**
- Prefer lifecycle rules (`NoncurrentVersionExpiration`) over suspending versioning to control cost.
- Use `aws s3api list-object-versions` and look at `IsLatest` and `LastModified`; the console can hide the `null` version problem.
- Protect configuration buckets with bucket policies that deny `s3:PutBucketVersioning` to everyone except an admin role.
