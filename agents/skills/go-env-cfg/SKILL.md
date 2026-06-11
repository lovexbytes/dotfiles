---
name: go-env-cfg
description: Use when creating, editing, or reviewing Go config structs that load environment variables via servkit config.Loader, mapstructure tags, or viper. Trigger words - config.go, mapstructure, env config, environment variables in Go structs, config prefix mismatch, nested config struct.
---

# Go Env Config

## Overview

In repositories that use servkit `config.Loader`, viper, or mapstructure, the env var name is often **derived from struct nesting + mapstructure tags**. Getting the nesting wrong = wrong env var name = silent empty values in prod.

## Go MCP Navigation

- Use gopls MCP for Go symbol lookup: `go_search` for config types/loaders, `go_symbol_references` for readers and parse call sites, `go_package_api` for package contracts, and `go_file_context` for cross-file config dependencies.
- Use `rg` for exact env var strings, docs, deployment config, and other non-Go text, or when gopls is unavailable/empty.

## How Env Names Are Built

`registerEnvs` walks the struct recursively:

```
envKey = UPPER( join(all_ancestor_tags + field_tag, "_") )
```

| Struct shape | mapstructure tags | Resulting env var |
|---|---|---|
| `Config.Field` | `"SOME_KEY"` | `SOME_KEY` |
| `Config.Limits.MinAmount` | `"LIMITS"` + `"MIN_AMOUNT"` | `LIMITS_MIN_AMOUNT` |
| `Config.Env.LimitsMinAmount` | `"ENV"` + `"LIMITS_MIN_AMOUNT"` | `ENV_LIMITS_MIN_AMOUNT` |

**Key rule:** every ancestor struct's `mapstructure` tag becomes a prefix segment.

## Leaf vs Nested Detection

`registerEnvs` recurses into struct fields UNLESS the type is a "leaf":
- Implements `config.Unmarshaler` (`UnmarshalConfig(string) error`)
- Implements `encoding.TextUnmarshaler` (`UnmarshalText([]byte) error`)

Leaf types (NOT recursed into): `decimal.Decimal`, `time.Duration`, `config.Duration`, `config.JSON[T]`, `url.URL`, any custom `UnmarshalConfig` type.

Regular structs without these interfaces ARE recursed into and become prefix segments.

## Patterns

### Single field needing a specific env var — use flat field

**Problem:** need env `EXCHANGE_MIN_AMOUNT` but don't want an `Exchange` wrapper struct for one field.

```go
// DO: flat field at root level
type Config struct {
    ExchangeMinAmount decimal.Decimal `mapstructure:"EXCHANGE_MIN_AMOUNT" default:"50"`
}
// env: EXCHANGE_MIN_AMOUNT  ✓
```

```go
// DON'T: nested struct adds unwanted prefix
type Config struct {
    Env Env `mapstructure:"ENV"`  // prefix "ENV"
}
type Env struct {
    ExchangeMinAmount string `mapstructure:"EXCHANGE_MIN_AMOUNT"`
}
// env: ENV_EXCHANGE_MIN_AMOUNT  ✗
```

### Multiple fields sharing a prefix — use nested struct

When 2+ fields share a logical prefix, a nested struct is correct:

```go
type Limits struct {
    MinAmount    decimal.Decimal `mapstructure:"MIN_AMOUNT" default:"50"`
    MaxAmount    decimal.Decimal `mapstructure:"MAX_AMOUNT" default:"100000"`
    FeePercent   decimal.Decimal `mapstructure:"FEE_PERCENT" default:"0.5"`
}
type Config struct {
    Limits Limits `mapstructure:"LIMITS"`
}
// envs: LIMITS_MIN_AMOUNT, LIMITS_MAX_AMOUNT, LIMITS_FEE_PERCENT
```

### Default values

Use `default` tag. Works with all leaf types:

```go
Field    string          `mapstructure:"FIELD" default:"hello"`
Duration time.Duration   `mapstructure:"DUR" default:"10m"`
Amount   decimal.Decimal `mapstructure:"AMT" default:"50"`
BoolPtr  *bool           `mapstructure:"FLAG" default:"true"`
```

For non-primitive types (decimal, custom), the default string is stored as-is and decoded via `TextUnmarshallerHookFunc` or `StringToCustomTypeHookFunc` at unmarshal time.

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Field in wrong nesting level | Env var has unexpected prefix, value always empty | Move field to correct struct level or flatten |
| Using `string` for numeric config | No type safety, caller must parse | Use `decimal.Decimal`, `int`, `float64` with default |
| No `default` tag | Zero value when env missing (0 for numbers, "" for strings) | Add `default:"X"` matching the source of truth |
| Testing with struct literal instead of env | Tests pass but deployed env var name wrong | Test via `t.Setenv("EXACT_ENV_NAME", ...)` + `Parse()` |

## Verification Checklist

Before finishing any config change:

1. Trace the mapstructure tag path from root → field, join with `_`, uppercase. Does it match the real env var name?
2. Is `default` tag present and matching the canonical source?
3. Is the Go type correct (`decimal.Decimal` not `string` for amounts)?
4. Does at least one test use `t.Setenv("EXACT_DEPLOYED_ENV_NAME", ...)` + `loader.Parse()`?
