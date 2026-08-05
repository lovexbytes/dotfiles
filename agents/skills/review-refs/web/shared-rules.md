# Shared Web Review Rules

## Scope

Start with the files in `agent_plan.<agent>.files` from `review-context.json`. Review changed lines and directly affected context only.

Load cross-file context only when it is needed to prove a finding. Examples include a store-to-component flow, a route boundary, a form owner, or an API mapping.

## Repository Conventions

Before you cite a convention:

1. Inspect two or three nearby components, hooks, stores, or services.
2. Prefer the clearer local example when old and new patterns differ.
3. Do not accept a weak change only because old code has the same problem.

Ignore formatting and naming issues that lint or format tools already enforce.

## Finding Contract

Each finding must cover one independently fixable mechanism. Include the affected construct, root cause, concrete proof, user or production impact, and the minimum fix direction.

Use `open_questions` when a cross-file path is incomplete. Use `requires_verification: true` when a browser, accessibility tool, bundle report, or build is needed.

## Do Not Report

- Pure formatting or naming preferences.
- Broad refactors outside the changed scope.
- Old issues that the change does not extend or expose.
- Framework preferences without a concrete correctness, performance, accessibility, or maintenance risk.
- A coverage gap that belongs only to the tests agent.
