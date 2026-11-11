# Solution

1. **Trigger.** The notification was cloned onto `mg-photo-uploads-staging` with a `.jpeg` suffix filter. Remove it from staging (`put-bucket-notification-configuration` with `{}`) and put a Lambda notification on `mg-photo-uploads` instead, with `s3:ObjectCreated:*` and a suffix rule of `.jpg`. Dropping the filter would make `.txt` notes produce thumbnails.
2. **Role policy.** `s3:GetObject` was scoped to `mg-photo-uploads-staging/*`. Change it to `mg-photo-uploads/*`. Do not add `PutObject` on the uploads bucket: a function that writes into the bucket that triggers it creates a loop.
3. **Function environment.** `THUMB_BUCKET` is `mg-photo-thumb`; set it to `mg-photo-thumbs`.

`check` triages each stage (trigger configuration, a direct invoke with a synthetic record, the thumbs bucket), then uploads a real JPEG, a text file and a staging JPEG, and verifies that only the production JPEG becomes a thumbnail.
