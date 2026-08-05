# Context Rules: TypeScript Agent

| Trigger in diff | What to load | Why |
|---|---|---|
| TypeScript or JavaScript source changed | Changed file, nearest `tsconfig*.json`, `package.json`, and lint config | Compiler and runtime behavior depend on local settings |
| Unsafe cast, ignore, optional access, or indexed access | Related types, callers, API types, and validation helpers | Unsafe narrowing can hide runtime shape errors |
| HTTP, API client, JSON, storage, environment, or query input | Contract, DTOs, parser, validation, and callers | External data needs contract alignment and runtime validation |
| Promise, timer, stream, worker, effect, or subscription | Caller and lifecycle or cleanup owner | Ownership and cancellation often cross files |
| Component, hook, store, route, form, or server-rendered code | Adjacent tests, route config, shared hooks, and framework config | State and rendering bugs need framework context |
| HTML, URL, markdown, redirect, dynamic code, or worker sink | Sanitizer, allowlist, security config, and data source | Browser sinks need data-origin proof |
| Package, lock, TypeScript, lint, bundler, test, or Node setting | Matching config and CI install, build, and test commands | Reproducibility depends on aligned tooling |
| Generated client or type changed | Source contract, generator config, and runtime package version | Generated output must match its source and runtime |
