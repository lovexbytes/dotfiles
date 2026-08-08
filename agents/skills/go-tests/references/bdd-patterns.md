# BDD Patterns

Use this for workflows that are clearer as a branch tree than as a table.

## Rules

- Apply the Principle of Least Astonishment (POLA). A reader must understand a scenario, each step, its visible data, and its expected outcome without reading step definitions, fixtures, or helper code.
- One scenario proves one behavior contract.
- Put a failure path before the success path when it makes the behavior clearer.
- Nest sequential branches. A child branch runs only after its parent prerequisite succeeds.
- Use parent/shared setup only for technical lifecycle and other non-causal setup. Keep business prerequisites and causal values visible in the scenario or narrow behavior branch that uses them. Keep child setup narrow.
- Give every edge-case state an explicit step that says what the state is. Do not make an empty table, an omitted row, a sentinel value, or hidden step behavior mean a separate business case. Use a step such as `Given sender 7 owns transfer 12 with no recipients`.
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
- Empty or special-case tables that require the reader to inspect a step definition to know their meaning.
- Several behavior contracts in one scenario.
- BDD for trivial pure helpers that are clearer as small table tests.
