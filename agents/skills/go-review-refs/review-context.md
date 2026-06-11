# Review Context Contract

Use this contract in Phase 1 before launching agents. The goal is to make every agent start from the same map of the change instead of rediscovering files independently.

## Artifact

Write `{{tmp_dir}}/review-context.json` with this shape:

```json
{
  "scope": "mr|branch|local",
  "changed_go_files": [
    {
      "path": "internal/service/user.go",
      "old_path": "internal/service/user.go",
      "status": "added|modified|deleted|renamed",
      "diff_path": "{{tmp_dir}}/diffs/internal-service-user.go.diff",
      "prefetched_path": "{{tmp_dir}}/files/internal/service/user.go",
      "lines_added": 12,
      "lines_removed": 4,
      "symbols_hint": ["CreateUser", "userService"],
      "trigger_hints": ["error-path", "db-write", "http-handler"],
      "agent_hints": {
        "correctness": ["error-path"],
        "tests": ["behavior-change"],
        "transactions": ["db-write"]
      }
    }
  ],
  "contract_files": [
    {
      "path": "cmd/migrations/20260501_add_users.up.sql",
      "type": "sql-migration"
    }
  ],
  "aggregate_hints": ["db-write", "schema-change"],
  "agent_plan": {
    "correctness": {
      "decision": "run",
      "reason": "baseline correctness review for changed Go files",
      "files": ["internal/service/user.go"]
    }
  }
}
```

`prefetched_path` is empty for deleted files and for files beyond a prefetch cap. Agents may still load those files through the workflow's File Access rules when context rules require it.

## Trigger Hints

Use cheap diff scanning and path names. Do not need perfect parsing; if unsure, add the hint.

| Hint | Examples |
|---|---|
| `error-path` | `if err != nil`, `fmt.Errorf`, `errors.New`, `return nil, err` |
| `panic-risk` | `panic(`, type assertion `.(T)`, direct indexing, nil pointer-looking change |
| `resource` | `http.Response`, `Rows`, `os.Open`, `Close`, `defer`, `WithTimeout`, `WithCancel` |
| `concurrency` | `go `, `chan`, `sync.`, `atomic.`, `errgroup`, `WaitGroup`, `Mutex`, `Once`, `Ticker`, `Timer` |
| `db-read` | `SELECT`, `Query`, `QueryRow`, `sqlc`, repository/read model path |
| `db-write` | `INSERT`, `UPDATE`, `DELETE`, `Exec`, `Begin`, `Commit`, `Rollback`, repository/write path |
| `sql` | SQL query text, sqlc query file/config, migration, scan destination, index, `rows.Next`, `rows.Err` |
| `cache` | `Redis`, `Cache`, `GET`, `SET`, `DEL`, key builder, TTL |
| `external-call` | HTTP/gRPC client, queue publish, SDK client, card/bank/provider client |
| `handler-api` | handler/controller/router path, request/response DTO, route registration |
| `config` | env var, config struct, feature flag, Helm/K8s values, CLI flag |
| `contract` | `.proto`, OpenAPI/Swagger, public DTO, event schema, migration, Redis format |
| `dependency` | `go.mod`, `go.sum`, `go.work`, `vendor/modules.txt`, Dockerfile/CI image, codegen tool config |
| `security` | auth, token, JWT, password, secret, SQL string building, path/file, template, redirect, money/PII fields |
| `observability` | logger, metric, trace/span, readiness/liveness, resources, rollout strategy |
| `distributed` | retry, backoff, timeout, breaker, queue, consumer, ack/nack, outbox, inbox, idempotency, compensation |
| `domain-invariant` | money, ledger, balance, account/card status, KYC, limits, fees, operation state |
| `money` | amount, currency, fee, balance, ledger, hold, settlement, refund, reversal |
| `performance` | loop over collection, query in loop, allocation in loop, regexp/reflect/json in hot path, unbounded fan-out |
| `test-change` | `*_test.go`, testdata, mocks |
| `behavior-change` | new branch, changed return, new side effect, changed function signature |

## Conservative Router

Router decisions are a speed optimization, not a quality shortcut. If confidence is low, choose `run`.

Agent decisions:

| Agent | Run when | Safe `skip` condition |
|---|---|---|
| correctness | Always for changed non-test Go files | Only test-only changes with no implementation diff |
| tests | Always for implementation Go changes; also for changed tests | Only no implementation/test Go files after exclusions |
| conventions | Exported symbols, interfaces, context/error handling, package/API shape changed | No exported/API/context/error/interface hints |
| style | Package/file naming, routing, interface shape, struct init/slice idioms changed | No style trigger hints and conventions also skipped |
| security | User input, auth, PII, money, config, SQL/exec/path/template/redirect/external URL touched | No security hints, no handler/API/config/PII/money paths |
| performance | Performance hint, hot path, DB loop, fan-out, retry/backoff touched | No performance/external-call/distributed hints |
| deps-supply-chain | Dependency/build/tooling hint, module file, codegen config, Dockerfile, CI image, generated/runtime dependency drift touched | No dependency/build/tooling/codegen hints and no dependency files in `contract_files` |
| sql-data-access | SQL query, sqlc, repository data-access, migration, nullable scan, pagination, index, or DB read/write hint touched | No sql/db-read/db-write/migration/sqlc/repository hints |
| observability | Logs/metrics/traces, external calls, consumers/workers, deploy manifests touched | No observability/external-call/distributed/config hints |
| concurrency | Concurrency hint present | No concurrency hints |
| consistency | Exported signature/type/interface/API/cross-package contract changed | No cross-file/API/type/interface hints |
| transactions | DB write, transaction, cache/local state boundary touched | No db-write/cache/transaction hints |
| compatibility | Contract, public API, config, migration, proto, event, Redis format, deploy rollout touched | No contract/config/schema/public API hints and `contract_files` empty |
| distributed-operations | Retry, queue, consumer, outbox/inbox, idempotency, external side effect, degraded dependency touched | No distributed/external-call/db-write+publish hints |
| domain-invariants | Money, ledger, balance, account/card/KYC/limit/fee, operation state, domain event/audit/reconciliation touched | No domain-invariant/money/state-machine/business-rule hints |

When an agent is skipped, the orchestrator writes a valid report JSON with `findings: []`, `files_checked: 0`, and a positive note: `Skipped by conservative router: <reason>`.

If the user supplied `--only`, apply the router only inside that selected set. A selected agent may still be skipped only when its safe skip condition is met. Add all skipped selected agents to final report Verification/Gaps.

## Agent Prompt Rules

Agents must:

1. Read `review-context.json` before any broad search.
2. Start with files listed in `agent_plan.<agent>.files`.
3. Read matching prefetched Go files from `{{tmp_dir}}/files/` first.
4. For planned non-Go paths from `contract_files`, load source and target revisions only when changed content matters.
5. Use context rules to load extra files only when a trigger fires.
6. Add an `open_questions` entry instead of searching broadly when context is missing and confidence is below the finding threshold.
