# Debrief: Firehose is a batcher, and batching is a latency budget

For S3 destinations Firehose buffers incoming records and flushes when **the first** of two thresholds is hit:

- `SizeInMBs`: the buffered size (1 to 128 MB);
- `IntervalInSeconds`: time since the buffer started filling (the API accepts 0 to 900, default 300; 0 means "zero buffering").

Low traffic means the interval always wins, so *latency is the interval*. High traffic hits the size first, so objects are bigger and appear sooner. That explains why this stream looked fine in a load test (it filled 128 MB quickly) and terrible in production.

**The trade-off.** Shorter intervals give fresher data but many more, smaller S3 objects. Small files hurt downstream readers (Athena, Glue and Spark pay per object and per request), cost more in `PUT` requests and slow listings. Pick the largest interval your freshness requirement tolerates; if you need seconds, consider reading the stream directly (Kinesis + Lambda) and use Firehose for the archive copy.

**Compression.** `CompressionFormat` of `GZIP`, `ZIP`, `Snappy` or `HADOOP_SNAPPY` shrinks objects before they are written and typically saves 70-90% for JSON. GZIP files get a `.gz` suffix and are read transparently by Athena. Note that the buffer size is measured *before* compression, so compressed objects are smaller than `SizeInMBs`.

**Also relevant**
- Firehose concatenates records with no separator: send a trailing newline with each record (or add it in a transformation) if you want one JSON document per line.
- Changing the hints affects buffers that have not been flushed yet. Records already buffered may still wait for the old interval to expire.
