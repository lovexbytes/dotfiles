# TDD Patterns Reference

Use this after the main skill selects TDD or small table-driven tests.

TDD is the red-green-refactor loop, not a unit-test-only paradigm. Use the smallest real boundary that proves the behavior. For branch behavior or infrastructure, return to the main skill's BDD or integration guidance.

## Table-Driven Tests

- Keep the table declarative. Rows should describe data, not behavior.
- The table answers `what is tested`; the loop answers `how it is executed`.
- Do not put setup closures or imperative callbacks in table rows.
- If a case needs custom sequencing or setup, pull it out into a standalone test or switch to BDD.

### Prefer

```go
type testCase struct {
    name     string
    input    string
    expected string
    wantErr  error
}
```

## Red-Green-Refactor

- Red: write a test that fails for the intended missing behavior, not a setup error.
- Green: make the smallest production change that passes the test.
- Refactor only while the test stays green.

## Determinism

- Use fixed, visible inputs and isolated state the test owns.
- Clean up state explicitly.
- Do not use sleeps or unseeded random data.
- For asynchronous work, use an existing bounded wait or eventually helper. Do not write sleeps or unbounded polling.

## Assertions

- In `testing` and `testify` suites, use `require` for prerequisites that must hold before continuing.
- Use `assert` for follow-up value checks once the test can proceed safely.
- In Ginkgo suites, stay on `Expect` and matchers instead of mixing assertion styles without a clear reason.
