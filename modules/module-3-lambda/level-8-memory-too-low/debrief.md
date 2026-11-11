# Debrief: memory is the one dial that sets size, CPU and price

Lambda has a single resource setting: **memory** (128 MB to 10,240 MB). CPU power, network bandwidth and the hourly price all scale with it; at about 1,769 MB you get one full vCPU.

When a function uses more memory than configured, the runtime is killed by the operating system's OOM handling. You get no exception your code can catch: the invocation ends with `Runtime exited with error: signal: killed` (here `exit status 137`, which is 128 + SIGKILL). The CloudWatch `REPORT` line shows `Max Memory Used` right next to `Memory Size`, and that is where you should look first.

**Sizing it properly**
- Add up the real working set: your data (here a 256 MB canvas), the runtime (~40 MB for Node.js), libraries, and a margin of 20 to 30%.
- Higher memory can be *cheaper*: a CPU-bound function that finishes twice as fast at double memory costs about the same, and users wait less. AWS Lambda Power Tuning (open source) automates this search.
- Beware of `Buffer.alloc` / lazy allocation. Memory that is reserved but never written may not count in a test, which is why this function paints every row of the canvas.

**In real life**
- Stream large payloads (S3 `GetObject` bodies, image tiles) instead of holding them whole.
- For work that truly needs more than 10 GB, move to ECS/Fargate or AWS Batch.
- Set a budget alarm: a mistaken jump from 512 to 10,240 MB is a 20x price jump per millisecond.
