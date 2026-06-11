---
name: write-adr
description: Use when the user explicitly asks to write, draft, create, update, or produce an Architecture Decision Record (ADR), formal decision document, or decision record.
---

# Write ADR

Generate a production-ready ADR using current conversation context plus the user's prompt.

## When to Use

Use this skill when:

- the user asks for an ADR (Architecture Decision Record)
- the user wants a formal decision document with clear sections
- decision rationale and consequences must be documented for future review

Do not use this skill for low-level implementation notes or casual architecture chat.

## Workflow

1. Build draft from existing session context first.
2. Fill sections with concrete, decision-specific content.
3. Mark assumptions explicitly when data is missing.
4. Decide whether a diagram belongs in the ADR and use `mermaid-diagrams` when it does.

## Output Structure

Use these headings in this exact order:

1. `Context and Problem Statement`
2. `Decision Drivers`
3. `Considered Options`
4. `Pros and Cons of the Options`
5. `Decision Outcome`
6. `Positive Consequences`
7. `Negative Consequences`

## Formatting Rules

- Keep section headers in English exactly as defined.
- Write ADR documents in English only.
- Use concise, factual statements.
- Avoid marketing wording.
- Prefer explicit trade-offs and operational implications.

## Diagram

Add a diagram section when:

- the user explicitly asks for a diagram, call flow, sequence, topology, component map, or visual flow
- you think a focused diagram will materially clarify the ADR decision, boundary, actors, data flow, control flow, or operational consequence

When adding a diagram:

1. Use `mermaid-diagrams` for Mermaid syntax guidance.
2. Add a section named exactly `Diagram`.
3. Choose the smallest useful diagram type, usually sequence, flowchart, C4, or ERD.
4. Keep actor names concrete, such as API, Service, Queue, Worker, Provider, or DB.
5. Keep it focused on the decision, not the whole system.

## Quality Checklist

Before final output, verify:

- headings match the output structure exactly
- decision rationale is explicit
- at least 3 positive and 3 negative consequences (when context allows)
- no contradictory statements between outcome and consequences
- any included diagram is focused, valid Mermaid, and tied to the decision

## Common Mistakes

- Omitting required ADR sections
- Generic consequences not tied to the selected decision
- Missing explicit trade-off explanation in `Decision Outcome`
