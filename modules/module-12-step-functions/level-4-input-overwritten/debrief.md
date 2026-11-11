# Debrief: state output replaces state input unless you say otherwise

Every state in a state machine receives a JSON document and passes one on. For a Task, the default is brutal: the task's **result becomes the next state's input**, and whatever came in is thrown away. That is `ResultPath: "$"`, the implicit default.

Lumen's Lambda only knew about scoring, so only the score survived.

Five fields shape the data around a Task, applied in this order:

1. `InputPath` selects the part of the input to work with.
2. `Parameters` builds the payload actually sent to the task.
3. `ResultSelector` reshapes the task's raw result.
4. `ResultPath` decides where the result is placed in the **original** input (`"$.fraud"` adds it, `"$"` replaces everything, `null` discards the result).
5. `OutputPath` filters what finally leaves the state.

**In real life**
- Make `ResultPath` a habit on every Task that is not the last step. Name it after what it holds (`$.fraud`, `$.payment`, `$.shipping`).
- `ResultPath: null` is the right choice for "fire and forget" calls such as sending a notification: you keep your data and ignore the response.
- The execution history stores each state's input and output. Comparing `TaskStateEntered` and `TaskStateExited` is the quickest way to see where data disappears.
- Very large results can hit the 256 KB payload limit. Use `ResultSelector` to keep only the fields you need.
