# TDD Patterns Reference

Use this after the main skill has already selected lightweight TDD or small table-driven tests.

Use it for helpers, mappers, parsers, validators, and other deterministic code without collaborator orchestration. If the test starts needing mock sequencing, nested branch setup, or real infra behavior, switch back to the main skill's BDD or integration guidance.

## Table-Driven Tests

- Keep the table declarative. Rows should describe data, not behavior.
- The table answers `what is tested`; the loop answers `how it is executed`.
- Do not put `setupMock func(...)`, closures, or imperative callbacks in table rows.
- If a case needs custom sequencing or collaborator setup, pull it out into a standalone test or switch to BDD.

### Avoid

```go
type testCase struct {
    name      string
    setupMock func(m *MockService)
}
```

### Prefer

```go
type testCase struct {
    name     string
    input    string
    expected string
    wantErr  error
}
```

## TDD Scope

- Use TDD for code that is easy to exercise in-process without collaborator orchestration.
- Keep the red-green-refactor loop small and cheap.
- Do not force TDD onto dependency-heavy control flow that is clearer as BDD.

## Assertions

- In `testing` and `testify` suites, use `require` for prerequisites that must hold before continuing.
- Use `assert` for follow-up value checks once the test can proceed safely.
- In Ginkgo suites, stay on `Expect` and matchers instead of mixing assertion styles without a clear reason.
