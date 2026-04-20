---
type: reference
topic: flutter-architecture
updated: 2026-04-20
tags: [flutter, dart, architecture, template-source]
source: null
---

# Flutter — Architecture Patterns

Current Flutter architecture guidance the harness considers when updating
[templates/flutter/](../../templates/flutter/). Placeholder scaffold — fill
during the next `/harness/evolve` cycle that emphasizes Flutter.

## Scope

- State management (Riverpod / Bloc / Provider / signals) — what the template assumes
- Project layout (feature-based vs. layer-based)
- Dart version / null-safety posture
- Testing pyramid (unit / widget / integration / golden tests)
- Lint (`flutter_lints`, `very_good_analysis`, custom rules)
- Platform-specific concerns (plugin federation, platform channels)
- Build / CI (build flavors, Fastlane, Codemagic)

## Harness adoption state

Currently templated in [templates/flutter/lefthook.yml](../../templates/flutter/lefthook.yml):

- pre-commit: `gitleaks` + `dart format --set-exit-if-changed .`
- pre-push: `flutter analyze` + `flutter test` (selective)

Any canonical shift in lint pack or test framework → template-update finding.

## Open questions

- (to be filled by the first Flutter-focused evolve cycle)
