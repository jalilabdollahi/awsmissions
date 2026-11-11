# Solution

The export builds a 256 MB canvas in memory (a 16 x 16 block of 512 px tiles is 8192 x 8192 px at 4 bytes per pixel), plus the Node.js runtime itself. The function has 128 MB in total, so the process is killed.

1. Reproduce and look at the settings:

```bash
aws lambda invoke --function-name tile-stitcher --cli-binary-format raw-in-base64-out \
  --payload '{"tiles_per_side":16}' out.json && cat out.json
aws lambda get-function-configuration --function-name tile-stitcher --query MemorySize
```

2. Raise memory so that the canvas, the runtime and some headroom fit (512 MB is a sensible step, and under the 1024 MB cap):

```bash
aws lambda update-function-configuration --function-name tile-stitcher --memory-size 512
```
