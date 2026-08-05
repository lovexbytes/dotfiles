# Context Rules: Web Forms Validation Agent

| Trigger in diff | What to load | Why |
|---|---|---|
| Form state, controller, schema, or validator changed | Fields, error display, and submit handler | Validation must match the view and submit path |
| Asynchronous validation changed | Request owner, cancellation, and submit guard | Stale validation can accept bad data |
| Reset, default, or patch behavior changed | Initial data and rendered field state | View and model can diverge |
| Cross-field rule changed | Every field and the shared error output | The rule cannot be judged from one field |
| Payload mapping changed | Server contract and server validation | Client checks do not replace the trust boundary |
