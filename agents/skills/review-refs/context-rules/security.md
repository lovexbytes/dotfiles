# Context Rules: Security Agent

Before analyzing diffs, read this table. When you see a trigger pattern in the diff, load the additional context described.

| Trigger in diff | What to load | How | Why |
|---|---|---|---|
| `fmt.Sprintf` near SQL query or `db.Query`/`db.Exec` | Full query builder / repository file | Use File Access instructions from your prompt | Check if user input reaches query via Sprintf — must use parameterized queries |
| `os/exec.Command` or `exec.CommandContext` | Full handler chain — where does the command argument come from? | Use File Access instructions from your prompt | Command injection if user input is unsanitized |
| `filepath.Join` or `os.Open` with variable path | HTTP handler or function receiving the path | Use File Access instructions from your prompt | Path traversal — check for `filepath.Clean` + base path validation |
| Hardcoded string looking like token/password/key | N/A (local check) | N/A | Credentials must come from env/config, never hardcoded |
| `md5` or `sha1` used for password/auth | Full auth module | Use File Access instructions from your prompt | Must use bcrypt/argon2 for passwords |
| `crypto/rand` vs `math/rand` | Full file | Use File Access instructions from your prompt | Security-sensitive randomness must use crypto/rand |
| `http.ListenAndServe` (not TLS) | Main/server setup | Use File Access instructions from your prompt | Check if TLS termination happens at proxy level |
| Integer arithmetic in money/size/limit calculations | Full function | Use File Access instructions from your prompt | Integer overflow can bypass security checks |
| `template.HTML` or `template.JS` | Full handler | Use File Access instructions from your prompt | XSS risk — unescaped user input in templates |
| `http.Get`/`http.Post`/`http.NewRequest` with variable URL | Full handler chain — where does the URL come from? | Use File Access instructions from your prompt | SSRF — attacker can probe internal network if URL is user-controlled |
| `http.Redirect` with variable URL | Full handler — where does redirect URL come from? | Use File Access instructions from your prompt | Open redirect — phishing via trusted domain |
| `float32` / `float64` used for amount / money / balance / price / fee in struct field, function signature, JSON tag, or sqlc column type | Full chain: producer, DB schema/migration, consumer | Search repo for the field name, then use File Access instructions | Float drift and rounding errors; must use int64 minor units or `decimal.Decimal` end-to-end |
| Struct field named `email`, `phone`, `name`, `pan`, `iban`, `token`, `secret`, `password`, `authorization`, `cookie`, `tax_id`, `document_no`, `dob` | Every place the struct is logged, serialized to metrics/traces, used as a cache key, or returned in an error message | Search repo for the field name, then use File Access instructions | Verify redaction at every telemetry surface |
| Audit-related call / table write (`audit.Log`, `auditlog`, `audit_events`, or equivalent) added/removed/modified | Full function + every branch returning from the operation (including error branches) | Use File Access instructions from your prompt | Audit must fire on success, failure, and partial-failure branches |
| New state-changing operation on a ledger/balance/outbox/money table without an audit or event side-effect in the same function | Full function + reconciliation pipeline (search for `reconcil*`) | Use File Access instructions from your prompt | Reconciliation cannot anchor the change to a single source of truth |
