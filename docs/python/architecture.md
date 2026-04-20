---
type: reference
topic: python-architecture
updated: 2026-04-20
tags: [python, architecture, template-source]
source: null
---

# Python — Architecture Patterns

Current Python architecture guidance the harness considers when updating
[templates/python/](../../templates/python/). Placeholder scaffold — fill
during the next `/harness/evolve` cycle that emphasizes Python.

## Scope

- Version landscape (Python 3.12 / 3.13 feature use; what template assumes)
- Project layout (`src/` vs. flat, `pyproject.toml`, `uv` vs. `poetry` vs. `pip`)
- Type checking (`mypy`, `pyright`, gradual typing posture)
- Testing (`pytest` conventions, fixtures, `hypothesis`, async test patterns)
- Lint/format (`ruff` as unified tool, `black` posture)
- Packaging / distribution (wheels, entry points)
- Async / concurrency defaults

## Harness adoption state

Currently templated in [templates/python/lefthook.yml](../../templates/python/lefthook.yml):

- pre-commit: `gitleaks`
- pre-push: `ruff` + `mypy` + `pytest` (selective)

`ruff` is the assumed linter/formatter; `mypy` is the assumed type checker.
Shift to `pyright` or changes to Python version floor → template-update finding.

## Open questions

- (to be filled by the first Python-focused evolve cycle)
