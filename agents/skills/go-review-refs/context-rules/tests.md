# Context Rules: Tests Agent

Before analyzing diffs, read this table. When you see a trigger pattern in the diff, load the additional context described.

| Trigger in diff | What to load | How | Why |
|---|---|---|---|
| Changed function in `internal/` or `pkg/` | Corresponding `*_test.go` file in the same package | Use File Access instructions from your prompt | Verify tests exist and match new behavior |
| New or modified error return | Test file + grep for function name in `*_test.go` files | Search repo for function name in test files, then use File Access instructions | Check if error path is tested |
| New `go` keyword or goroutine | Test file for the package | Use File Access instructions from your prompt | Check for concurrent/race test coverage |
| New `tx.Begin` or transaction code | Test file for the package | Use File Access instructions from your prompt | Check for rollback/failure path tests |
| Changed function signature (new param, changed return) | All `*_test.go` files calling that function | Search repo for function name in test files, then use File Access instructions | Verify test call sites match new signature |
| New HTTP handler or route change | Handler test file (`*_test.go` in same package) | Use File Access instructions from your prompt | Check for request/response test coverage |
| Modified struct used in tests | Test files using that struct | Search repo for struct name in test files, then use File Access instructions | Test data may use outdated field values |
| `*_test.go` file in diff with changed assertions | Implementation file being tested | Use File Access instructions from your prompt | Verify assertions match actual implementation behavior |
| New or changed `go` / channel / mutex / `sync.Once` / `sync/atomic` in non-test code | Repo's CI configuration, `Makefile`, test scripts | Search for `go test -race`, `-race`, `race:` in `Makefile`, `.gitlab-ci.yml`, `Taskfile`, etc., then use File Access instructions | Confirm race-enabled runs cover the affected package; if not, raise a `requires_verification: true` finding |
| New state added to persistent state machine, new idempotency/dedup key, new message/replay semantics | Existing integration spec directory (search `*_integration_test.go`, `suite_test.go`, Ginkgo suite `BeforeSuite` spinning up DB/Redis/NATS) | Use File Access instructions from your prompt | Recommend integration validation for multi-step transitions; ordering regressions escape unit tests |
| Change in ordering/commit/ack timing (outbox flush, commit-before-publish, ack-before-handle) | Test files around the affected subject/table/consumer | Search for subject/table names in `*_test.go`, then use File Access instructions | Pin observable side-effect order in tests to prevent regressions |
