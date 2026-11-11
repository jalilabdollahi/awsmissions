# Solution

`create-stack` is rejected with `YAML not well-formed (line 9, column 4)`. That line is `   DelayTopic:`, indented with three spaces while the other resource under `Resources:` uses two.

1. Open the template (`edit`) and align `DelayTopic:` with `TimetableBucket:`:

```yaml
Resources:
  TimetableBucket:
    ...
  DelayTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: harborlights-delay-alerts
```

2. Deploy and wait for it:

```bash
aws cloudformation create-stack --stack-name harborlights-core --template-body file://template.yaml
aws cloudformation wait stack-create-complete --stack-name harborlights-core
```

3. Run `check`. It looks at the stack status and confirms the bucket is versioned and the topic exists.
