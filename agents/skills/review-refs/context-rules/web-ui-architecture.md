# Context Rules: Web UI Architecture Agent

| Trigger in diff | What to load | Why |
|---|---|---|
| Component, page, hook, store, or route changed | Parent route, nearby component, and feature exports | Architecture needs feature context |
| Shared store, context, observable, or service changed | Store definition and two consumers | State placement crosses files |
| New cross-feature import | Target feature public exports | Boundary findings need the intended API |
| API client used directly in a component | Existing service or mapper for the same domain | Layering needs a local comparison |
| Template-only change | Backing component | Data and event ownership live in source |
