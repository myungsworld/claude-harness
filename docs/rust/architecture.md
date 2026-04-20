---
type: reference
topic: rust-architecture
updated: 2026-04-20
tags: [rust, architecture, template-source]
source: null
---

# Rust — Architecture Patterns

Current Rust architecture guidance the harness considers when updating
[templates/rust/](../../templates/rust/). Placeholder scaffold — fill
during the next `/harness/evolve` cycle that emphasizes Rust.

## Scope

- Edition posture (2021 vs. 2024) and what the template assumes
- Workspace vs. single-crate layouts
- Async runtime choice (`tokio` default; when `async-std` / `smol` instead)
- Error model (`thiserror`, `anyhow`, domain error enums)
- Testing (unit tests in-module, integration in `tests/`, `insta` snapshots,
  `proptest`, `loom` for concurrency)
- Lint/format (`clippy` + `cargo fmt`; which lints beyond default)
- Build ergonomics (`cargo-nextest`, `cargo-deny`, `cargo-vet`)

## Harness adoption state

Currently templated in [templates/rust/lefthook.yml](../../templates/rust/lefthook.yml):

- pre-commit: `gitleaks` + `cargo fmt --check`
- pre-push: `cargo clippy -- -D warnings` + `cargo test`

Any shift in the canonical test runner or clippy level → template-update finding.

## Open questions

- (to be filled by the first Rust-focused evolve cycle)
