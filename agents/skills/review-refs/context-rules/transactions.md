# Context Rules: Transactions Agent

Before analyzing diffs, read this table. When you see a trigger pattern in the diff, load the additional context described.

| Trigger in diff | What to load | How | Why |
|---|---|---|---|
| `tx.Begin()` or `db.BeginTx` | Full function + all callers | Use File Access instructions from your prompt | Verify `defer tx.Rollback()` exists, Commit on success, rollback on ALL error paths |
| `UPDATE` or `INSERT` statement | Other writes to the same table(s) in the repo | Search repo for table name, then use File Access instructions | Check for concurrent modification, missing WHERE clause, consistency |
| Multiple local state changes in one handler (DB + cache + local tables) | Full handler/service method | Use File Access instructions from your prompt | Verify atomicity — if DB succeeds but cache fails, is local state consistent? |
| External API call or message publish inside a DB transaction | Full transaction scope | Use File Access instructions from your prompt | External calls can timeout while holding DB locks; distributed handoff safety belongs to `distributed-operations` |
| `DELETE` statement | Related INSERT/UPDATE and foreign key constraints | Search for table name, check migration files via File Access instructions | Cascade effects, orphaned records |
| Redis/cache SET after DB write | Full function | Use File Access instructions from your prompt | If DB write succeeds but cache SET fails, stale data is served |
| Local retry inside a transaction or local write path | Full function | Use File Access instructions from your prompt | Verify local uniqueness guards; retry/replay safety across external effects belongs to `distributed-operations` |
| `context.WithTimeout` near `tx.Begin`/`db.BeginTx` | Full function — check rollback on context cancel | Use File Access instructions from your prompt | Context cancellation doesn't auto-rollback — transaction stays open holding connection |
| Same table / aggregate written from ≥2 files or ≥2 branches in the same function (one branch inside `WithTx`/tx, another branch direct) | All writer call sites for the table/aggregate | Search repo for the table name or helper that performs the write, then use File Access instructions | Inconsistent tx scoping across completion/cancel branches allows races and interleaved sibling writes |
