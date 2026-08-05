# Context Rules: Distributed Operations Agent

| Trigger in diff | What to load | How | Why |
|---|---|---|---|
| New or changed side-effecting handler, consumer, worker, or scheduled job | Idempotency extraction, dedup storage, retry helper, publisher or consumer pair | Use File Access instructions from your prompt | Verify retries and replay converge to one logical effect |
| New retry, backoff, timeout, circuit-breaker, or fallback logic | Dependency client, caller chain, timeout budget source, side-effect site | Use File Access instructions from your prompt | Verify timeout and retry behavior stay within caller intent |
| Changed publisher, consumer, ack, nack, or DLQ logic | Topic or subject definitions, producer and consumer pair, redelivery behavior, durable handoff tables | Use File Access instructions from your prompt | Verify crash and replay safety |
| Changed worker, queue, or deployment settings | Drain or shutdown behavior, concurrency limits, termination settings, rollout strategy | Use File Access instructions from your prompt | Verify degraded dependency and redelivery safety |
| Changed non-Go artifacts tied to distributed behavior | Related Go producer and consumer code, plus the artifact diff | Use File Access instructions from your prompt | Verify the artifact change preserves distributed invariants |
