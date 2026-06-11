# Context Rules: SQL Data Access Agent

| Trigger in diff | What to load | How | Why |
|---|---|---|---|
| SQL query string or sqlc query changed | Full query file + generated sqlc method + direct callers | Use File Access instructions from your prompt | Verify query contract, scan types, and caller assumptions |
| Migration touches a table queried in changed code | Previous migrations for table + repository queries + indexes | Search table name, then use File Access instructions | Verify schema/query/index fit |
| `LEFT JOIN`, aggregate, nullable column, or `COALESCE` changed | Table schema + Go scan destination type | Use File Access instructions from your prompt | Null scan traps often appear only at runtime |
| `LIMIT`, `OFFSET`, cursor, or `ORDER BY` changed | Caller pagination contract + existing indexes | Use File Access instructions from your prompt | Verify stable ordering and cursor correctness |
| `Query`, `QueryRow`, `Scan`, `rows.Next`, or `rows.Err` changed | Full repository method + callers | Use File Access instructions from your prompt | Verify error/no-row/multi-row semantics |
| `ON CONFLICT`, unique index, or upsert changed | Unique constraints + business key callers | Use File Access instructions from your prompt | Conflict target must match logical identity |
