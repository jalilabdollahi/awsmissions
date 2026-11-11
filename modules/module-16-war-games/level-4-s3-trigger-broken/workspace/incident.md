# Support escalation #8841 - "Where are my thumbnails?"

Marigold Photo Studio, gallery platform. Customer-facing: wedding photographers.

## Report
Photographers upload their shoots (`.jpg` files) to `mg-photo-uploads`. The
gallery page builds its previews from `mg-photo-thumbs`. Since Monday's
"storage reorganisation" the gallery shows grey boxes for every new upload.
Old galleries are fine.

## How it is supposed to work
1. Upload lands in `s3://mg-photo-uploads/` (JPEG only; other file types are
   ignored on purpose, photographers upload contact sheets and notes too).
2. S3 notifies Lambda `mg-thumbnailer`.
3. The function reads the original and writes `thumb-<name>` to the bucket named
   in its `THUMB_BUCKET` setting.

## Things people told me
- "We copied the trigger setup from the staging bucket when we reorganised."
- "Marcus created a new IAM policy for the thumbnailer, cloned from staging too."
- "The staging bucket `mg-photo-uploads-staging` is for testers. Test uploads
  must never produce production thumbnails."
- The on-call user `mg-oncall` can assume the thumbnailer's role to try
  things by hand.

## Warning
The thumbnailer must never be able to write into `mg-photo-uploads`: a
function that writes into the bucket that triggers it is a recursive loop and a
very expensive afternoon.
