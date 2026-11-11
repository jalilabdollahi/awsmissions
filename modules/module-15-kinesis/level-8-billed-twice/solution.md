# Solution

The checkpoint holds the sequence number of the **last event that was billed**. `billing.py` resumes with an `AT_SEQUENCE_NUMBER` iterator, which starts *at* that record and returns it again, so the previous run's last event is billed a second time on every run. `AFTER_SEQUENCE_NUMBER` starts with the next record.

1. Confirm in the ledger (do not run the function first, it would bill the event again):

```bash
aws ssm get-parameter --name /brightline/billing/checkpoint
aws dynamodb scan --table-name invoice-lines
```

2. In `billing.py` (`edit`) change `"AT_SEQUENCE_NUMBER"` to `"AFTER_SEQUENCE_NUMBER"`.

3. Deploy:

```bash
zip billing.zip billing.py
aws lambda update-function-code --function-name billing-resume --zip-file fileb://billing.zip
```

4. `check` builds its own mini-scenario (one billed event, two new ones), invokes the function and verifies the ledger and the checkpoint. It does not touch the real invoice lines.
