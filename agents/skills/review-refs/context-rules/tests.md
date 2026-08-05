# Context Rules: Tests Agent

Before analyzing diffs, read this table. When you see a trigger pattern in the diff, load the additional context described.

| Trigger in diff | What to load | How | Why |
|---|---|---|---|
| Changed Go function in `internal/` or `pkg/` | Corresponding `*_test.go` file in the same package | Use File Access instructions from your prompt | Verify tests exist and match new behavior |
| Changed TypeScript or JavaScript function, component, hook, or route | Nearby `*.test.*`, `*.spec.*`, component test, and browser test | Search by exported name, route, or visible text | Verify tests match visible behavior and contracts |
| New or modified error return or rejected promise | Matching test files | Search for the function or component name in tests | Check if the error path is tested |
| New `go` keyword or goroutine | Test file for the package | Use File Access instructions from your prompt | Check for concurrent/race test coverage |
| New `tx.Begin` or transaction code | Test file for the package | Use File Access instructions from your prompt | Check for rollback/failure path tests |
| Changed function signature, props, or API type | Test files that call or render it | Search test files for the changed symbol | Verify test call sites match the new contract |
| New HTTP handler or route change | Handler, route, or browser tests | Use File Access instructions from your prompt | Check request and response behavior |
| Modified struct used in tests | Test files using that struct | Search repo for struct name in test files, then use File Access instructions | Test data may use outdated field values |
| Test file in diff with changed assertions | Implementation file being tested | Use File Access instructions from your prompt | Verify assertions match actual implementation behavior |
| New or changed `go` / channel / mutex / `sync.Once` / `sync/atomic` in non-test code | Repo's CI configuration, `Makefile`, test scripts | Search for `go test -race`, `-race`, or `race:` in build and CI files | Confirm race-enabled runs cover the affected package; if not, raise a `requires_verification: true` finding |
| New state added to persistent state machine, new idempotency/dedup key, new message/replay semantics | Existing integration spec directory (search `*_integration_test.go`, `suite_test.go`, Ginkgo suite `BeforeSuite` spinning up DB/Redis/NATS) | Use File Access instructions from your prompt | Recommend integration validation for multi-step transitions; ordering regressions escape unit tests |
| Change in ordering/commit/ack timing (outbox flush, commit-before-publish, ack-before-handle) | Test files around the affected subject/table/consumer | Search for subject/table names in `*_test.go`, then use File Access instructions | Pin observable side-effect order in tests to prevent regressions |
