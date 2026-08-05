# Context Rules: Compatibility Agent

Before analyzing diffs, read this table. When you see a trigger pattern in the diff, load the additional context described.

| Trigger in diff | What to load | How | Why |
|---|---|---|---|
| HTTP handler signature change (new required field, removed field, type change, new required query param/header) | Router registration + OpenAPI/Swagger spec (if present) + any known client SDKs in the monorepo | Use File Access instructions from your prompt; search for route constant | Mixed-rollout clients send old shape against new server |
| Changed HTTP response body shape | Callers of the API across the monorepo (other services, worker jobs) | Search repo for the path or response DTO type, then use File Access instructions | Old clients parse old shape; new response may break them |
| Field added/removed/renumbered/retyped in a `.proto` file | Previous proto revision from target branch + every generated Go/Java/TS client/server using it | Load target-branch proto via File Access with the target branch ref; search for proto package name | Wire compatibility across versions |
| Proto field number reused or deleted without `reserved` | Previous proto revision + service definition file | Use File Access instructions from your prompt | Future reuse will silently clash |
| New SQL migration file | Previous migrations touching the same table + the sqlc queries reading the table + handlers calling those queries | Use File Access instructions from your prompt; search for table name | Old binary + new schema and new binary + old schema windows during rollout |
| `ALTER TABLE ... ADD COLUMN ... NOT NULL` / `ADD CONSTRAINT` / `DROP COLUMN` / `RENAME COLUMN` | Full migration file + prior migration for the same table + queries referencing the column | Use File Access instructions from your prompt | Validate old-binary tolerance during rollout; validate rollback safety |
| Change in published event type, subject, or payload field | Producer file + every consumer across repos (search for subject constant or proto message name) | Search repo for subject/type name, then use File Access instructions | Producer/consumer coordinate during rollout |
| Change in Redis key construction (prefix, separator, version segment) or stored value schema | Every reader and writer of the key | Search repo for the key prefix or helper that builds the key, then use File Access instructions | Old binary writes old key/value; new binary reads new |
| Change in outbox/job/scheduler table row shape | Producer write path + consumer read path + pending-row replay code | Use File Access instructions from your prompt | In-flight rows must be interpretable by both versions |
| Renamed/removed env var, CLI flag, or config key | Config loader + deployment manifests/Helm values + service start-up validation | Use File Access instructions from your prompt | Old deployment configs silently fall back to defaults |
| Removed or renamed exported function/method that could be called by other services in the monorepo | Callers across the monorepo | Search repo for the symbol, then use File Access instructions | Cross-service references must not snap |
| Change to state-machine enum values in a persisted column | Enum Go definition + every `switch` over the enum + migration history | Search repo for enum values, then use File Access instructions | Unknown value handling across versions |
| Change to feature-flag default or scope | Flag definition + every read site + off-path code | Search repo for flag name, then use File Access instructions | Verify "off" path does not exercise the new code |
| Rolling-update strategy tightened/loosened in Helm/K8s manifest | Previous manifest + change in schema/consumer code in the same review | Use File Access instructions from your prompt | Combination with schema change can lose in-flight traffic |
