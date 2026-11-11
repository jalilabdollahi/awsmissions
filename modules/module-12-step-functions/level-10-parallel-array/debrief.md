# Debrief: Parallel and Map return arrays

Both `Parallel` and `Map` collect results into an **array**:

- Parallel: one entry per *branch*, in the order the branches are written, not the order they finish.
- Map: one entry per *item*, in input order.

Each branch receives a copy of the state's whole input, and the state's output is the array of branch outputs. Anything the next state wants by name has to be built from that array. Three tools do that:

1. `ResultSelector` reshapes the raw result before it is stored: `{"billing.$": "$[0]"}` picks element 0.
2. `ResultPath` decides where the reshaped result lives in the original input (`"$.lookups"` keeps `customerId`; the default `"$"` replaces everything).
3. A following `Pass` state with `Parameters` can merge and rename. `States.JsonMerge($.a, $.b, false)` merges two objects into one.

Because order matters, adding or reordering a branch silently changes what `$[1]` means. If the branches are likely to change, name the results at the end of each branch (a final `Pass` with `Parameters: {"billing.$": "$"}`) and merge them.

**In real life**
- An error in any branch fails the whole Parallel state (other branches are cancelled). Put `Retry` and `Catch` *inside* branches when one lookup is optional.
- All branches pay for their own transitions; parallel is about wall-clock time, not cost.
- The state output size limit (256 KiB) applies to the combined array. Select only the fields you need with `ResultSelector`.
