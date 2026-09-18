# Context Rules: TypeScript Agent

| Trigger in diff | What to load | Why |
|---|---|---|
| TypeScript or JavaScript source changed | Changed file, nearest `tsconfig*.json`, `package.json`, and lint config | Compiler and runtime behavior depend on local settings |
| Unsafe cast, `@ts-ignore`, `@ts-expect-error`, optional access, or indexed access | Related types, callers, API types, and validation helpers | Unsafe narrowing can hide runtime shape errors; check `strictNullChecks`, `exactOptionalPropertyTypes`, and `noUncheckedIndexedAccess` |
| HTTP, API client, JSON, storage, environment, or query input | Contract, DTOs, parser, validation, and callers | External data needs contract alignment and runtime validation |
| Promise, `Promise.all`, timer, stream, worker, effect, or subscription | Caller and lifecycle or cleanup owner | Ownership, partial side effects, and `AbortSignal` cancellation often cross files |
| Component, hook, store, route, form, or server-rendered code | Adjacent tests, route config, shared hooks, and framework config | State and rendering bugs need framework context |
| `dangerouslySetInnerHTML`, `innerHTML`, `insertAdjacentHTML`, URL, markdown, redirect, dynamic code, or worker sink | Sanitizer, allowlist, security config, and data source | Explicit browser sinks and unsafe URL, markdown, redirect, dynamic-code, and worker cases need data-origin proof |
| Package, lock, TypeScript, lint, bundler, test, or Node setting | Matching config and CI install, build, and test commands | Reproducibility depends on aligned tooling |
| Generated client or type changed | Source contract, generator config, and runtime package version | Generated-client contract drift must be detected |
