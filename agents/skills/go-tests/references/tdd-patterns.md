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

## Synthetic Test Data

- Use fixed, visible, clearly synthetic data when the exact production identity is not the contract.
- Do not copy real deployment identity into tests. This includes account IDs, tenant IDs, environment names, topic or queue names, ARNs, email domains, hostnames, and URLs.
- First decide if the exact value matters, or if only its format and internal consistency matter. If only format matters, use a synthetic value with the required structure.
- Preserve protocol parts that are the contract. For host validation, keep the AWS SNS host and matching region, but use a synthetic account ID, topic name, and URL path: `arn:aws:sns:us-west-1:000000000000:test-topic` and `https://sns.us-west-1.amazonaws.com/test-certificate.pem`.
- Prefer reserved test domains such as `example.com` and clear labels such as `test-topic`, `test-tenant`, and `test-configuration-set`.
- Do not load production configuration only to avoid a test literal. This creates environment coupling and can let input and expectation change together.
- Reuse or derive named production-owned policy values such as limits and timeouts, as the main skill requires. Synthetic identity data does not replace production policy boundaries.
- Use an exact production literal only when that literal is the contract.

## Assertions

- In `testing` and `testify` suites, use `require` for prerequisites that must hold before continuing.
- Use `assert` for follow-up value checks once the test can proceed safely.
- In Ginkgo suites, stay on `Expect` and matchers instead of mixing assertion styles without a clear reason.
