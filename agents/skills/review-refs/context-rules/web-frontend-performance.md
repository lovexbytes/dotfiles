# Context Rules: Web Frontend Performance Agent

| Trigger in diff | What to load | Why |
|---|---|---|
| Large list or repeated component changed | Key strategy, data source, and paging | Rendering cost depends on list ownership |
| Effect, memo, selector, or subscription changed | Dependencies, cleanup, and callers | Repeated work and leaks often cross files |
| Route import or lazy boundary changed | Route configuration and target module | Initial bundle impact needs the boundary |
| New package import changed | `package.json`, lockfile, and bundler config | Bundle claims need package context |
| Server-rendered or hydrated component changed | Server entry, client boundary, and initial data | Hydration needs equal server and client output |
| Image, font, or layout style changed | Rendered dimensions and loading path | Layout shift and delivery cost need asset context |
