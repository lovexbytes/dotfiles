# BDD Patterns

Use this for workflows that are clearer as a branch tree than as a table.

## Rules

- One scenario proves one behavior contract.
- Put a failure path before the success path when it makes the behavior clearer.
- Nest sequential branches. A child branch runs only after its parent prerequisite succeeds.
- Use parent/shared setup only for technical lifecycle and other non-causal setup. Keep business prerequisites and causal values visible in the scenario or narrow behavior branch that uses them. Keep child setup narrow.
- Assert visible outcomes and durable effects. Assert exact causal keys when they are part of the contract.
- Use repository real infrastructure helpers when the workflow crosses a real boundary.
- Use fixed, visible data and isolated state the test owns. Clean up explicitly.
- Do not use sleeps. For asynchronous outcomes, use an existing bounded wait or eventually helper.
- Internal call order is not an outcome unless the contract exposes it.
- If the repository uses a BDD framework, follow its local setup and assertion conventions.

## Avoid

- Sibling branches for sequential steps.
- Repeating full successful setup in every branch.
- Hiding setup in closures, helper callbacks, or table rows.
- Several behavior contracts in one scenario.
- BDD for trivial pure helpers that are clearer as small table tests.
