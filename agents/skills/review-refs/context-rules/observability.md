# Context Rules: Observability Agent

Before analyzing diffs, read this table. When you see a trigger pattern in the diff, load the additional context described.

| Trigger in diff | What to load | How | Why |
|---|---|---|---|
| New error-returning function or new branch returning an error | Project's metrics registry (e.g. `metrics.go`, `prometheus.go`) + the error's callers | Use File Access instructions from your prompt | Verify failure is counted/histogrammed at one of the callers |
| Unique constraint (`23505`) caught / `ON CONFLICT DO NOTHING` / upsert returning existing row | Full function + all metric/log calls on that path | Use File Access instructions from your prompt | Verify metric increments and `defer dec(...)` are gated behind "new state actually applied" |
| New `metric.Inc`/`Add`/`Observe` or equivalent | Metric definition (labels, buckets) + call sites with same metric name | Search repo for the metric name, then use File Access instructions | Check label cardinality and symmetric inc/dec for gauges |
| New log call (`logger.Info/Warn/Error`) | Full function + request/correlation ID propagation in the handler chain | Use File Access instructions from your prompt | Verify structured fields, level appropriateness, no PII |
| Struct field holding email/phone/pan/iban/token/secret/password/authorization/cookie | All places that serialize the struct to logs, metric labels, span attributes, error messages, cache keys | Search repo for the field name, then use File Access instructions | Confirm redaction at every telemetry surface |
| New outbound HTTP/gRPC/DB/cache/queue call | Function signature + caller's `context.Context` wiring | Use File Access instructions from your prompt | Verify ctx propagation; verify latency histogram exists |
| `go func(...)` or new goroutine | Full function + the logger/tracer wiring used in caller | Use File Access instructions from your prompt | Verify request_id / trace context carried across the goroutine boundary |
| New retry loop (`for attempt := range ...`, `retry.Do`, `backoff.Retry`) | Full function + metrics registry | Use File Access instructions from your prompt | Verify retry count and exhausted/success metrics |
| New consumer / subscriber (`Subscribe`, `Consume`, `PullMessages`) | Producer side of the same subject/topic + tracing middleware | Search repo for subject constant, then use File Access instructions | Verify trace context continuation from producer |
| Changed `readinessProbe`, `livenessProbe`, `resources`, `strategy`, `terminationGracePeriodSeconds`, `preStop` in K8s manifest | Previous revision of the manifest + the service's startup code | Use File Access instructions from your prompt; check git history if available | Verify rollout/drain/SIGKILL safety |
| Changed CPU/memory `requests` or `limits` | Previous manifest revision + the service's known steady-state usage (from runbook/doc if present) | Use File Access instructions from your prompt | Throttle / OOMKilled risk |
