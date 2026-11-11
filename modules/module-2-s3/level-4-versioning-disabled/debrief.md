# Debrief: versioning is a bucket setting, and it is not retroactive

Without versioning, S3 treats a key as a single slot: `PutObject` on an existing key replaces the old bytes for good. With versioning **Enabled**, every write gets a unique `VersionId`, the latest version answers plain GETs, and older versions stay addressable with `--version-id`.

**Things worth knowing**
- Objects written *before* versioning was enabled get the version id `null`. They are kept as the oldest version once you enable it.
- A plain DELETE on a versioned bucket does not erase anything; it adds a *delete marker*. Deleting a specific version id is the only way to destroy data.
- Every version is billed as a full object. Pair versioning with a lifecycle rule for `NoncurrentVersionExpiration` so old revisions do not pile up forever.
- Listing versions needs `s3:ListBucketVersions`; reading one needs `s3:GetObjectVersion`. The service had both, which is why only the bucket setting was missing.

**In real life**
- Turn versioning on at bucket creation for anything an application overwrites: contracts, configuration, state files.
- Consider MFA Delete or Object Lock for documents that must never be destroyed.
- Versioning is the cheapest defence against "I just overwrote the wrong file".
