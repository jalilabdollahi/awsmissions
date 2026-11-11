# Parcelwise ops review - "the queue that ate Black Friday prep"

Parcelwise, sorting-hub platform. Review notes from the weekly ops call.

## What happened
A malformed parcel record (`poison: true` in our test data, a null weight in
production) entered the sort-jobs queue on Thursday. The consumer threw on it,
the message came back, was retried, threw again... and nobody was notified.
The retry storm hammered the consumer for hours and the sort stats went red.
We only found out because the hub supervisor phoned.

## Intended design
    producers --> SQS pw-sort-jobs --> sorter worker fleet (outside AWS, polls the queue)
                      |
                      | after a few failed receives
                      v
                  SQS pw-sort-jobs-dlq         <-- ops must be PAGED when this is non-empty

    Paging path: CloudWatch alarm -> SNS topic pw-ops-alerts -> SQS pw-ops-pager

## Numbers we agreed on
- A sorter worker needs up to 30 seconds to finish one parcel.
- A failing message may be received at most 3 times before being parked in
  the DLQ (anything above 5 is a bug: we saw 100 in the config).
- The queue's visibility timeout must give a worker room to finish; if it is
  shorter than the processing time, a slow-but-healthy parcel is handed to a
  second worker while the first is still sorting it.
- Any message in the DLQ must page ops within minutes.

## Facts
- The DLQ is `pw-sort-jobs-dlq`. Someone typed a different name into the
  redrive policy "from memory".
- The workers are not part of this ticket; the queue configuration and the
  alarm are.
