# Context Rules: Correctness Agent

Before analyzing diffs, read this table. When you see a trigger pattern in the diff, load the additional context described.

| Trigger in diff | What to load | How | Why |
|---|---|---|---|
| `defer` inside a `for` loop | Full function containing the loop | Use File Access instructions from your prompt | Understand scope — defer executes at function exit, not loop iteration |
| Ignored error: `_ = f()` without comment | The calling function and callers of current function | Use File Access instructions from your prompt | Assess criticality — is this in a critical path? |
| `resp.Body` or `*http.Response` without `defer resp.Body.Close()` | Full HTTP handler/function | Use File Access instructions from your prompt | Check ALL exit paths — early returns may skip Close |
| `*sql.Rows` without `defer rows.Close()` | Full function | Use File Access instructions from your prompt | Same as above — check all exit paths |
| `*os.File` without `defer f.Close()` | Full function | Use File Access instructions from your prompt | Same — resource leak on error paths |
| `panic()` in non-test code | Full function + callers | Use File Access instructions from your prompt | Determine if panic is in init/main or leaks into normal flow |
| `nil` returned where pointer is expected | Interface definition and callers | Use File Access instructions from your prompt | Check if callers handle nil |
| Type assertion without ok check: `x.(T)` | Full function | Use File Access instructions from your prompt | Will panic on wrong type at runtime |
| `context.WithCancel` or `context.WithTimeout` without `defer cancel()` | Full function | Use File Access instructions from your prompt | Derived context leaks goroutines and resources until parent is cancelled |
| `ctx, cancel := context.WithTimeout` or `ctx, cancel := context.WithCancel` inside an `if` block | Full function containing the `if` | Use File Access instructions from your prompt | Inner `ctx` shadows outer `ctx`; deadline/cancellation may never apply after the block |
| Exported function or method declares the **last** or **only** return as a concrete error pointer type (e.g. `func F() *MyError`, not `func F() error`) | Full function + callers | Use File Access instructions from your prompt | Nil `*MyError` is a non-nil `error` interface — callers see err != nil when logic expects nil |
| `return e` (or similar) where `e` is a variable of concrete pointer error type and the function's **declared** return is `error` | Full function | Use File Access instructions from your prompt | Typed nil `*T` assigned to `error` becomes non-nil interface |
| Unique constraint (`23505`) caught / `ON CONFLICT DO NOTHING` / upsert returning existing row on an idempotent create path | Full function + all metric/log calls on that path | Use File Access instructions from your prompt | Verify metric increments and gauge `inc`/`dec` are gated behind "new row actually inserted" |
| Type conversion from string or int into a domain enum at a boundary (`Mode(v)`, `Status(v)`, `Kind(s)`) in config loader / request parser / DB scan | Full function + the enum's definition file | Use File Access instructions from your prompt | Unknown values propagate silently; validate at the boundary |
| Function parameter named like a logical key (`stepIndex`, `version`, `sequenceNo`) used to index a slice built by `ORDER BY <that key>` | Full function + callers | Use File Access instructions from your prompt | Slice ordinal vs logical key mismatch — gaps in the key yield wrong row |
