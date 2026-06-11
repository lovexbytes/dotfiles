---
name: go-tests
description: Use when creating, modifying, reviewing, debugging, or choosing strategy for Go tests, including unit tests, integration tests, Ginkgo/Gomega suites, gomock expectations, generated mocks, fixtures, and test command selection. Also use when a Go behavior change needs corresponding test coverage. Do not use for non-Go tests or unrelated Go code style work.
---

# Go Test Strategy

## When to Use

Use this skill for Go work when:

- adding, updating, refactoring, or reviewing tests
- fixing failing or flaky Go tests
- deciding what test coverage a Go behavior change needs
- changing interfaces or dependencies that affect generated mocks
- choosing between table tests, BDD-style collaborator tests, or integration tests
- selecting the targeted or repo-level Go test command to run

Do not use it for non-Go tests. If the user only asks to run an existing test command, run it directly; apply this guidance only if the result needs interpretation or test code changes.

## First Pass

1. Inspect nearby tests before choosing a style.
2. Identify the real boundary under test: pure function, use case with collaborators, repository/storage, HTTP/API, worker/job, or external integration.
3. Follow the repository's existing framework and helpers unless there is a strong reason not to.
4. Pick the smallest test shape that proves the behavior without hiding important setup.

## Go MCP Navigation

- Use gopls MCP for semantic lookup before broad text search: `go_search` for changed symbols, `go_symbol_references` for callers and test call sites, `go_package_api` for package contracts, and `go_file_context` for dependencies around the file under test.
- Use `rg` for `_test.go` path discovery, table names, fixture strings, non-Go files, or when gopls is unavailable/empty.
- After modifying Go tests or tested code, run `go_diagnostics` when available, then the targeted test command.

## Choose the Test Shape

- `Small table tests`: pure helpers, mappers, parsers, validators, simple policy functions, and deterministic code without collaborator orchestration.
- `BDD + gomock`: business logic with dependencies, branching, retries, callbacks, ordered side effects, or error paths that are clearer as nested behavior.
- `Integration tests`: real DB, HTTP, queue, filesystem, or other infrastructure boundaries. Reuse the repo harness instead of mocking through the boundary.
- `Regression test`: bugs and behavior changes where the old failure can be expressed cheaply. Prefer a focused failing test before changing implementation when practical.

Load [references/tdd-patterns.md](references/tdd-patterns.md) when writing small table tests or doing a tight red-green-refactor loop.

Load [references/bdd-gomock.md](references/bdd-gomock.md) when testing branching flows, dependency-heavy use cases, gomock expectations, or Ginkgo/Gomega suites.

## Test Design Rules

- Keep table rows declarative and data-only.
- Do not put `setupMock func(...)`, closures, or imperative behavior into table cases.
- If one table case needs custom mock sequencing, make it a standalone test or switch to BDD.
- In BDD suites, model the behavior path: parent setup establishes successful prerequisites, child `When` branches add the next failure or success branch.
- Prefer visible behavior assertions over overspecified mock arguments.
- Use exact mock argument matching only when the dependency contract is the behavior being tested.
- Use the repo's assertion style: `Expect` in Ginkgo, `require` for prerequisites in `testing`/`testify`, and `assert` for follow-up checks.
- In Ginkgo/Gomega suites, use `BeforeEach`/`When`/`It`; do not use `Context` blocks.
- Use `JustBeforeEach` only when invocation or mock setup must happen after nested `BeforeEach` adjustments.
- Prefer full-struct `Equal` assertions over field-by-field checks when the whole result is the behavior.
- When expecting an error, assert the error outcome without also checking partially populated outputs unless that is part of the contract.
- Use repo faker helpers when present; generate data in the narrowest scope and override only fields needed to drive the path.

## Mocks and Generated Files

- Prefer the repo's existing gomock generation flow and mock locations.
- If a mocked interface changes, or a new dependency interface is added, regenerate mocks before finishing.
- If the package uses `//go:generate mockgen ...`, run `go generate` for that package unless the repo has a higher-level generation target.
- Do not hand-edit generated mock files.

## Verification

- Run targeted tests for the package or behavior while iterating.
- For broad behavior changes, shared helpers, or before claiming a branch is ready, run the repo-level Go test target when available, usually `make test`.
- If no suitable Make target exists, use explicit `go test` commands for the touched packages.
- Report exactly which test commands ran and any skipped verification.

## Avoid

- Adding a new test framework when the repo already has a clear local pattern.
- Forcing TDD onto dependency-heavy orchestration that is clearer as BDD.
- Turning branch-heavy behavior into giant tables with hidden setup.
- Mocking through a real boundary that the repo already tests with integration harnesses.
- Repeating full happy-path mock setup in every branch when nesting would make the flow clearer.
