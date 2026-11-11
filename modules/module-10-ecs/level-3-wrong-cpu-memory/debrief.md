# Debrief: Fargate sizes are a menu, not free-form

On Fargate you pay for the task's vCPU and memory, and AWS only sells specific combinations (for example 0.25 vCPU with 0.5-2 GB, 0.5 vCPU with 1-4 GB, 1 vCPU with 2-8 GB). Anything else is rejected at registration with "No Fargate configuration exists for given values".

Two levels of memory settings are easy to confuse:
- **Task-level** `memory` (and `cpu`): the size of the whole task. Required on Fargate.
- **Container-level** `memory` (hard limit, kills the container) and `memoryReservation` (soft limit). The sum must fit inside the task memory.

Real-world tips:
- Start small, watch CloudWatch `MemoryUtilization`/`CpuUtilization` and adjust. Over-sizing is the default way to overspend on Fargate.
- A container hitting its hard limit exits with code 137 (OOM) and `OutOfMemoryError: Container killed due to memory usage`.
- Larger sizes need larger platform support (>16 vCPU, ephemeral storage), so check the current limits in the docs.
