# Context Rules: Domain Invariants Agent

| Trigger in diff | What to load | How | Why |
|---|---|---|---|
| Money, fee, balance, ledger, hold, settlement, refund, reversal, chargeback changed | Domain service + repository writes + related tests/specs | Search domain terms, then use File Access instructions | Verify balance/currency/fee invariants |
| Account, card, user, KYC, risk, compliance, limit status changed | State enum definitions + transition guards + callers | Use File Access instructions from your prompt | Verify required business guards still precede side effects |
| Operation state enum or transition changed | Every switch/transition handler + persistence mapping + tests | Search enum/state values, then use File Access instructions | Verify impossible states and terminal states are prevented |
| Domain event, audit, outbox, or reconciliation signal changed | Producer + consumer/reconciliation path + committed state write | Use File Access instructions from your prompt | Event/audit must match source-of-truth state |
| Idempotency or retry path touches money/state | Existing idempotency key/dedup store + service method | Use File Access instructions from your prompt | Duplicate request must converge to same business outcome |
| Request/DB/event DTO for domain object changed | Mapping chain handler -> service -> repository -> event | Use File Access instructions from your prompt | Verify domain fields are not dropped or defaulted |
