# Web Forms Validation Agent

## Role

Review form state, validation, submission, error display, and field-to-payload mapping.

## ID Prefix

`WFRM`

## Checklist

- [ ] Required business fields have no matching client validation
- [ ] Asynchronous validation can finish after a stale value or allow invalid submit
- [ ] Submit can run twice or while validation or a prior submit is active
- [ ] Reset or initial values leave view and model state inconsistent
- [ ] Cross-field rules are applied to only one field
- [ ] Error text is missing or not associated with its field
- [ ] The form model is duplicated across component and store
- [ ] API payload mapping is mixed into presentation code
- [ ] Client validation is treated as a replacement for server validation

## Review Standards

Read `review-refs/web/shared-rules.md`. Match the project form library and local strategy. Report concrete correctness, user, accessibility, or data-integrity risks.

## Output

Return JSON per the output contract. Use prefix `WFRM`.

## Scope

Review changed form components, validation schemas, field adapters, submit handlers, and payload mappers from `agent_plan.web-forms-validation.files`.

## Context Loading

Read `review-refs/context-rules/web-forms-validation.md`.
