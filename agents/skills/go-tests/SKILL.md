---
name: go-tests
description: Use when creating, modifying, reviewing, debugging, or choosing strategy for Go tests, including table tests, BDD suites, integration tests, fixtures, and test command selection. Also use when a Go behavior change needs corresponding test coverage. Do not use for non-Go tests or unrelated Go code style work.
---

# Go Test Strategy

## When to Use

Use this skill for Go work when:

- adding, updating, refactoring, or reviewing tests
- fixing failing or flaky Go tests
- deciding what test coverage a Go behavior change needs
- selecting a test structure and real boundary
- selecting the targeted or repo-level Go test command to run

Do not use it for non-Go tests. If the user only asks to run an existing test command, run it directly; apply this guidance only if the result needs interpretation or test code changes.

## First Pass

1. Inspect nearby tests before choosing a style.
2. Identify the real boundary under test: pure function, use case with collaborators, repository/storage, HTTP/API, worker/job, or external integration.
3. Follow the repository's existing framework and helpers unless there is a strong reason not to.
4. Select a structure and the smallest real boundary that proves the behavior.

## Go MCP Navigation

- Use gopls MCP for semantic lookup before broad text search: `go_search` for changed symbols, `go_symbol_references` for callers and test call sites, `go_package_api` for package contracts, and `go_file_context` for dependencies around the file under test.
- Use `rg` for `_test.go` path discovery, table names, fixture strings, non-Go files, or when gopls is unavailable/empty.
- After modifying Go tests or tested code, run `go_diagnostics` when available, then the targeted test command.

## Choose Test Structure and Boundary

- Select a structure: small table tests for data-driven behavior; BDD for branches, retries, callbacks, ordered effects, or error paths; a focused regression test for a prior failure.
- Select the smallest real boundary: a pure function, controlled time or an existing repository time helper, or the repository DB, HTTP, queue, filesystem, or service harness.
- BDD can use real infrastructure. Structure and boundary are independent.

Load [references/tdd-patterns.md](references/tdd-patterns.md) when writing small table tests or doing a tight red-green-refactor loop.

Load [references/bdd-patterns.md](references/bdd-patterns.md) when testing branching flows, dependency-heavy use cases, or BDD suites.

## Test Design Rules

- Apply the Principle of Least Astonishment (POLA). A reader must understand the test name, inputs, setup, action, and expected outcome at a high level without reading helpers, fixtures, or test implementation.
- Keep table rows declarative and data-only.
- Do not put setup closures or imperative behavior into table cases.
- If one table case needs custom sequencing or setup, make it a standalone test or switch to BDD.
- In BDD suites, model the behavior path: parent/shared setup is only for technical lifecycle and other non-causal setup; keep business prerequisites and causal values visible in the scenario or narrow behavior branch that uses them. Child `When` branches add the next failure or success branch and keep setup narrow.
- Give each BDD edge case an explicit step with its business meaning. Do not use empty tables, omitted rows, sentinel values, or hidden step behavior to mean a distinct state. For example, use `Given sender 7 owns transfer 12 with no recipients` instead of a recipients-table step with no rows.
- Prefer visible outcomes, durable effects, and exact causal keys when they are part of the contract.
- Use real boundaries through existing repository harnesses. Do not add test-only interfaces or seams only to support substitution.
- Use the repo's assertion style: `Expect` in Ginkgo, `require` for prerequisites in `testing`/`testify`, and `assert` for follow-up checks.
- In Ginkgo/Gomega suites, use `BeforeEach`/`When`/`It`; do not use `Context` blocks.
- Use `JustBeforeEach` only when invocation or setup must happen after nested `BeforeEach` adjustments.
- Prefer full-struct `Equal` assertions over field-by-field checks when the whole result is the behavior.
- When expecting an error, assert the observable error and any durable state the contract defines. Do not check partial outputs unless the contract defines them.
- Use fixed, visible data. Override only fields needed to drive the path.

## Verification

- Run targeted tests for the package or behavior while iterating.
- For broad behavior changes, shared helpers, or before claiming a branch is ready, run the repo-level Go test target when available, usually `make test`.
- If no suitable Make target exists, use explicit `go test` commands for the touched packages.
- Report exactly which test commands ran and any skipped verification.

## Avoid

- Adding a new test framework when the repo already has a clear local pattern.
- Turning branch-heavy behavior into giant tables with hidden setup.
- Replacing a real boundary that the repository already tests with an integration harness.
- Repeating full happy-path setup in every branch when nesting would make the flow clearer.
