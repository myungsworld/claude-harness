---
type: reference
topic: go-architecture
updated: 2026-04-20
tags: [go, architecture, template-source]
source: null
---

# Go — Architecture Patterns

Current Go architecture guidance the harness considers when updating
[templates/go/](../../templates/go/). This file is a placeholder scaffold —
fill it during the next `/harness/evolve` cycle that emphasizes Go.

## Scope

What this file should cover, in evolve cycles that include Go:

- Module layout conventions (monorepo vs. polyrepo, `cmd/`, `internal/`, `pkg/`)
- Context propagation and error-handling patterns
- Testing idioms (table-driven, subtests, `t.Cleanup`, `testify` vs. stdlib)
- Dependency direction / Clean Architecture interpretations for Go
- Observability (structured logging, OpenTelemetry)
- Build / tooling (golangci-lint config, govulncheck, workspaces)
- Notable recent language/stdlib changes that affect templates

## Harness adoption state

Currently templated in [templates/go/AGENTS.md.tmpl](../../templates/go/AGENTS.md.tmpl):

- Error handling: always check returned error, no `_`
- Context as first parameter
- Table-driven tests
- `gofmt` + `golangci-lint run ./...`

Anything recorded here that matures into a concrete recommendation becomes a
**template-update** finding in a future cycle.

## Open questions

- (to be filled by the first Go-focused evolve cycle)
