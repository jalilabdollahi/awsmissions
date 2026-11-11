# Debrief: TTL is only a name plus a contract on the data

`UpdateTimeToLive` takes one thing: the **name** of an attribute. From then on a background process deletes items whose value in that attribute is a Number holding an epoch timestamp **in seconds** that lies in the past. If an item lacks the attribute, has a string, or stores milliseconds (a value 1000x too large looks like year 55000), it never expires. DynamoDB will not warn you about any of this; `describe-time-to-live` says `ENABLED` either way.

What to remember:
- TTL deletion is eventual. In AWS it usually happens within minutes, but can lag up to a couple of days. Do not rely on it for hard security cutoffs. Always filter expired items in reads (`expiresAt > :now`) if correctness matters.
- Deletes are free: they do not consume write capacity. They do appear in DynamoDB Streams as REMOVE records with a `userIdentity` of `dynamodb.amazonaws.com`, which is how you hook cleanup logic (for example archive to S3).
- Changing the TTL attribute requires disabling TTL first, and AWS limits how often you can change it.
- Because the only "schema" is an attribute name, enforce the format in the writer: epoch seconds as `N`.
- Items already expired when TTL is turned on are removed too, so enabling it on an old table can delete a lot at once. Check what you hold first.
