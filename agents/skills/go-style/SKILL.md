---
name: go-style
description: Use when creating, modifying, reviewing, or refactoring Go production code, especially API shape, package boundaries, naming, dependency ownership, error handling, concurrency, generated-code boundaries, or internal S2S HTTP contracts. Prefer repo-local conventions first. Do not use as the primary skill for Go tests, env config structs, sqlc/database work, NATS job workflows, generated files, or command-only tasks.
---

# Go Code Style

## When to Use

Use this skill for Go work when:

- writing or changing production Go code
- reviewing Go code for maintainability or correctness risks
- designing package APIs, constructors, interfaces, dependencies, or error flow
- refactoring Go code without changing behavior
- touching concurrency, ownership boundaries, or internal service-to-service HTTP contracts
- deciding whether an abstraction, fallback, export, or helper belongs in the codebase

Do not use it as the primary guide when a more specific skill owns the task:

- Go tests and test strategy: use `go-tests`
- Go env/config structs: use `go-env-cfg`
- SQL, migrations, sqlc, or DB access: use DB/sqlc skills first
- NATS JetStream job workflows: classify and follow the repository's existing async/job pattern first
- generated files: regenerate from the source instead of styling generated output
- command-only requests: run the command directly

When skills overlap, use the specific skill for the workflow and apply this style guidance only to the hand-written Go code.

## How to Use

1. Inspect nearby code before deciding style.
2. Follow repo-local conventions over generic preference.
3. Keep edits scoped to the behavior or review concern.
4. Prefer readable call sites, explicit ownership, cohesive packages, and small APIs.
5. Add abstractions only when they remove real complexity or match an established local pattern.

## Go MCP Navigation

- For Go symbol/API questions, prefer gopls MCP over text search: `go_workspace` for layout, `go_search` for symbols, `go_symbol_references` for refs/callers, `go_package_api` for package contracts, and `go_file_context` for cross-file dependencies.
- After Go edits, use `go_diagnostics` when available before slower repo-wide checks.
- Use `rg`/file search for non-Go text, docs/config, path discovery, or when gopls is unavailable or empty; mention the fallback if it affects confidence.

## Packages and APIs

- Keep packages focused. Avoid vague package names like `util`, `common`, and `helper`.
- Prefer concrete types. Add small, usually consumer-owned interfaces only for real substitution or protocol boundaries.
- Accept interfaces where useful; return concrete types. Do not use pointers to interfaces.
- Keep dependency interfaces at the package/module boundary. If the package already has `deps.go`, add new dependency interfaces there; when a new package introduces dependency interfaces, create `deps.go` so mock generation has a single source.
- Keep signatures short. Use config or options structs when parameters are numerous, optional, or easy to mix up.
- Put `context.Context` first and do not store it.
- Prefer explicit dependencies over mutable package state. Avoid `init()` for real logic.
- Do not export types only for tests.
- Avoid embedding in exported structs unless promoted members are intentional API.
- Add compile-time interface assertions when interface conformance is part of the contract.

## Names and Data

- Avoid stutter, redundant type words, vague names, and unnecessary aliases.
- Prefer singular names for structs and interfaces that model one concept or protocol. Use plural names only for real collections, batches, or multi-item operations.
- Use nouns for values, verbs for side-effecting functions, and keep variable scope tight.
- Avoid shadowing important values such as `ctx` and `err`.
- Make zero values useful when possible.
- `nil` is a valid slice. Return empty slices only when a contract requires it.
- Copy slices and maps at ownership boundaries.
- Use keyed struct literals except in tiny obvious locals.
- Preallocate only with known size or measured need.
- Use `time.Time` for instants and `time.Duration` for intervals. If an external format forces numbers, include the unit in the field name.

## Errors and Control Flow

- Handle each error once: return, wrap, match, or log and degrade. Do not log and return the same error.
- Wrap errors with short context where the layer knows what failed.
- Prefer early returns over deep nesting and avoid unnecessary `else`.
- Library code should return errors instead of panicking or logging and returning.
- Panic only for programmer misuse, impossible states, or tightly contained internal control flow with a clear recovery boundary.
- Exit once, in `main`.

## Concurrency

- Do not launch goroutines without cancellation, shutdown, or a wait path.
- Use channel direction when it clarifies ownership.
- Buffered channels are usually unbuffered or size 1 unless a larger buffer is justified.
- Prefer `defer` for unlocks and cleanup unless profiling proves otherwise.
- Mutexes are values, not pointers, and should not accidentally become public API.

## Internal S2S HTTP

- Use `servkit` `s2shttp` for internal service-to-service HTTP when there is no gRPC contract yet; treat it as generated RPC-style transport, not ad hoc REST.
- Define or extend the service contract interface in the contract package, usually `Service`, with methods shaped `Method(ctx context.Context, in Input) (Output, error)`.
- Keep `//go:generate s2shttp` or `//go:generate s2shttp <InterfaceName>` next to that interface, regenerate `s2shttp_gen.go`, and never edit generated S2S files by hand.
- Wire servers through the generated `HandleS2SHTTPService` function and callers through `s2shttp.NewClient` plus the generated `NewS2SHTTPClient`.
- Prefer changing the shared contract and regenerating over adding one-off internal HTTP handlers or bespoke clients.

## Comments and Tests

- Document non-obvious behavior: ownership, cancellation, concurrency, side effects, and unusual errors.
- Comments should add meaning, not restate names or types.
- Keep test setup local, mark helpers with `t.Helper()`, and do not call `t.Fatal` or `t.FailNow` from goroutines.
- Prefer real objects and clear behavior over unnecessary test doubles.
- Use keyed table-test cases when cases get tall or fields share types.

## Fallback Discipline

- Prefer explicit invariants over defensive nesting: resolve required context once at entry, then pass it through.
- Do not add downstream fallbacks when an upstream contract guarantees the value exists.
- Keep a fallback only for explicit backward compatibility, documented missing-input paths, or temporary migration windows.
- For every kept fallback, document the trigger and owner layer, then add a targeted reachability test.
- If realistic tests cannot reach a fallback, remove it and fail fast with a clear lowercase error.
- In review-driven refactors, simplify first: remove redundant resolve/check loops before adding abstractions.

## Default Tie-Breakers

- Smaller package.
- Simpler signature.
- Fewer exports.
- Concrete type over premature interface.
- Explicit ownership over hidden sharing.
- Readable name over descriptive redundancy.
