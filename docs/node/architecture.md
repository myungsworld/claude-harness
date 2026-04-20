---
type: reference
topic: node-architecture
updated: 2026-04-20
tags: [node, typescript, architecture, template-source]
source: null
---

# Node / TypeScript — Architecture Patterns

Current Node / TypeScript architecture guidance the harness considers when
updating [templates/node/](../../templates/node/). Placeholder scaffold — fill
during the next `/harness/evolve` cycle that emphasizes Node.

## Scope

- Runtime landscape (Node LTS, Bun, Deno — which does the harness template for?)
- Module system (ESM vs. CommonJS), `tsconfig.json` modern defaults
- Framework choices (Next.js App Router, Remix, Hono, Fastify, …) and their
  testing expectations
- Package manager posture (`npm`, `pnpm`, `bun`)
- Test runners (Jest, Vitest, `node:test`)
- Lint/format (ESLint flat config, Biome)

## Harness adoption state

Currently templated in [templates/node/lefthook.yml](../../templates/node/lefthook.yml):

- pre-commit: `gitleaks`
- pre-push: `eslint --max-warnings 0 .` + `jest --findRelatedTests` on changed files

Test runner is assumed to be Jest; ESLint is assumed to be configured. Any
shift here (e.g. moving default to Vitest) would be a **template-update**
finding.

## Open questions

- (to be filled by the first Node-focused evolve cycle)
