# Backend TypeScript / JavaScript (Node, Nest)

Load this file when a generic backend agent receives `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, or `.cjs` plan files.

**Hard rules:**
- Do not demand Go idioms. Repository Node and framework conventions win.
- Type-only issues belong to the `typescript` agent.
- Skip `node_modules/`, `dist/`, `coverage/`, `*.generated.ts`, and `*.gen.ts`.

Apply only the section that matches the agent name.

## correctness
- Check rejected promises, double responses, unclosed resources, boundary nullability, non-exhaustive status handling, swallowed errors, and in-memory races.

## concurrency
- Check shared mutable state, non-atomic `Promise.all` mutations, missing `AbortSignal`, overlapping aggregate work, and request-scoped timers.

## conventions
- Check transport and persistence boundary leaks, circular modules, implicit `any` at public service boundaries, and incorrect HTTP error mapping.

## style
- Report only catch-all backend helpers or god-modules that mix HTTP, SQL, and queues. Do not report formatting or TypeScript taste.

## performance
- Check N+1 calls, unbounded lists, large payload reads, chatty sequential calls, and missing indexes for new high-cardinality filters.

## security
- Check injection, command execution, missing authorization, IDOR, secret or PII logging, JWT verification, path traversal, and unsafe credentialed CORS.

## observability
- Check failure logging or metrics for side effects, sensitive logs, lost error causes, false success metrics, and missing request or trace context.

## sql-data-access
- Check deterministic pagination, fragile `SELECT *` or graph loads, nullable mapping, empty `IN` semantics, indexes, transaction boundaries, and generated-client source drift.

## consistency
- Check public DTO and event changes, provider tokens, interfaces, and in-repository consumers.

## transactions
- Check multi-write atomicity or compensation, rollback on rejected transactions, cache ordering, and idempotency constraints.

## compatibility
- Check public field changes, migration rollout safety, mixed-version event or queue changes, and changed production defaults.

## distributed-operations
- Check idempotency, durable writes before acknowledgement, retry safety, timeout propagation, and partial success recovery.

## domain-invariants
- Check money and currency math, validation before side effects, allow-listed state transitions, and stable idempotent retries.
